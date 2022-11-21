module Main exposing (..)

import Theme exposing (Theme, light, dark)
import Components exposing (leftPane, content, rightPane)

import Browser
import Html
import Time
import Element exposing (Element, text, row, column, el, paddingXY)
import Element.Input exposing (button)
import Random exposing (generate)
import Random.List as List

type Msg
  = Theme (Theme Msg)
  | Redirect Page
  | GenRandomHello Time.Posix
  | Hellos (List String)

type alias Model =
  { theme : Theme Msg
  , page : Page
  , hello: String
  }

type Page = Home | Article Int

main =
  Browser.element
    { init = init
    , subscriptions = subscriptions
    , update = update
    , view = view
    }

init : () -> (Model, Cmd Msg)
init _ =
  ( { theme = Theme.light
  , page = Home
  , hello = "Hi,"
  }, randomHello )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Theme t ->
      ( { model | theme = t
      }, Cmd.none )
    Redirect p ->
      ( { model | page = p
      }, Cmd.none )
    GenRandomHello _ ->
      ( model
      , randomHello
      )
    Hellos h ->
      ( { model | hello = (Maybe.withDefault "Hi" (List.head h)) ++ "," }, Cmd.none )
    

view : Model -> Html.Html Msg
view model =
  Element.layout (List.append model.theme [ Element.paddingXY 0 30 ])
  <|
    case model.page of
      Home ->
        row []
          [ el [ Element.alignTop] leftPane
          , content model
          ]
      Article id ->
        Element.el [] (text ("This is article ID " ++ (String.fromInt id)))

subscriptions : Model -> Sub Msg
subscriptions _ =
  Time.every 4000 GenRandomHello

randomHello =
  Random.generate Hellos
  <|
    List.shuffle
      [ "Salut"
      , "Hi"
      , "¿Cómo estás?"
      , "Привет"
      , "你好"
      , "Ciao"
      , "やあ"
      ]