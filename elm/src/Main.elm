port module Main exposing (main)

import Codec exposing (Codec)
import DTT.Data as Data
import DTT.Data.Config exposing (Config)
import DTT.Data.Error as Error exposing (Error(..))
import DTT.Data.InputForm as InputForm exposing (InputForm)
import DTT.Data.OutputForm as OutputForm exposing (OutputForm)
import DTT.Data.Secret as Secret exposing (Secret)
import DTT.Data.TodoEntry as TodoEntry exposing (TodoEntry)
import DTT.Page.Secrets as Secrets
import DTT.Page.Todo as Todo
import Http
import Json.Decode as D
import Json.Encode as E
import Jsonstore
import Random
import Result exposing (Result)
import Task
import Time exposing (Posix)


port toElm : (E.Value -> msg) -> Sub msg


type Input
    = InputTodoEntry { message : String }
    | SyncTodoEntry
    | DeleteTodoEntry { id : String }
    | UpdateTodoEntry
        { id : String
        , message : String
        }
    | InsertSecret { secret : String }
    | DeleteSecret { secret : String }
    | SyncSecret
    | ForceReset


handleInput : E.Value -> Msg
handleInput =
    Codec.decodeValue InputForm.codec
        >> Result.mapError
            (D.errorToString >> ParsingError)
        >> Result.andThen
            (\({ page, action, id, content } as form) ->
                case page of
                    "admin" ->
                        case ( action, id, content ) of
                            ( "reset", Nothing, Nothing ) ->
                                Ok <| ForceReset

                            _ ->
                                Err <| WrongInputFormat <| form

                    "todo" ->
                        case ( action, id, content ) of
                            ( "insert", Nothing, Just message ) ->
                                Ok <| InputTodoEntry <| { message = message }

                            ( "delete", Just i, Nothing ) ->
                                Ok <| DeleteTodoEntry <| { id = i }

                            ( "update", Just i, Just message ) ->
                                Ok <|
                                    UpdateTodoEntry <|
                                        { id = i
                                        , message = message
                                        }

                            ( "sync", Nothing, Nothing ) ->
                                Ok <| SyncTodoEntry

                            _ ->
                                Err <| WrongInputFormat <| form

                    "secrets" ->
                        case ( action, id, content ) of
                            ( "insert", Nothing, Just secret ) ->
                                Ok <| InsertSecret <| { secret = secret }

                            ( "delete", Nothing, Just secret ) ->
                                Ok <| DeleteSecret <| { secret = secret }

                            ( "sync", Nothing, Nothing ) ->
                                Ok <| SyncSecret

                            _ ->
                                Err <| WrongInputFormat <| form

                    _ ->
                        Err <| WrongInputFormat <| form
            )
        >> GotInput


port fromElm : E.Value -> Cmd msg


type Output
    = ErrorOccurred Error
    | GotTodoList (List TodoEntry)
    | GotSecretList (List Secret)


handleOutput : Output -> E.Value
handleOutput output =
    Codec.encodeToValue OutputForm.codec <|
        case output of
            ErrorOccurred error ->
                error
                    |> Error.toJsError
                    |> OutputForm.error

            GotTodoList list ->
                OutputForm.todo list

            GotSecretList list ->
                OutputForm.secrets list


type alias Flag =
    { user : String
    , currentTime : Int
    , initialSeed : Float
    }


type alias Model =
    Config


type Msg
    = GotTime Posix
    | GotTodoResponse (Result Todo.Error (List TodoEntry))
    | GotSecretResponse (Result Secrets.Error (List Secret))
    | GotInput (Result Error Input)


init : Flag -> ( Model, Cmd Msg )
init { user, currentTime, initialSeed } =
    ( { user = user |> String.toLower
      , currentTime = currentTime |> Time.millisToPosix
      , seed = Random.initialSeed (Random.minInt + round (initialSeed * toFloat (Random.maxInt * 2)))
      }
    , Todo.getList |> Task.attempt GotTodoResponse
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime posix ->
            ( { model | currentTime = posix }
            , Cmd.batch
                [ Todo.getList |> Task.attempt GotTodoResponse
                , Secrets.getList model |> Task.attempt GotSecretResponse
                ]
            )

        GotTodoResponse result ->
            case result of
                Ok list ->
                    ( model
                    , list
                        |> OutputForm.todo
                        |> Codec.encodeToValue OutputForm.codec
                        |> fromElm
                    )

                Err err ->
                    ( model
                    , (case err of
                        Todo.HttpError e ->
                            HttpError e

                        Todo.NoPermission ->
                            NoPermission
                      )
                        |> Error.toJsError
                        |> OutputForm.error
                        |> Codec.encodeToValue OutputForm.codec
                        |> fromElm
                    )

        GotSecretResponse result ->
            case result of
                Ok list ->
                    ( model
                    , list
                        |> OutputForm.secrets
                        |> Codec.encodeToValue OutputForm.codec
                        |> fromElm
                    )

                Err err ->
                    ( model
                    , (case err of
                        Secrets.HttpError e ->
                            HttpError e

                        Secrets.IsMatched ->
                            IsMatched
                      )
                        |> Error.toJsError
                        |> OutputForm.error
                        |> Codec.encodeToValue OutputForm.codec
                        |> fromElm
                    )

        GotInput result ->
            case result of
                Ok input ->
                    case input of
                        InputTodoEntry { message } ->
                            let
                                ( cmd, seed ) =
                                    model.seed
                                        |> Random.step
                                            (message
                                                |> Todo.insertEntry model
                                            )
                            in
                            ( { model | seed = seed }
                            , cmd
                                |> Task.attempt GotTodoResponse
                            )

                        SyncTodoEntry ->
                            ( model
                            , Todo.getList
                                |> Task.attempt GotTodoResponse
                            )

                        DeleteTodoEntry { id } ->
                            ( model
                            , Todo.deleteEntry model id
                                |> Task.attempt GotTodoResponse
                            )

                        UpdateTodoEntry arguments ->
                            ( model
                            , Todo.updateEntry model arguments
                                |> Task.attempt GotTodoResponse
                            )

                        InsertSecret { secret } ->
                            ( model
                            , secret
                                |> Secrets.insert model
                                |> Task.attempt GotSecretResponse
                            )

                        DeleteSecret { secret } ->
                            ( model
                            , secret
                                |> Secrets.delete model
                                |> Task.attempt GotSecretResponse
                            )

                        SyncSecret ->
                            ( model
                            , Secrets.getList model
                                |> Task.attempt GotSecretResponse
                            )

                        ForceReset ->
                            ( model
                            , Jsonstore.delete Data.url
                                |> Task.mapError Todo.HttpError
                                |> Task.andThen
                                    (\() -> Todo.getList)
                                |> Task.attempt GotTodoResponse
                            )

                Err err ->
                    ( model
                    , err
                        |> Error.toJsError
                        |> OutputForm.error
                        |> Codec.encodeToValue OutputForm.codec
                        |> fromElm
                    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ toElm handleInput
        ]


main : Program Flag Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
