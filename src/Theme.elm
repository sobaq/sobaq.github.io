module Theme exposing (..)

import Element exposing (Element, Attribute, Color, rgb255)
import Element.Background as Background
import Element.Font as Font

type alias Theme msg =
  List (Attribute msg)

base : Theme msg
base =
  [ Font.family
    [ Font.serif
    ]
  , Font.size 18
  ]

light : Theme msg
light =
  base ++
  [ Background.color (rgb255 252 251 250)
  ]

dark : Theme msg
dark =
  base ++
  [ Background.color (rgb255 10 10 10)
  , Font.color (rgb255 255 255 255)
  ]