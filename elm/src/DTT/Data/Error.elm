module DTT.Data.Error exposing (Error(..), ErrorJson, codec, toJsError)

import Codec exposing (Codec)
import DTT.Data.InputForm as InputForm exposing (InputForm)
import Http


type alias ErrorJson =
    { errorType : String
    , content : String
    }


type Error
    = HttpError Http.Error
    | WrongInputFormat InputForm
    | ParsingError String
    | IsMatched
    | NoPermission


toJsError : Error -> ErrorJson
toJsError err =
    case err of
        HttpError (Http.BadUrl string) ->
            { errorType = "bad-url"
            , content = string
            }

        HttpError Http.Timeout ->
            { errorType = "timeout"
            , content = ""
            }

        HttpError Http.NetworkError ->
            { errorType = "network-error"
            , content = ""
            }

        HttpError (Http.BadStatus int) ->
            { errorType = "bad-status"
            , content = String.fromInt int
            }

        HttpError (Http.BadBody string) ->
            { errorType = "bad-body"
            , content = string
            }

        WrongInputFormat inputForm ->
            { errorType = "wrong-input-format"
            , content =
                inputForm
                    |> Codec.encodeToString 2 InputForm.codec
            }

        ParsingError string ->
            { errorType = "parsingError"
            , content = string
            }

        IsMatched ->
            { errorType = "is-matched"
            , content = ""
            }

        NoPermission ->
            { errorType = "no-permission"
            , content = ""
            }


codec : Codec ErrorJson
codec =
    Codec.object ErrorJson
        |> Codec.field "errorType" .errorType (Codec.string |> Codec.map String.toLower String.toLower)
        |> Codec.field "content" .content Codec.string
        |> Codec.buildObject
