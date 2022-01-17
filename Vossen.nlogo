globals [
  hour
  day
  year
  average-ideal-temperature
]

breed [foxes fox]

foxes-own [
  ideal-temperature
  pair-temperature
  age
  male ?
  days-till-hatch
  pair-fox
  travel-distance
  max-age
]

to setup
  clear-all
  reset-ticks
  set hour 0
  set day 0
  set year 0
  ask patches [
    set pcolor 29.9 - (temperature + 50) / 50 ;;om een koude wereld ook echt koud eruit te laten zien
  ]

  create-foxes population-start [
    set shape "fox"
    setxy random-xcor random-ycor
    set ideal-temperature temperature + random 5 - 2 ;;start with ideal temp between -2 and 2
    set color 105 - 10 * (5 + floor (ideal-temperature / 5))
    set size 5
    set days-till-hatch "x"
    set max-age 365 + random-exponential 700 ;;vossen worden tussen 0 en 14 jaar oud
    while[max-age > 5500] [
      set max-age 365 + random-exponential 700 ;;zorgen dat ze niet te oud worden, omdathet toch een random verdeling is is er een kans op vossen van 1000 jaar
    ]
    set age random max-age ;;willekeurige leeftijd tussen 0 en de maximale leeftijd van de vos
    set male random 2 = 1
  ]
END

to go
  hour_procedures
  set hour hour + 1
  if(hour = 24) [
    day_procedures
    set hour 0
    set day day + 1
    ifelse soortvorming [
      ask patches with [pycor <= 1 AND pycor >= -1][
        set pcolor black
      ]
      ask patches with [pycor < 1 AND pcolor != black][
        set pcolor 29.9 - (temperature2 + 50) / 50 ;;om een koude wereld ook echt koud eruit te laten zien
      ]
      ask patches with [pycor > 1 AND pcolor != black] [
        set pcolor 29.9 - (temperature + 50) / 50
      ]
    ]
    [
      ask patches [
        set pcolor 29.9 - (temperature + 50) / 50
      ]
    ]
    if(day = 365) [
      set year year + 1
      set day 0
      set temperature temperature + temperature-increase
      set temperature2 temperature2 + temperature-increase2
    ]
  ]
  tick
END

to hour_procedures
  ask foxes [set travel-distance 0.2 + random-float 0.2]
  move_foxes
  if(day < 60) [ ;;eerste 2 maanden van de lente is paarseizoen
    seek_pair
  ]
END

to day_procedures
  age_foxes
  get_average_temp
END

to get_average_temp
  let total-temp 0
  ask foxes [
    set total-temp total-temp + ideal-temperature
  ]
  set average-ideal-temperature (total-temp / count foxes)
END

to seek_pair
  ask foxes with [days-till-hatch = "x" AND age > 365] [
    let sex male
    let y ycor
    if(count foxes with [days-till-hatch = "x" AND self != myself AND sex != male AND age > 365] > 0) [
      set pair-fox min-one-of foxes with [days-till-hatch = "x" AND self != myself AND sex != male AND age > 365] [distance myself] ;;ik weet niet precies hoe maar dit werkt
      if (distance pair-fox < 2)[ ;;binnen 2km radius
        face pair-fox
        ifelse (distance pair-fox < travel-distance) [
          fd distance pair-fox
        ]
        [
          fd travel-distance
        ]
        if(distance pair-fox = 0) [
          ifelse(male) [
            let temp ideal-temperature
            set pair-temperature [ideal-temperature] of pair-fox
            ask pair-fox [
              set days-till-hatch 52
              set pair-temperature temp
            ]
          ]
          [
            set days-till-hatch 52 ;; gemiddelde tijd die een vossenbaby in de buik zit, dit laten verschillen is niet nodig
            set pair-temperature [ideal-temperature] of pair-fox
          ]
        ]
      ]
    ]
    set pair-fox 0
  ]
END

to move_foxes
  ask foxes [
    if(pair-fox = 0)[
      rt random 31 - 15
      if NOT (can-move? travel-distance) [
        rt 180
      ]
      if patch-left-and-ahead 0 travel-distance != nobody [
        if [pcolor] of patch-left-and-ahead 0 travel-distance = 0 [
          rt 180
        ]
      ]

      fd travel-distance
    ]
  ]
END

