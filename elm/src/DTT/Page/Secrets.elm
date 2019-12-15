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
        |> String.toLower
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
                                        Secret.updateRawResponse
                                            { hash = hash, raw = Just raw }

                                Nothing ->
                                    { user = config.user
                                    , hash = hash
                                    , raw = Nothing
                                    }
                                        |> Secret.insertResponse
                        )
           )
        |> Task.mapError HttpError
        |> Task.andThen (\() -> getList config)


delete : Config -> String -> Task Error (List Secret)
delete config =
    String.toLower
        >> Sha256.sha224
        >> (\hash ->
                Secret.getResponse hash
                    |> Task.mapError HttpError
                    |> Task.andThen
                        (\maybeEntry ->
                            case maybeEntry of
                                Just { user, raw } ->
                                    if raw == Nothing then
                                        if user == config.user then
                                            Secret.deleteResponse hash
                                                |> Task.mapError HttpError

                                        else
                                            Task.succeed ()

                                    else
                                        Task.fail IsMatched

                                Nothing ->
                                    Task.succeed ()
                        )
                    |> Task.andThen
                        (\() -> getList config)
           )


getList : Config -> Task Error (List Secret)
getList config =
    Secret.getListResponse
        |> Task.map
            (List.filter
                (\{ user, raw } ->
                    (user == config.user)
                        || (raw /= Nothing)
                )
            )
        |> Task.mapError HttpError
