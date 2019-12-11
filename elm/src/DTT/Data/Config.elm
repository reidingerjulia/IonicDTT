module DTT.Data.Config exposing (Config)

import Random exposing (Seed)
import Time exposing (Posix)


type alias Config =
    { user : String
    , currentTime : Posix
    , seed : Seed
    }
