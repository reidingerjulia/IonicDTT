module DTT.Data.Id exposing (Id, codec, generate, json, view)

import Codec exposing (Codec)
import Jsonstore exposing (Json)
import Random exposing (Generator)


type alias Id =
    String


generate : Generator Id
generate =
    Random.int 0 Random.maxInt
        |> Random.map String.fromInt


view : Id -> String
view =
    String.left 4


json : Json Id
json =
    Jsonstore.string


codec : Codec Id
codec =
    Codec.string
