module DTT.Data.Budget exposing (Budget, Spending, codec,json,getBudgetResponse,getResponse,insertResponse,deleteResponse)

import DTT.Data.Id as Id exposing (Id)
import Time exposing (Posix)
import DTT.Data as Data

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
  |> Jsonstore.with "id" Id.codec .id
  |> Jsonstore.with "user" Codec.string .user
  |> Jsonstore.with "cent" Codec.int .cent
  |> Jsonstore.with "reference" Codec.string .reference
  |> Jsonstore.with "lastUpdated" Data.codecPosix .lastUpdated

codec : Codec Budget
codec =
  Codec.object Budget
  |> Codec.with "totalCent" .totalCent Codec.int
  |> Codec.with "spending" .spending (Codec.list codecSpending)

json : Json Budget
json =
  Jsonstore.object Budget
  |> Jsonstore.with "totalCent" Jsonstore.int .totalCent
  |> Jsonstore.withList "spending" jsonSpending .spending

insertResponse : Spending -> Task Http.Error ()
insertResponse entry =
    entry
        |> Jsonstore.encode json
        |> Jsonstore.insert (Data.url ++ String.budget ++ "/" ++ entry.id)

getResponse : Id -> Task Http.Error (Maybe Spending)
getResponse id =
    json
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.budget ++ "/" ++ id)

getBudgetResponse : Task Http.Error Budget
getBudgetResponse =
    json
        |> Jsonstore.dict
        |> Jsonstore.decode
        |> Jsonstore.get (Data.url ++ String.budget)
        |> Task.map
          (Maybe.map Dict.values
            >> Maybe.withDefault []
            >> (\list ->
              { totalCent = list |> List.foldl (.cent >> (+)) 0
              , spendings = list
              }
              )
          )


deleteResponse : Id -> Task Http.Error ()
deleteResponse id =
    Jsonstore.delete (Data.url ++ String.budget ++ "/" ++ id)