module DTT.Page.Secrets exposing (Error(..), delete, getList, insert)

import DTT.Data.Config exposing (Config)
import DTT.Data.Secret as Secret exposing (Secret)
import Http
import Sha256
import Task exposing (Task)


type Error
    = HttpError Http.Error
    | IsMatched


insert : Config -> String -> Task Error (List Secret)
insert config raw =
    raw
    String.toLower >>
        |> Sha256.sha224
        |> (\hash ->
                Secret.getResponse hash
                    |> Task.andThen
                        (\maybeEntry ->
                            case maybeEntry of
                                Just { user } ->
                                    if user == config.user then
                                        Task.succeed ()

                                    else
                                        Secret.updateMatchResponse hash raw

                                Nothing ->
                                    { user = config.user
                                    , hash = hash
                                    , match = False
                                    }
                                        |> Secret.insertResponse
                        )
           )
        |> Task.mapError HttpError
        |> Task.andThen (\() -> getList config)


delete : Config -> String -> Task Error (List Secret)
delete config =
    String.toLower >>
    Sha256.sha224
        >> (\hash ->
    Secret.getResponse hash
        |> Task.mapError HttpError
        |> Task.andThen
            (\maybeEntry ->
                case maybeEntry of
                    Just { user, match } ->
                        if user == config.user then
                            if match then
                                Task.fail IsMatched

                            else
                                Secret.deleteResponse hash
                                    |> Task.mapError HttpError

                        else
                            Secret.updateMatchResponse hash False
                                |> Task.mapError HttpError

                    Nothing ->
                        Task.succeed ()
            )
        |> Task.andThen
            (\() -> getList config))


getList : Config -> Task Error (List Secret)
getList config =
    Secret.getListResponse
        |> Task.map
            (List.filter
                (\{ user, match } ->
                    (user == config.user)
                        || match
                )
            )
        |> Task.mapError HttpError