to age_foxes
  ask foxes [
    ifelse (Soortvorming)[
      ifelse (ycor > 0) [
        set age age + 1 + abs (temperature - ideal-temperature) * 0.3
      ]
      [
        set age age + 1 + abs (temperature2 - ideal-temperature) * 0.3
      ]
    ]
    [
      set age age + 1 + abs (temperature - ideal-temperature) * 0.3
    ]
    if (days-till-hatch != "x" AND days-till-hatch != "hatched") [
      set days-till-hatch days-till-hatch - 1
      if (days-till-hatch <= 0) [
        let ideal-temperature-mother ideal-temperature
        let ideal-temperature-father pair-temperature
        hatch 5 + random 3 [ ;;tussen 5 en 7 per hatch
          set age 0
          set color 105 - 10 * (5 + floor (ideal-temperature / 5))
          set male random 2 = 1
          set days-till-hatch "x"
          let diff abs ideal-temperature-mother - ideal-temperature-father
          ifelse (ideal-temperature-mother > ideal-temperature-father) [
            ifelse(random 2 = 1)[ ;;gotta do this because of some weird bug
              set ideal-temperature ideal-temperature-mother - (random (diff + 1)) + random 3 - 1
            ]
            [
              set ideal-temperature ideal-temperature-father + (random (diff + 1)) + random 3 - 1
            ]
          ]
          [
            ifelse(random 2 = 1)[
              set ideal-temperature ideal-temperature-father - (random (diff + 1)) + random 3 - 1
            ]
            [
              set ideal-temperature ideal-temperature-mother + (random (diff + 1)) + random 3 - 1
            ]
          ]
          ifelse(random 2 = 0) [
            set max-age random 305
          ]
          [
            set max-age 305 + random-exponential 700 ;;vossen worden tussen 0 en 14 jaar oud
            while[max-age > 5500] [
              set max-age 305 + random-exponential 700 ;;zorgen dat ze niet te oud worden, omdat het toch een random verdeling is is er een kans op vossen van 1000 jaar
            ]
          ]
        ]
        set days-till-hatch "hatched"
      ]
    ]
    if(age >= max-age) [
      die
    ]
  ]
END

to GENEFLOW
  create-foxes 1 [
    set shape "fox"
    setxy random-xcor random-ycor
    set ideal-temperature geneflow-temperature
    set color 105 - 10 * (5 + floor (ideal-temperature / 5))
    set size 5
    set days-till-hatch "x"
    set max-age 365 + random-exponential 600 ;;vossen worden tussen 0 en 14 jaar oud
    while[max-age > 5500] [
      set max-age 365 + random-exponential 600 ;;zorgen dat ze niet te oud worden, omdathet toch een random verdeling is is er een kans op vossen van 1000 jaar
    ]
    set age random max-age ;;willekeurige leeftijd tussen 0 en de maximale leeftijd van de vos
    set male random 2 = 1
  ]
END

to GENETICDRIFT
  ask fox fox-number [
    die
  ]
END
@#$#@#$#@
GRAPHICS-WINDOW
369
26
877
535
-1
-1
4.9505
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
59
73
123
106
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
59
125
122
158
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
256
197
289
temperature
temperature
-50
50
13.0
1
1
° C
HORIZONTAL

SLIDER
131
75
303
108
population-start
population-start
1
100
41.0
1
1
NIL
HORIZONTAL

PLOT
909
271
1347
496
population size
ticks
aantal vossen
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count foxes"

PLOT
895
10
1337
226
average ideal temperature
ticks
avg temp
0.0
10000.0
6.0
16.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average-ideal-temperature"

MONITOR
1359
95
1416
140
year
year
17
1
11

INPUTBOX
208
258
355
318
temperature-increase
0.0
1
0
Number

MONITOR
1366
191
1423
236
NIL
day
17
1
11

BUTTON
12
433
107
466
NIL
GENEFLOW
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
122
434
275
494
geneflow-temperature
5.5
1
0
Number

BUTTON
0
502
116
535
NIL
GENETICDRIFT
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
121
503
276
563
fox-number
1.0
1
0
Number

TEXTBOX
211
323
361
365
De jaarlijkse stijging van temperatuur, voer een negatief getal in voor daling
11
0.0
1

TEXTBOX
283
435
362
501
Ideale temperatuur van de vos die erbij komt
11
0.0
1

TEXTBOX
279
504
361
555
Nummer van de vos die sterft (verdwijnt)
11
0.0
1

TEXTBOX
305
71
377
130
Het aantal vossen waarmee we beginnen
11
0.0
1

