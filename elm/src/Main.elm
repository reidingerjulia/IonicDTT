port module DTT exposing (main)

import Codec exposing (Codec)
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


handleInput : E.Value -> Msg
handleInput =
    Codec.decodeValue InputForm.codec
        >> Result.mapError
            (D.errorToString >> ParsingError)
        >> Result.andThen
            (\({ page, action, id, content } as form) ->
                case page of
                    "todo" ->
                        case ( action, id, content ) of
                            ( "input", Nothing, Just message ) ->
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
                            ( "input", Nothing, Just secret ) ->
                                Ok <| InsertSecret <| { secret = secret }

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
    ( { user = user
      , currentTime = currentTime |> Time.millisToPosix
      , seed = Random.initialSeed (Random.minInt + round (initialSeed * toFloat (Random.maxInt * 2)))
      }
    , Todo.getList GotTodoResponse
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime posix ->
            ( { model | currentTime = posix }
            , Cmd.batch
                [ Todo.getList GotTodoResponse
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
                                                |> Todo.insertEntry model GotTodoResponse
                                            )
                            in
                            ( { model | seed = seed }
                            , cmd
                            )

                        SyncTodoEntry ->
                            ( model
                            , Todo.getList GotTodoResponse
                            )

                        DeleteTodoEntry { id } ->
                            ( model
                            , Todo.deleteEntry model GotTodoResponse id
                            )

                        UpdateTodoEntry arguments ->
                            ( model
                            , Todo.updateEntry model GotTodoResponse arguments
                            )

                        InsertSecret { secret } ->
                            ( model
                            , secret
                                |> Secrets.insert model
                                |> Task.attempt GotSecretResponse
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
