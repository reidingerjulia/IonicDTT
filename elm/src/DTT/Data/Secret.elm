module DTT.Data.Secret exposing (Secret, codec, deleteResponse, getListResponse, getResponse, insertResponse, json, updateMatchResponse)

import Codec exposing (Codec)
import DTT.Data as Data
import DTT.String as String
import Dict
import Http
import Jsonstore exposing (Json)
import Task exposing (Task)
import Time exposing (Posix)


type alias Secret =
    { hash : String
    , user : String
    , match : Bool
    }


json : Json Secret
json =
    Jsonstore.object Secret
        |> Jsonstore.with "hash" Jsonstore.string .hash
        |> Jsonstore.with "user" Jsonstore.string .user
        |> Jsonstore.with "match" Jsonstore.bool .match
        |> Jsonstore.toJson


codec : Codec Secret
codec =
    Codec.object Secret
        |> Codec.field "hash" .hash Codec.string
        |> Codec.field "user" .user Codec.string
        |> Codec.field "match" .match Codec.bool
        |> Codec.buildObject


insertResponse : Secret -> Task Http.Error ()
insertResponse entry =
    entry
        |> Jsonstore.encode json
        |> Jsonstore.insert (Data.url ++ String.secrets ++ "/" ++ entry.hash)


getResponse : String -> Task Http.Error (Maybe Secret)
getResponse hash =
    json
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.secrets ++ "/" ++ hash)


getListResponse : Task Http.Error (List Secret)
getListResponse =
    json
        |> Jsonstore.dict
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.secrets)
        |> Task.map (Maybe.map Dict.values >> Maybe.withDefault [])


updateMatchResponse : String -> Bool -> Task Http.Error ()
updateMatchResponse hash b =
    Jsonstore.update
        (Data.url ++ String.secrets ++ "/" ++ hash ++ String.match)
        Jsonstore.bool
        (always <| b)


deleteResponse : String -> Task Http.Error ()
deleteResponse hash =
    Jsonstore.delete (Data.url ++ String.secrets ++ "/" ++ hash)