SWITCH
42
179
171
212
Soortvorming
Soortvorming
1
1
-1000

SLIDER
18
372
190
405
temperature2
temperature2
-50
50
13.0
1
1
°C
HORIZONTAL

TEXTBOX
48
353
198
371
Alleen voor soortvorming
11
0.0
1

INPUTBOX
197
373
352
433
temperature-increase2
0.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

A model showing how natural selection works, including concepts like genetic drift, gene flow and the making of species (simplified).
Some things are written in Dutch, while other things are written in English, depending on what my mood was while writing the script. I am sorry for this, I might change it in the future. 

## HOW IT WORKS

Foxes in this model have an ideal temperature. Offspring of these foxes inherit these temperatures, the offspring can have a temperature between, 1 above or 1 below the temperatures of their parents. Having a greater difference in ideal temperature and surrounding temperature makes foxes age faster, and thus die sooner.

## HOW TO USE IT

Adjust the population-start slider to your liking, and afterwards press 'setup'. Once your variables such as temperature and temperature-increase (yearly) are set, you can run the model with the 'go' button.
Switching on 'soortvorming' creates a barrier in the middle of the world, seperating two groups. You may vary the temperatures on both sides of the barrier, which simulates the origin of different species.
The 'geneflow' button adds a fox to the with a variable temperature, and the 'genetic drift' button removes a fox with a variable fox number (which you can see by right-clicking the fox)

## THINGS TO NOTICE

You may notice an increase in the average temperature while increasing the surrounding temperature, which is what we were hoping to simulate with this model. The color of foxes should change as well, with blue colors indicating a cold ideal temperature and red colors a warm ideal temperature.

## THINGS TO TRY

I would suggest to try and increase/decrease the temperature to see what foxes can adapt to. Note that what normally happens over millions of years now happens in a single decade, so this model is not fit to measure the time it takes for foxes to adapt. This is because this model's primary purpose is to show how natural selection works, and running this model for a day just to show how the natural selection works would be overkill.

## EXTENDING THE MODEL

You might add a way to cap the foxes' population, as of right now the population can easily increase to up to thousands of foxes which is really not realistic. I have not added this yet because I would not know how to implement it, and I could not find sufficient information about the territory of these foxes.

## NETLOGO FEATURES

This model uses the random-exponential function provided by Netlogo to calculate the maximum age of the foxes, making it probable but extremely unlikely for these foxes to reach their maximum age.


## CREDITS AND REFERENCES

Baldwin, M. (z.d.). Red Fox Territory & Home Range | Wildlife Online. Wildlifeonline.Me.Uk. Geraadpleegd op 7 december 2021, van https://www.wildlifeonline.me.uk/animals/article/red-fox-territory-home-range 

Fox, C. (2021, 9 juni). Red Foxes: The ULTIMATE Guide. All Things Foxes. Geraadpleegd op 7 december 2021, van https://allthingsfoxes.com/red-foxes/ 

Schofield, R. D. (1958). Litter Size and Age Ratios of Michigan Red Foxes. The Journal of Wildlife Management, 22(3), 313. https://doi.org/10.2307/3796468 

FoxesWorlds. (2014, 10 maart). Fox Reproduction. Fox Facts and Information. Geraadpleegd op 9 december 2021, van https://www.foxesworlds.com/fox-reproduction/ 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

fox
true
0
Circle -7500403 true true 150 45 90
Polygon -7500403 true true 150 90 120 105 120 225 180 225 195 210 195 150 210 135 225 120
Line -7500403 true 225 120 150 75
Polygon -16777216 false false 120 120
Polygon -7500403 true true 120 120 90 120 75 105 75 135 120 135
Polygon -7500403 true true 120 195 90 195 75 180 75 210 120 210
Polygon -7500403 true true 180 225 180 270 180 285 165 300 150 300 135 300 135 285 135 270 150 255 150 255 150 225
Polygon -7500403 true true 195 45 180 15 165 30 165 15 165 60
Polygon -7500403 true true 225 60 270 60 240 90
Polygon -16777216 true false 165 30 180 30 180 15
Polygon -16777216 true false 225 75 255 60 225 90
Rectangle -16777216 true false 195 60 210 75
Polygon -1 true false 150 105 135 120 135 195 120 195 120 105 150 90
Line -16777216 false 120 135 120 120
Line -16777216 false 120 195 120 210
Polygon -1 true false 135 285 150 285 165 300 135 300

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
