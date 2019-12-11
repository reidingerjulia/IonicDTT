module DTT.Page.Todo exposing (Error(..), deleteEntry, getList, insertEntry, updateEntry)

import DTT.Data.Config exposing (Config)
import DTT.Data.Id as Id exposing (Id)
import DTT.Data.TodoEntry as TodoEntry exposing (TodoEntry)
import Http
import Random exposing (Generator)
import Task


type Error
    = HttpError Http.Error
    | NoPermission


insertEntry : Config -> (Result Error (List TodoEntry) -> msg) -> String -> Generator (Cmd msg)
insertEntry config msg message =
    Id.generate
        |> Random.map
            (\id ->
                { id = id
                , user = config.user
                , message = message
                , lastUpdated = config.currentTime
                }
                    |> TodoEntry.insertResponse
                    |> Task.andThen (\() -> TodoEntry.getListResponse)
                    |> Task.mapError HttpError
                    |> Task.attempt msg
            )


deleteEntry : Config -> (Result Error (List TodoEntry) -> msg) -> Id -> Cmd msg
deleteEntry config msg id =
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
        |> Task.attempt msg


updateEntry :
    Config
    -> (Result Error (List TodoEntry) -> msg)
    -> { id : Id, message : String }
    -> Cmd msg
updateEntry config msg { id, message } =
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
        |> Task.attempt msg


getList : (Result Error (List TodoEntry) -> msg) -> Cmd msg
getList msg =
    TodoEntry.getListResponse
        |> Task.mapError HttpError
        |> Task.attempt msg
