module DTT.Data.InputForm exposing (InputForm, codec)

import Codec exposing (Codec)


type alias InputForm =
    { page : String
    , action : String
    , id : Maybe String
    , content : Maybe String    
    , content2 : Maybe String
    , amount : Maybe Int
    }


codec : Codec InputForm
codec =
    Codec.object InputForm
        |> Codec.field "page"
            .page
            (Codec.string |> Codec.map String.toLower String.toLower)
        |> Codec.field "action"
            .action
            (Codec.string |> Codec.map String.toLower String.toLower)
        |> Codec.optionalField "id" .id Codec.string
        |> Codec.optionalField "content" .content Codec.string
        |> Codec.optionalField "content2" .content2 Codec.string
        |> Codec.optionalField "amount" .amount Codec.int
        |> Codec.buildObject
