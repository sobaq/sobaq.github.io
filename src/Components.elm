module Components exposing (leftPane, content, rightPane)

import Html exposing (Html, ul)
import Element exposing (Attribute, Element, rgb255, paddingEach, el, text, column, px, row, height, width)
import Element.Font as Font
import Element.Region as Region
import Element.Border as Border

none =
  { top = 0
  , right = 0
  , bottom = 0
  , left = 0
  }

iconLink :
  { src : String
  , description : String
  , href : String
  }
  -> Element msg
iconLink x = 
  Element.newTabLink []
  { url = x.href
  , label =
      Element.image [ height (px 25), width (px 25) ]
      { src = x.src
      , description = x.description
      }
  }

li : String -> Html msg
li x = Html.li [] [ Html.text x ]

-- Actually produces <div><ul></ul><div><ul></ul></div> etc.
-- But it works.
brokenUl : Int -> List (String) -> Element msg
brokenUl n x =
  case x of
    [] -> Element.none
    _  ->
      row []
          [ Element.html (ul [] (List.map (li) (List.take n x)))
          , brokenUl n (List.drop n x)
          ]

paragraph x =
  Element.paragraph [ paddingEach { none | top = 5 } ] x

-- the left pane is for navigation.
leftPane : Element msg
leftPane =
  column
    [ paddingEach { none | left = 25, right = 50 }
    ]
    [ column
        [ Font.variant Font.smallCaps
        , Font.size 32
        , paddingEach { none | bottom = 15 }
        , Border.widthEach { none | bottom = 1 }
        , Border.color (rgb255 100 100 100)
        ]
        [ el [ Font.color (rgb255 120 120 120) ] (text "defaults,\n")
        , text "noatime"
        ]
    -- Hack because elm-ui doesn't have a <hr>
    , column [ paddingEach { none | bottom = 20 } ] []
    -- Links
    , row []
      [
        iconLink
          { src = "../static/github.svg"
          , description = "My GitHub profile"
          , href = "https://github.com/6e6f61"
          }
      ]
    ]

content model =
  column
    [ Element.paddingEach { none | left = 20, right = 500 }
    , Element.width Element.fill
    ]
    [ el
      [ Region.heading 1, Font.size 48, paddingEach { none | bottom = 5 }]
      (text model.hello)
    , paragraph
      [ text
          """I'm a cybersecurity engineer and programmer. I'm also partial to geography,
          vexillology, aviation, and linguistics. I am particularly interested in
          functional programming; at the moment, I'm primarily engaging with Elm and
          Elixir."""
      ]
    -- , brokenUl 3 [ "test", "test2", "test3", "test4", "test5", "test6" ]
    ]

rightPane = text "Hello"