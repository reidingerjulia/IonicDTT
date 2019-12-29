module Test exposing (main)

import Api exposing (Flag, init, subscriptions, update)
import Browser
import Codec
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
      { page:String
      , action:String
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
    , inputId : String
    , inputContent : String
    }


type Model
    = Waiting WaitingModel
    | Running RunningModel


type RunningMsg
    = ApiSpecific Api.Msg
    | FromApi E.Value
    | ChangedId String
    | ChangedContent String
    | EnteredInput
      { page:String
      , action:String
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
    , inputId = ""
    , inputContent = ""
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( Waiting
        { user = Nothing
        , currentTime = Nothing
        , initialSeed = Nothing
        }
    , Cmd.batch
      [Random.generate (GotSeed >> WaitingSpecific) Random.independentSeed
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
                    } |> Api.init
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
    case (msg,model) of
      (RunningSpecific runningMsg, Running runningModel) ->
        case runningMsg of
          ApiSpecific apiMsg ->
              Api.update
                (Task.succeed >> Task.perform FromApi)
                ApiSpecific
                apiMsg
                runningModel.apiModel
              |> Tuple.mapBoth
                (\m -> Running {runningModel | apiModel = m})
                (Cmd.map RunningSpecific)

          FromApi value ->
            case value |> Codec.decodeValue OutputForm.codec of
              Ok ({ error, todo, secrets } as outputForm) ->
                case ( error, todo, secrets ) of
                  ( Just err, Nothing, Nothing ) ->
                      ( Running { runningModel | error = Just (InternalError err) }, Cmd.none )

                  ( Nothing, Just todoList, Nothing ) ->
                      ( Running { runningModel 
                      | error = Nothing
                      , todoList = todoList }, Cmd.none )

                  ( Nothing, Nothing, Just secretsList ) ->
                      ( Running { runningModel 
                      | error = Nothing
                      , secretsList = secretsList }, Cmd.none )

                  _ ->
                      ( Running { runningModel | error = Just (WrongFormat outputForm) }
                      , Cmd.none )
              Err _ ->
                ( Running { runningModel | error = Just (ParsingError value) }
                , Cmd.none )
          ChangedId string ->
            ( Running {runningModel| inputId = string},Cmd.none)
          ChangedContent string ->
            ( Running {runningModel| inputContent = string},Cmd.none)
          EnteredInput {page,action} ->
            let
              inputNone =
                { page = page
                , action =action
                , id = Nothing
                , content = Nothing
                }
            
              inputWithId =
                { page = page
                , action =action
                , id = Just runningModel.inputId
                , content = Nothing
                }
              
              inputWithContent =
                { page = page
                , action =action
                , id = Nothing
                , content = Just runningModel.inputContent
                }
              
              inputWithBoth =
                { page = page
                , action =action
                , id = Just runningModel.inputId
                , content = Just runningModel.inputContent
                }

              maybeInput =
                case (page,action,(runningModel.inputId /= "",runningModel.inputContent /= "")) of
                  ("todo","sync",(False,False)) ->
                    Just inputNone
                  ("todo","insert",(False,True)) ->
                    Just inputWithContent
                  ("todo","delete",(True,False)) ->
                    Just inputWithId
                  ("todo","update",(True,True)) ->
                    Just inputWithBoth
                  ("secrets","sync",(False,False)) ->
                    Just inputNone
                  ("secrets","insert",(False,True)) ->
                    Just inputWithContent
                  ("secrets","delete",(False,True))->
                    Just inputWithContent
                  _ ->
                    Nothing
            in
            case maybeInput of
              Just input ->
                ( model
                ,input
                |> Codec.encodeToValue InputForm.codec
                |> Api.handleInput
                |> Task.succeed
                |> Task.perform (ApiSpecific >> RunningSpecific)
                )
              Nothing ->
                ( Running {runningModel|error = Just <| WrongInput <|
                    { page =  page
                    , action = action
                    }
                  }
                ,Cmd.none)

      (WaitingSpecific waitingMsg, Waiting waitingModel) ->
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
    button : {page:String,action:String} -> Element RunningMsg
    button ({page,action} as route) =
      Input.button Button.simple <|
                          { onPress = Just <| EnteredInput route
                          , label = Element.text action
                          }
  in
    Framework.layout [] <|
        Element.column Framework.container <|
            case model of
                Waiting _ ->
                    List.map (Element.map WaitingSpecific)  <|
                    [ Element.el Heading.h1 <| Element.text "Select a User"
                    , Element.row Grid.simple <|
                        [ Input.button (Button.simple)
                            { label = Element.text "Julia"
                            , onPress = Just <| GotUser <| "Julia"
                            }
                        , Input.button (Button.simple)
                            { label = Element.text "Lucas"
                            , onPress = Just <| GotUser <| "Lucas"
                            }
                        ]
                    ]

                Running { error, todoList, secretsList, inputId,inputContent } ->
                    List.map (Element.map RunningSpecific) <|
                    [ case error of
                        Just e ->
                            Element.el (Card.large++Color.danger) <|
                              Element.text <|
                                case e of
                                  InternalError {errorType,content} ->
                                    "Internal Error:" ++ errorType ++ " - " ++ content
                                  ParsingError value ->
                                    "ParsingError: \n" ++ (value |> E.encode 2)
                                  WrongFormat _->
                                    "Wrong Format"
                                  WrongInput {page,action} ->
                                    "Wrong Input: " ++ page ++ " - " ++ action


                        Nothing ->
                            Element.none
                    , Element.el Heading.h2 <| Element.text "Interface"
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
                      , Element.el Heading.h3 <| Element.text "page:\"todo\""
                      , Element.paragraph [] <|
                        [ button {page="todo",action="sync"}
                        , button {page="todo",action="insert"}
                        , button {page="todo",action="delete"}
                        , button {page="todo",action="update"}
                        ]
                      , Element.el Heading.h3 <| Element.text "page:\"secrets\""
                      , Element.paragraph [] <|
                        [ button {page="secrets",action="sync"}
                        , button {page="secrets",action="insert"}
                        , button {page="secrets",action="delete"}
                        ]
                      ]
                    , Element.el Heading.h2 <| Element.text "Todo List"
                    , Element.column Grid.section <| 
                        (todoList
                          |> List.map (\{id, user, message, lastUpdated} ->
                              Element.row Grid.spacedEvenly <|
                                [ Element.text <| id
                                , Element.text <| user
                                , Element.text <| message
                                , Element.text <| "timestamp: " ++ (String.fromInt <| Time.posixToMillis <| lastUpdated)
                                ]
                            )
                        )
                    , Element.el Heading.h2 <| Element.text "Secrets"
                    , Element.column Grid.section <|
                        (secretsList
                          |> List.map (\{hash, user, raw} ->
                            Element.row Grid.spacedEvenly <|
                              [Element.text <| user
                              ,Element.text <| String.left 4 <| hash
                              ,Element.text <| Maybe.withDefault "" <| raw
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
