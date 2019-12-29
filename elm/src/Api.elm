module Api exposing (Flag, Model, Msg(..), handleInput, init, subscriptions, update)

import Codec
import DTT.Data as Data
import DTT.Data.Config exposing (Config)
import DTT.Data.Error as Error exposing (Error(..))
import DTT.Data.InputForm as InputForm
import DTT.Data.OutputForm as OutputForm
import DTT.Data.Secret exposing (Secret)
import DTT.Data.TodoEntry exposing (TodoEntry)
import DTT.Page.Secrets as Secrets
import DTT.Page.Todo as Todo
import Json.Decode as D
import Json.Encode as E
import Jsonstore
import Random
import Result exposing (Result)
import Task
import Time exposing (Posix)


type Input
    = InputTodoEntry String
    | SyncTodoEntry
    | DeleteTodoEntry String
    | UpdateTodoEntry
        { id : String
        , message : String
        }
    | InsertSecret String
    | DeleteSecret String
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
                                Ok <| InputTodoEntry <| message

                            ( "delete", Just i, Nothing ) ->
                                Ok <| DeleteTodoEntry <| i

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
                                Ok <| InsertSecret <| secret

                            ( "delete", Nothing, Just secret ) ->
                                Ok <| DeleteSecret <| secret

                            ( "sync", Nothing, Nothing ) ->
                                Ok <| SyncSecret

                            _ ->
                                Err <| WrongInputFormat <| form

                    _ ->
                        Err <| WrongInputFormat <| form
            )
        >> GotInput


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
    , Cmd.none
    )


update : (E.Value -> Cmd msg) -> (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update fromElm wrapper msg model =
    case msg of
        GotTime posix ->
            ( { model | currentTime = posix }
            , Cmd.none
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
                        InputTodoEntry message ->
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
                                |> Cmd.map wrapper
                            )

                        SyncTodoEntry ->
                            ( model
                            , Todo.getList
                                |> Task.attempt GotTodoResponse
                                |> Cmd.map wrapper
                            )

                        DeleteTodoEntry id ->
                            ( model
                            , Todo.deleteEntry model id
                                |> Task.attempt GotTodoResponse
                                |> Cmd.map wrapper
                            )

                        UpdateTodoEntry arguments ->
                            ( model
                            , Todo.updateEntry model arguments
                                |> Task.attempt GotTodoResponse
                                |> Cmd.map wrapper
                            )

                        InsertSecret secret ->
                            ( model
                            , secret
                                |> Secrets.insert model
                                |> Task.attempt GotSecretResponse
                                |> Cmd.map wrapper
                            )

                        DeleteSecret secret ->
                            ( model
                            , secret
                                |> Secrets.delete model
                                |> Task.attempt GotSecretResponse
                                |> Cmd.map wrapper
                            )

                        SyncSecret ->
                            ( model
                            , Secrets.getList model
                                |> Task.attempt GotSecretResponse
                                |> Cmd.map wrapper
                            )

                        ForceReset ->
                            ( model
                            , Jsonstore.delete Data.url
                                |> Task.mapError Todo.HttpError
                                |> Task.andThen
                                    (\() -> Todo.getList)
                                |> Task.attempt GotTodoResponse
                                |> Cmd.map wrapper
                            )

                Err err ->
                    ( model
                    , err
                        |> Error.toJsError
                        |> OutputForm.error
                        |> Codec.encodeToValue OutputForm.codec
                        |> fromElm
                    )


subscriptions : ((E.Value -> Msg) -> Sub Msg) -> Sub Msg
subscriptions toElm =
    Sub.batch
        [ Time.every 10000 GotTime
        , toElm handleInput
        ]
