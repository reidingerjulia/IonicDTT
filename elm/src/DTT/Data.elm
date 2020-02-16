module DTT.Data exposing (jsonPosix,codecPosix,url)

import Time exposing (Posix)
import Codec exposing (Codec)
import Jsonstore exposing (Json)

url : String
url =
    "https://www.jsonstore.io/ef32899156a024d90ab93b0bd506a4930cbcd4754609d6fd9c9f35a9fc4a04b3"

jsonPosix : Json Posix
jsonPosix =
    Jsonstore.int
        |> Jsonstore.map Time.millisToPosix Time.posixToMillis

codecPosix : Codec Posix
codecPosix =
    Codec.int
        |> Codec.map Time.millisToPosix Time.posixToMillis