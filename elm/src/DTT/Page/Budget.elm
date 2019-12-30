module DTT.Page.Budget exposing (Error(..), delete, get, insert, update)

import DTT.Data.Budget as Budget exposing (Budget, Spending)
import DTT.Data.Config exposing (Config)
import DTT.Data.Id as Id exposing (Id)
import Http
import Random exposing (Generator)
import Task exposing (Task)


type Error
    = HttpError Http.Error
    | NoPermission


get : Config -> Task Error Budget
get config =
    Budget.getBudgetResponse config.user
        |> Task.mapError HttpError


insert : Config -> { cent : Int, reference : String } -> Generator (Task Error Budget)
insert config { cent, reference } =
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
                    |> Task.andThen (\() -> Budget.getBudgetResponse config.user)
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
        |> Task.andThen (\() -> Budget.getBudgetResponse config.user |> Task.mapError HttpError)


update : Config -> { id : Id, cent : Int, reference : String } -> Task Error Budget
update config { id, cent, reference } =
    Budget.getResponse id
        |> Task.mapError HttpError
        |> Task.andThen
            (\maybeSpending ->
                case maybeSpending of
                    Just ({ user } as entry) ->
                        if user == config.user then
                            { entry
                                | cent = cent
                                , reference = reference
                                , lastUpdated = config.currentTime
                            }
                                |> Budget.insertResponse
                                |> Task.mapError HttpError

                        else
                            Task.fail NoPermission

                    Nothing ->
                        Task.succeed ()
            )
        |> Task.andThen (\() -> Budget.getBudgetResponse config.user |> Task.mapError HttpError)
