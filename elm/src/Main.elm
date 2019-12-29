port module Main exposing (main)

import Api exposing (Flag, Model, Msg)
import Json.Decode as D
import Json.Encode as E


port toElm : (E.Value -> msg) -> Sub msg


port fromElm : E.Value -> Cmd msg


init : Flag -> ( Model, Cmd Msg )
init =
    Api.init


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Api.update fromElm identity


subscriptions : Model -> Sub Msg
subscriptions _ =
    Api.subscriptions toElm


main : Program Flag Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
