port module DTT exposing (main)

import Codec
import DTT.Data.Config exposing (Config)
import DTT.Data.TodoEntry as TodoEntry exposing (TodoEntry)
import DTT.Error as Error
import DTT.Page.Todo as Todo
import Json.Decode as D
import Json.Encode as E
import Random
import Result exposing (Result)
import Time exposing (Posix)


handleParsingError : (v -> Msg) -> Result Codec.Error v -> Msg
handleParsingError fun result =
    case result of
        Ok v ->
            fun v

        Err e ->
            e |> ParsingError


port insertTodoEntry : (E.Value -> msg) -> Sub msg


type alias InsertTodoEntryForm =
    { message : String }


handleInsertTodoEntry : E.Value -> Msg
handleInsertTodoEntry =
    Codec.decodeValue
        (Codec.object InsertTodoEntryForm
            |> Codec.field "message" .message Codec.string
            |> Codec.buildObject
        )
        >> handleParsingError
            (\{ message } ->
                InsertTodoEntry message
            )


port syncTodoEntry : ({} -> msg) -> Sub msg


handleSyncTodoEntry : {} -> Msg
handleSyncTodoEntry {} =
    GetTodoList


port deleteTodoEntry : (E.Value -> msg) -> Sub msg


type alias DeleteTodoEntryForm =
    { id : String }


handleDeleteTodoEntry : E.Value -> Msg
handleDeleteTodoEntry =
    Codec.decodeValue
        (Codec.object DeleteTodoEntryForm
            |> Codec.field "id" .id Codec.string
            |> Codec.buildObject
        )
        >> handleParsingError
            (\{ id } ->
                DeleteTodoEntry id
            )


port updateTodoEntry : (E.Value -> msg) -> Sub msg


type alias UpdateTodoEntryForm =
    { id : String
    , message : String
    }


handleUpdateTodoEntry : E.Value -> Msg
handleUpdateTodoEntry =
    Codec.decodeValue
        (Codec.object UpdateTodoEntryForm
            |> Codec.field "id" .id Codec.string
            |> Codec.field "message" .message Codec.string
            |> Codec.buildObject
        )
        >> handleParsingError UpdateTodoEntry


port errorOccured : String -> Cmd msg


port gotTodoList : E.Value -> Cmd msg


type alias Flag =
    { user : String
    , currentTime : Int
    , initialSeed : Float
    }


type alias Model =
    Config


type Msg
    = GotTime Posix
    | ParsingError D.Error
    | InsertTodoEntry String
    | DeleteTodoEntry String
    | UpdateTodoEntry UpdateTodoEntryForm
    | GetTodoList
    | GotTodoResponse (Result Todo.Error (List TodoEntry))


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
            , Todo.getList GotTodoResponse
            )

        ParsingError error ->
            ( model
            , error |> D.errorToString |> errorOccured
            )

        InsertTodoEntry message ->
            let
                ( cmd, seed ) =
                    model.seed
                        |> Random.step (message |> Todo.insertEntry model GotTodoResponse)
            in
            ( { model | seed = seed }
            , cmd
            )

        DeleteTodoEntry id ->
            ( model
            , Todo.deleteEntry model GotTodoResponse id
            )

        UpdateTodoEntry arguments ->
            ( model
            , Todo.updateEntry model GotTodoResponse arguments
            )

        GetTodoList ->
            ( model
            , Todo.getList GotTodoResponse
            )

        GotTodoResponse result ->
            case result of
                Ok list ->
                    ( model
                    , list
                        |> Codec.encodeToValue (Codec.list TodoEntry.codec)
                        |> gotTodoList
                    )

                Err err ->
                    ( model
                    , (case err of
                        Todo.HttpError e ->
                            e |> Error.toString

                        Todo.NoPermission ->
                            "You tried to do something that you do not have permission for."
                      )
                        |> errorOccured
                    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every 60000 GotTime
        , insertTodoEntry handleInsertTodoEntry
        , syncTodoEntry handleSyncTodoEntry
        , deleteTodoEntry handleDeleteTodoEntry
        , updateTodoEntry handleUpdateTodoEntry
        ]


main : Program Flag Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
