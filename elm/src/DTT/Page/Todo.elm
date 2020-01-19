module DTT.Page.Todo exposing (Error(..),toggle, deleteEntry, getList, insertEntry, updateEntry)

import DTT.Data.Config exposing (Config)
import DTT.Data.Id as Id exposing (Id)
import DTT.Data.TodoEntry as TodoEntry exposing (TodoEntry)
import Http
import Random exposing (Generator)
import Task exposing (Task)


type Error
    = HttpError Http.Error
    | NoPermission


insertEntry : Config -> String -> Generator (Task Error (List TodoEntry))
insertEntry config message =
    Id.generate
        |> Random.map
            (\id ->
                { id = id
                , user = config.user
                , message = message
                , lastUpdated = config.currentTime
                , checked = Just False
                }
                    |> TodoEntry.insertResponse
                    |> Task.andThen (\() -> TodoEntry.getListResponse)
                    |> Task.mapError HttpError
            )


deleteEntry : Config -> Id -> Task Error (List TodoEntry)
deleteEntry config id =
    TodoEntry.getResponse id
        |> Task.mapError HttpError
        |> Task.andThen
            (\maybeEntry ->
                case maybeEntry of
                    Just { user } ->
                        if user == config.user then
                            TodoEntry.deleteResponse id
                                |> Task.mapError HttpError

                        else
                            Task.fail NoPermission

                    Nothing ->
                        Task.succeed ()
            )
        |> Task.andThen (\() -> TodoEntry.getListResponse |> Task.mapError HttpError)

toggle : Config -> Id -> Task Error (List TodoEntry)
toggle config id =
    TodoEntry.toggleResponse id
        |> Task.mapError HttpError
        |> Task.andThen (\() -> TodoEntry.getListResponse |> Task.mapError HttpError)


updateEntry :
    Config
    -> { id : Id, message : String }
    -> Task Error (List TodoEntry)
updateEntry config { id, message } =
    TodoEntry.getResponse id
        |> Task.mapError HttpError
        |> Task.andThen
            (\maybeEntry ->
                case maybeEntry of
                    Just ({ user } as entry) ->
                        if user == config.user then
                            { entry
                                | message = message
                                , lastUpdated = config.currentTime
                            }
                                |> TodoEntry.insertResponse
                                |> Task.mapError HttpError

                        else
                            Task.fail NoPermission

                    Nothing ->
                        Task.succeed ()
            )
        |> Task.andThen (\() -> TodoEntry.getListResponse |> Task.mapError HttpError)


getList : Task Error (List TodoEntry)
getList =
    TodoEntry.getListResponse
        |> Task.mapError HttpError
