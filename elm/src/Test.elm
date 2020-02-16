module Test exposing (main)

import Api exposing (Flag, init, subscriptions, update)
import Browser
import Codec
import DTT.Data.Budget exposing (Budget)
import DTT.Data.Error exposing (ErrorJson)
import DTT.Data.InputForm as InputForm
import DTT.Data.OutputForm as OutputForm exposing (OutputForm)
import DTT.Data.Secret exposing (Secret)
import DTT.Data.TodoEntry exposing (TodoEntry)
import Element exposing (Element)
import Element.Input as Input
import Framework
import Framework.Button as Button
import Framework.Card as Card
import Framework.Color as Color
import Framework.Grid as Grid
import Framework.Heading as Heading
import Framework.Input as Input
import Html exposing (Html)
import Json.Decode as D
import Json.Encode as E
import Random exposing (Seed)
import Task
import Time exposing (Posix)


type Error
    = InternalError ErrorJson
    | ParsingError E.Value
    | WrongFormat OutputForm
    | WrongInput
        { page : String
        , action : String
        }


type alias WaitingModel =
    { user : Maybe String
    , currentTime : Maybe Int
    , initialSeed : Maybe Float
    }


type alias RunningModel =
    { apiModel : Api.Model
    , error : Maybe Error
    , todoList : List TodoEntry
    , secretsList : List Secret
    , budget : Budget
    , inputId : String
    , inputContent : String
    , inputContent2 : String
    , inputAmount : String
    }


type Model
    = Waiting WaitingModel
    | Running RunningModel


type RunningMsg
    = ApiSpecific Api.Msg
    | FromApi E.Value
    | ChangedId String
    | ChangedContent String
    | ChangedContent2 String
    | ChangedAmount String
    | EnteredInput
        { page : String
        , action : String
        }


type WaitingMsg
    = GotSeed Seed
    | GotTime Posix
    | GotUser String


type Msg
    = RunningSpecific RunningMsg
    | WaitingSpecific WaitingMsg


