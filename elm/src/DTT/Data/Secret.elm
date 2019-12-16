module DTT.Data.Secret exposing (Secret, codec, deleteResponse, getListResponse, getResponse, insertResponse, json, updateRawResponse)

import Codec exposing (Codec)
import DTT.Data as Data
import DTT.String as String
import Dict
import Http
import Jsonstore exposing (Json)
import Task exposing (Task)


type alias Secret =
    { hash : String
    , user : String
    , raw : Maybe String
    }


json : Json Secret
json =
    Jsonstore.object Secret
        |> Jsonstore.with "hash" Jsonstore.string .hash
        |> Jsonstore.with "user" Jsonstore.string .user
        |> Jsonstore.withMaybe "raw" Jsonstore.string .raw
        |> Jsonstore.toJson


codec : Codec Secret
codec =
    Codec.object Secret
        |> Codec.field "hash" .hash Codec.string
        |> Codec.field "user" .user Codec.string
        |> Codec.field "raw" .raw (Codec.maybe Codec.string)
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


updateRawResponse : { hash : String, raw : Maybe String } -> Task Http.Error ()
updateRawResponse { hash, raw } =
    case raw of
        Just r ->
            r
                |> Jsonstore.encode Jsonstore.string
                |> Jsonstore.insert
                    (Data.url ++ String.secrets ++ "/" ++ hash ++ String.raw)

        Nothing ->
            Jsonstore.delete (Data.url ++ String.secrets ++ "/" ++ hash ++ String.raw)


deleteResponse : String -> Task Http.Error ()
deleteResponse hash =
    Jsonstore.delete (Data.url ++ String.secrets ++ "/" ++ hash)
