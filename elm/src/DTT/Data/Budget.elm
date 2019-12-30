module DTT.Data.Budget exposing (Budget, Spending, codec, deleteResponse, getBudgetResponse, getResponse, insertResponse, json)

import Codec exposing (Codec)
import DTT.Data as Data
import DTT.Data.Id as Id exposing (Id)
import DTT.String as String
import Dict exposing (Dict)
import Http
import Jsonstore exposing (Json)
import Task exposing (Task)
import Time exposing (Posix)


type alias Budget =
    { totalCent : Int
    , spendings : List Spending
    }


type alias Spending =
    { id : Id
    , user : String
    , cent : Int
    , reference : String
    , lastUpdated : Posix
    }


codecSpending : Codec Spending
codecSpending =
    Codec.object Spending
        |> Codec.field "id" .id Id.codec
        |> Codec.field "user" .user Codec.string
        |> Codec.field "cent" .cent Codec.int
        |> Codec.field "reference" .reference Codec.string
        |> Codec.field "lastUpdated" .lastUpdated Data.codecPosix
        |> Codec.buildObject


jsonSpending : Json Spending
jsonSpending =
    Jsonstore.object Spending
        |> Jsonstore.with "id" Id.json .id
        |> Jsonstore.with "user" Jsonstore.string .user
        |> Jsonstore.with "cent" Jsonstore.int .cent
        |> Jsonstore.with "reference" Jsonstore.string .reference
        |> Jsonstore.with "lastUpdated" Data.jsonPosix .lastUpdated
        |> Jsonstore.toJson


codec : Codec Budget
codec =
    Codec.object Budget
        |> Codec.field "totalCent" .totalCent Codec.int
        |> Codec.field "spendings" .spendings (Codec.list codecSpending)
        |> Codec.buildObject


json : Json Budget
json =
    Jsonstore.object Budget
        |> Jsonstore.with "totalCent" Jsonstore.int .totalCent
        |> Jsonstore.withList "spendings" jsonSpending .spendings
        |> Jsonstore.toJson


insertResponse : Spending -> Task Http.Error ()
insertResponse entry =
    entry
        |> Jsonstore.encode jsonSpending
        |> Jsonstore.insert (Data.url ++ String.budget ++ "/" ++ entry.id)


getResponse : Id -> Task Http.Error (Maybe Spending)
getResponse id =
    jsonSpending
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.budget ++ "/" ++ id)


getBudgetResponse : String -> Task Http.Error Budget
getBudgetResponse configUser =
    jsonSpending
        |> Jsonstore.dict
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.budget)
        |> Task.map
            (Maybe.map Dict.values
                >> Maybe.withDefault []
                >> (\list ->
                        { totalCent =
                            list
                                |> List.foldl
                                    (\{ cent, user } ->
                                        (if user == configUser then
                                            cent

                                         else
                                            -cent
                                        )
                                            |> (+)
                                    )
                                    0
                        , spendings = list
                        }
                   )
            )


deleteResponse : Id -> Task Http.Error ()
deleteResponse id =
    Jsonstore.delete (Data.url ++ String.budget ++ "/" ++ id)