initModel : Api.Model -> RunningModel
initModel apiModel =
    { apiModel = apiModel
    , error = Nothing
    , todoList = []
    , secretsList = []
    , budget =
        { totalCent = 0
        , spendings = []
        }
    , inputId = ""
    , inputContent = ""
    , inputContent2 = ""
    , inputAmount = ""
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( Waiting
        { user = Nothing
        , currentTime = Nothing
        , initialSeed = Nothing
        }
    , Cmd.batch
        [ Random.generate (GotSeed >> WaitingSpecific) Random.independentSeed
        , Task.perform (GotTime >> WaitingSpecific) Time.now
        ]
    )


validateWaitingModel : WaitingModel -> ( Model, Cmd Msg )
validateWaitingModel ({ user, currentTime, initialSeed } as waitingModel) =
    case ( user, currentTime, initialSeed ) of
        ( Just u, Just c, Just i ) ->
            let
                ( apiModel, cmd ) =
                    { user = u
                    , currentTime = c
                    , initialSeed = i
                    }
                        |> Api.init
            in
            ( Running (initModel apiModel)
            , cmd |> Cmd.map (ApiSpecific >> RunningSpecific)
            )

        _ ->
            ( Waiting waitingModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        defaultCase : ( Model, Cmd Msg )
        defaultCase =
            ( model, Cmd.none )
    in
    case ( msg, model ) of
        ( RunningSpecific runningMsg, Running runningModel ) ->
            case runningMsg of
                ApiSpecific apiMsg ->
                    Api.update
                        (Task.succeed >> Task.perform FromApi)
                        ApiSpecific
                        apiMsg
                        runningModel.apiModel
                        |> Tuple.mapBoth
                            (\m -> Running { runningModel | apiModel = m })
                            (Cmd.map RunningSpecific)

                FromApi value ->
                    case value |> Codec.decodeValue OutputForm.codec of
                        Ok ({ error, todo, secrets, budget } as outputForm) ->
                            case ( ( error, todo ), ( secrets, budget ) ) of
                                ( ( Just err, Nothing ), ( Nothing, Nothing ) ) ->
                                    ( Running { runningModel | error = Just (InternalError err) }, Cmd.none )

                                ( ( Nothing, Just todoList ), ( Nothing, Nothing ) ) ->
                                    ( Running
                                        { runningModel
                                            | error = Nothing
                                            , todoList = todoList
                                        }
                                    , Cmd.none
                                    )

                                ( ( Nothing, Nothing ), ( Just secretsList, Nothing ) ) ->
                                    ( Running
                                        { runningModel
                                            | error = Nothing
                                            , secretsList = secretsList
                                        }
                                    , Cmd.none
                                    )

                                ( ( Nothing, Nothing ), ( Nothing, Just b ) ) ->
                                    ( Running
                                        { runningModel
                                            | error = Nothing
                                            , budget = b
                                        }
                                    , Cmd.none
                                    )

                                _ ->
                                    ( Running { runningModel | error = Just (WrongFormat outputForm) }
                                    , Cmd.none
                                    )

                        Err _ ->
                            ( Running { runningModel | error = Just (ParsingError value) }
                            , Cmd.none
                            )

                ChangedId string ->
                    ( Running { runningModel | inputId = string }, Cmd.none )

                ChangedContent string ->
                    ( Running { runningModel | inputContent = string }, Cmd.none )

                ChangedContent2 string ->
                    ( Running { runningModel | inputContent2 = string }, Cmd.none )


                ChangedAmount string ->
                    ( Running { runningModel | inputAmount = string }, Cmd.none )

                EnteredInput { page, action } ->
                    let
                        inputNone =
                            { page = page
                            , action = action
                            , id = Nothing
                            , content = Nothing
                            , content2 = Nothing
                            , amount = Nothing
                            }

                        inputWithId =
                            { page = page
                            , action = action
                            , id = Just runningModel.inputId
                            , content = Nothing
                            , content2 = Nothing
                            , amount = Nothing
                            }

                        inputWithContent =
                            { page = page
                            , action = action
                            , id = Nothing
                            , content = Just runningModel.inputContent
                            , content2 = Nothing
                            , amount = Nothing
                            }

                        inputWithIdAndContent =
                            { page = page
                            , action = action
                            , id = Just runningModel.inputId
                            , content = Just runningModel.inputContent
                            , content2 = Nothing
                            , amount = Nothing
                            }
                        
                        inputWithContentAndContent2 =
                            { page = page
                            , action = action
                            , id = Nothing
                            , content = Just runningModel.inputContent
                            , content2 = Just runningModel.inputContent2
                            , amount = Nothing
                            }

                        inputWithContentAndAmount =
                            { page = page
                            , action = action
                            , id = Nothing
                            , content = Just runningModel.inputContent
                            , content2 = Nothing
                            , amount = String.toInt <| runningModel.inputAmount
                            }

                        inputWithIdAndContentAndAmount =
                            { page = page
                            , action = action
                            , id = Just runningModel.inputId
                            , content = Just runningModel.inputContent
                            , content2 = Nothing
                            , amount = String.toInt <| runningModel.inputAmount
                            }
                        inputWithIdAndContentAndContent2 =
                            { page = page
                            , action = action
                            , id = Just runningModel.inputId
                            , content = Just runningModel.inputContent
                            , content2 = Just runningModel.inputContent2
                            , amount = Nothing
                            }

                        maybeInput =
                            case
                                ( page
                                , action
                                , ( runningModel.inputId /= ""
                                  , runningModel.inputContent /= ""
                                  , runningModel.inputAmount |> String.toInt |> (/=) Nothing
                                  )
                                )
                            of
                                ( "todo", "sync", ( False, False, False ) ) ->
                                    Just inputNone

                                ( "todo", "insert", ( False, True, False ) ) ->
                                    Just inputWithContentAndContent2

                                ( "todo", "delete", ( True, False, False ) ) ->
                                    Just inputWithId
                                
                                ( "todo", "toggle", (True,False,False) ) ->
                                    Just inputWithId
                                
                                ( "todo", "update", ( True, True, False ) ) ->
                                    Just inputWithIdAndContentAndContent2

                                ( "secrets", "sync", ( False, False, False ) ) ->
                                    Just inputNone

                                ( "secrets", "insert", ( False, True, False ) ) ->
                                    Just inputWithContent

                                ( "secrets", "delete", ( False, True, False ) ) ->
                                    Just inputWithContent

                                ( "budget", "sync", ( False, False, False ) ) ->
                                    Just inputNone

                                ( "budget", "insert", ( False, True, True ) ) ->
                                    Just inputWithContentAndAmount

                                ( "budget", "delete", ( True, False, False ) ) ->
                                    Just inputWithId

                                ( "budget", "update", ( True, True, True ) ) ->
                                    Just inputWithIdAndContentAndAmount

                                _ ->
                                    Nothing
                    in
                    case maybeInput of
                        Just input ->
                            ( model
                            , input
                                |> Codec.encodeToValue InputForm.codec
                                |> Api.handleInput
                                |> Task.succeed
                                |> Task.perform (ApiSpecific >> RunningSpecific)
                            )

                        Nothing ->
                            ( Running
                                { runningModel
                                    | error =
                                        Just <|
                                            WrongInput <|
                                                { page = page
                                                , action = action
                                                }
                                }
                            , Cmd.none
                            )

        ( WaitingSpecific waitingMsg, Waiting waitingModel ) ->
            case waitingMsg of
                GotSeed seed ->
                    { waitingModel
                        | initialSeed =
                            Just <|
                                Tuple.first <|
                                    Random.step (Random.float 0 1) <|
                                        seed
                    }
                        |> validateWaitingModel

                GotTime posix ->
                    { waitingModel | currentTime = posix |> Time.posixToMillis |> Just }
                        |> validateWaitingModel

                GotUser string ->
                    { waitingModel | user = Just string }
                        |> validateWaitingModel

        _ ->
            defaultCase


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Running _ ->
            Time.every 10000 (Api.GotTime >> ApiSpecific >> RunningSpecific)

        _ ->
            Sub.none


view : Model -> Html Msg
view model =
    let
        button : { page : String, action : String } -> Element RunningMsg
        button ({ page, action } as route) =
            Input.button Button.simple <|
                { onPress = Just <| EnteredInput route
                , label = Element.text action
                }
    in
    Framework.layout [] <|
        Element.column Framework.container <|
            case model of
                Waiting _ ->
                    List.map (Element.map WaitingSpecific) <|
                        [ Element.el Heading.h1 <| Element.text "Select a User"
                        , Element.row Grid.simple <|
                            [ Input.button Button.simple
                                { label = Element.text "Julia"
                                , onPress = Just <| GotUser <| "Julia"
                                }
                            , Input.button Button.simple
                                { label = Element.text "Lucas"
                                , onPress = Just <| GotUser <| "Lucas"
                                }
                            ]
                        ]

                Running { error, todoList, secretsList, budget, inputId, inputContent,inputContent2, inputAmount, apiModel } ->
                    List.map (Element.map RunningSpecific) <|
                        [ case error of
                            Just e ->
                                Element.el (Card.large ++ Color.danger) <|
                                    Element.text <|
                                        case e of
                                            InternalError { errorType, content } ->
                                                "Internal Error:" ++ errorType ++ " - " ++ content

                                            ParsingError value ->
                                                "ParsingError: \n" ++ (value |> E.encode 2)

                                            WrongFormat _ ->
                                                "Wrong Format"

                                            WrongInput { page, action } ->
                                                "Wrong Input: " ++ page ++ " - " ++ action

                            Nothing ->
                                Element.none
                        , Element.el Heading.h2 <| Element.text <| "Logged in as " ++ apiModel.user
                        , Element.column Grid.section <|
                            [ Input.text Input.simple <|
                                { label = Input.labelLeft Input.label <| Element.text "Id"
                                , onChange = ChangedId
                                , placeholder = Nothing
                                , text = inputId
                                }
                            , Input.text Input.simple <|
                                { label = Input.labelLeft Input.label <| Element.text "Content"
                                , onChange = ChangedContent
                                , placeholder = Nothing
                                , text = inputContent
                                }
                            , Input.text Input.simple <|
                                { label = Input.labelLeft Input.label <| Element.text "Content2"
                                , onChange = ChangedContent2
                                , placeholder = Nothing
                                , text = inputContent2
                                }
                            , Input.text Input.simple <|
                                { label = Input.labelLeft Input.label <| Element.text "Amount"
                                , onChange = ChangedAmount
                                , placeholder = Nothing
                                , text = inputAmount
                                }
                            , Element.el Heading.h3 <| Element.text "page:\"todo\""
                            , Element.paragraph [] <|
                                [ button { page = "todo", action = "sync" }
                                , button { page = "todo", action = "insert" }
                                , button { page = "todo", action = "delete" }
                                , button { page = "todo", action = "update" }
                                , button { page = "todo", action = "toggle" }
                                ]
                            , Element.el Heading.h3 <| Element.text "page:\"secrets\""
                            , Element.paragraph [] <|
                                [ button { page = "secrets", action = "sync" }
                                , button { page = "secrets", action = "insert" }
                                , button { page = "secrets", action = "delete" }
                                ]
                            , Element.el Heading.h3 <| Element.text "page:\"budget\""
                            , Element.paragraph [] <|
                                [ button { page = "budget", action = "sync" }
                                , button { page = "budget", action = "insert" }
                                , button { page = "budget", action = "delete" }
                                , button { page = "budget", action = "update" }
                                ]
                            ]
                        , Element.el Heading.h2 <| Element.text "Todo List"
                        , Element.column Grid.section <|
                            (todoList
                                |> List.map
                                    (\{ id, user, message,category ,lastUpdated,checked } ->
                                        Element.row Grid.spacedEvenly <|
                                            [ Element.text <| id
                                            , Element.text <| user
                                            , Element.text <| message
                                            , Element.text <| case checked of
                                                Just True -> "True"
                                                Just False -> "False"
                                                Nothing -> ""
                                            , Element.text <| Maybe.withDefault "" <| category
                                            , Element.text <| "timestamp: " ++ (String.fromInt <| Time.posixToMillis <| lastUpdated)
                                            ]
                                    )
                            )
                        , Element.el Heading.h2 <| Element.text "Secrets"
                        , Element.column Grid.section <|
                            (secretsList
                                |> List.map
                                    (\{ hash, user, raw } ->
                                        Element.row Grid.spacedEvenly <|
                                            [ Element.text <| user
                                            , Element.text <| String.left 4 <| hash
                                            , Element.text <| Maybe.withDefault "" <| raw
                                            ]
                                    )
                            )
                        , Element.el Heading.h2 <| Element.text "Budget"
                        , Element.text <| "Balance : " ++ (String.fromFloat <| toFloat budget.totalCent / 100) ++ "€"
                        , Element.column Grid.section <|
                            (budget.spendings
                                |> List.map
                                    (\{ id, user, cent, reference } ->
                                        Element.row Grid.spacedEvenly <|
                                            [ Element.text <| id
                                            , Element.text <| user
                                            , Element.text <| (String.fromFloat <| toFloat cent / 100) ++ "€"
                                            , Element.text <| reference
                                            ]
                                    )
                            )
                        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
