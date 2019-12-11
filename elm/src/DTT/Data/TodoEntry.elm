module DTT.Data.TodoEntry exposing (TodoEntry, codec, deleteResponse, getListResponse, getResponse, insertResponse, json)

import Codec exposing (Codec)
import DTT.Data as Data
import DTT.Data.Id as Id exposing (Id)
import DTT.String as String
import Dict
import Http
import Jsonstore exposing (Json)
import Task exposing (Task)
import Time exposing (Posix)


type alias TodoEntry =
    { id : Id
    , user : String
    , message : String
    , lastUpdated : Posix
    }


jsonPosix : Json Posix
jsonPosix =
    Jsonstore.int
        |> Jsonstore.map Time.millisToPosix Time.posixToMillis


json : Json TodoEntry
json =
    Jsonstore.object TodoEntry
        |> Jsonstore.with "id" Id.json .id
        |> Jsonstore.with "user" Jsonstore.string .user
        |> Jsonstore.with "message" Jsonstore.string .message
        |> Jsonstore.with "lastUpdated" jsonPosix .lastUpdated
        |> Jsonstore.toJson


codecPosix : Codec Posix
codecPosix =
    Codec.int
        |> Codec.map Time.millisToPosix Time.posixToMillis


codec : Codec TodoEntry
codec =
    Codec.object TodoEntry
        |> Codec.field "id" .id Id.codec
        |> Codec.field "user" .user Codec.string
        |> Codec.field "message" .message Codec.string
        |> Codec.field "lastUpdated" .lastUpdated codecPosix
        |> Codec.buildObject


insertResponse : TodoEntry -> Task Http.Error ()
insertResponse entry =
    entry
        |> Jsonstore.encode json
        |> Jsonstore.insert (Data.url ++ String.todo ++ "/" ++ entry.id)


getResponse : Id -> Task Http.Error (Maybe TodoEntry)
getResponse id =
    json
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.todo ++ "/" ++ id)


getListResponse : Task Http.Error (List TodoEntry)
getListResponse =
    json
        |> Jsonstore.dict
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.todo)
        |> Task.map (Maybe.map Dict.values >> Maybe.withDefault [])


deleteResponse : Id -> Task Http.Error ()
deleteResponse id =
    Jsonstore.delete (Data.url ++ String.todo ++ "/" ++ id)
