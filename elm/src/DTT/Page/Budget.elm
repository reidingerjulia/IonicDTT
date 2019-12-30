module DTT.Page.Budget exposing (Error(..), delete, getList, insert, update)

import DTT.Data.Config exposing (Config)
import DTT.Data.Budget exposing (Budget,Spending)
import Random exposing (Generator)

type Error
    = HttpError Http.Error
    | NoPermission

get : Config -> Task Error Budget
get config =
    Budget.getBudgetResponse
        |> Task.mapError HttpError

insert : Config -> {cent:Int,reference:String} -> Generator (Task Error Budget)
insert config {cent,reference}=
  Id.generate
        |> Random.map
            (\id ->
                { id = id
                , user = config.user
                , cent = cent
                , reference = reference
                , lastUpdated = config.currentTime
                }
                    |> Budget.insertResponse
                    |> Task.andThen (\() -> Budget.getBudgetResponse)
                    |> Task.mapError HttpError
            )

delete : Config -> Id -> Task Error Budget
delete config id =
    Budget.getResponse id
        |> Task.mapError HttpError
        |> Task.andThen
            (\maybeEntry ->
                case maybeEntry of
                    Just { user } ->
                        if user == config.user then
                            Budget.deleteResponse id
                                |> Task.mapError HttpError

                        else
                            Task.fail NoPermission

                    Nothing ->
                        Task.succeed ()
            )
        |> Task.andThen (\() -> Budget.getBudgetResponse |> Task.mapError HttpError)