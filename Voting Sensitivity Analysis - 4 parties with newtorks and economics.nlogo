globals [
;; codigos estáticos
ps psd pcp cds;; cores partidos
votaPsd votaPs votaPcp votaCds ;; codigos partidos

;; Variaveis sistema
partido-poder
economia ;; valor da economia (iniciado a 100)
centro-politico ;; define o valor que define o meio do espectro politico - iniciado a 0
limiar-ext-esquerda ;; valor a partir do qual os partidos catch-all de esquerda são menos benieficiados
limiar-ext-direita ;; valor a partir do qual os partidos catch-all de direita são menos benieficiados

]

;; Variaveis de cada patch/eleitor
patches-own [
  vote   ;; my vote (0, 1, 2, 3)
  viziPs ;; sum of votes on PS around me
  viziPsd ;; sum of votes on PSD around me
  viziPcp ;; sum of votes on PCP around me
  viziCds ;; sum of votes on CDS around me
]


;; Iniciação do sistema
to setup
  clear-all
  initiate-partidos
  if show_lim[create-limiar-turtles]

  ;; Gera um numero aleatorio de 1 a 100, e conforme se enquadre no intervalo de um dos partidos, atribui esse voto a esse partido
  ask patches [
    let choice random 100
  (ifelse
    choice < initial-psd-votes [
        set vote votaPsd    ]
    choice < initial-psd-votes + initial-ps-votes  [
      set vote votaPs
    ]
    choice < initial-psd-votes + initial-ps-votes + initial-pcp-votes [
      set vote votaPcp
    ]
    ; elsecommands
    [
    set vote votaCds
  ])
  ;; Invoca um metodo que atribui a cor do partido ao patch
    recolor-patch
  ]
  ;; inicia a econimia a 100
  set economia 100
  reset-ticks
  check-setup
end

;; atribui codigos numericos e de cores aos partidos para evitar erros mais à frente e ser mais simpleas alterar a cor.
to  initiate-partidos
  set psd orange
  set ps blue
  set cds yellow
  set pcp red

  set votaPsd 0
  set votaPs 1
  set votaPcp 2
  set votaCds 3

  set centro-politico 0
  set limiar-ext-esquerda -37.5
  set limiar-ext-direita 37.5
end

;; Cria as tartarugas que marcam o centro politico e os limiares de extrema esquera e extrema direita
to create-limiar-turtles
  create-turtles 1 [
    set color green
    set size 10
    set shape "person"
    setxy centro-politico 20
    set label "Centro"
    ]
   create-turtles 1 [
    set color white
    set size 8
    set shape "person"
    setxy limiar-ext-esquerda 0
    set label "Ext Esquerda"
    ]
   create-turtles 1 [
    set color black
    set size 8
    set shape "person"
    setxy limiar-ext-direita 0
    set label "Ext direita"
    ]
end


;; Metodo principal
to go
  tick
  update-partido-poder
  update-economia ;; atualiza valor da economia
  update-espectro-politico ;; define centro politico e limares ext esquerda e ext direita

  ask patches [
    ;; Conta  votos de outros patches de diferente forma conform tipologia de rede
   ifelse not rede-aleatoria [
      conta-votos-vizinhos
    ]
    [
      limpa-votos-vizinhos
      conta-votos-patches-aleatorios
    ]

    if rede-small-world
    [
      if not rede-aleatoria [ conta-votos-patches-aleatorios ]
    ]

   cria-aleatoriedade

   atribui-lealdade ;; beneficia o partido em que o eleitor votou nas ultimas eleições

   atribui-efeito-orientacao-poltica ;; dá vantagem na metade esquerda ou direita do cenário conforme o tipo de partido

   efeito-catch-all-party ;; beneficia partidos ao centro e prejudica-os nos extremos

   efeito-economia ;; aplica os dois efeitos de ecomomia 1) penaliza/benificia partido poder 2) desloca centro politico

   decide-voto ;; decide o proximo voto de cada eleitor
  ]
  tick
end

;; Faz a contagem dos votos dos 8 vizinhos
to conta-votos-vizinhos
  set viziPs  count neighbors with [vote = votaPs]
  set viziPsd count neighbors with [vote = votaPsd]
  set viziPcp count neighbors with [vote = votaPcp]
  set viziCds count neighbors with [vote = votaCds]
end


;; Faz uma contagem dos votos de patches aleatorios
to conta-votos-patches-aleatorios

      let i 0
      ;;Incremento por cada patch (metade da importancia dos vizinhos no caso da rede small-world
      let incremento-por-patch 0.5

      while  [i < 8]
      [
          let outro one-of patches
      (
         ifelse
      ([vote] of outro) = votaPsd [set viziPsd viziPsd + incremento-por-patch]
      ([vote] of outro) = votaPs [set viziPs viziPs + incremento-por-patch]

           ([vote] of outro) = votaPcp [set viziPcp viziPcp + incremento-por-patch]
           ([vote] of outro) = votaCds [set viziCds viziCds + incremento-por-patch]
      )
      set i i + 1
      ]
end

;; Rotina auxiliar para o caso da rede aleatoria em que não sao considerados os votos dos vizinhos.
to limpa-votos-vizinhos
   set viziPs  0
   set viziPsd 0
   set viziPcp 0
   set viziCds 0
end

;; introduz aleatoriedade no sistema
to cria-aleatoriedade
  set viziPs  viziPs * (1 - (random-float incerteza / 100 ))
  set viziPsd viziPsd * (1 - (random-float incerteza / 100 ))
  set viziPcp viziPcp * (1 - (random-float incerteza / 100 ))
  set viziCds viziCds * (1 - (random-float incerteza / 100 ))
end

;; atribui lealdade, beneficiando o partido em que votou nas ultimas eleições.
to atribui-lealdade
    (
          ifelse
          vote = votaPs [set viziPs viziPs + lealdade]
          vote = votaPsd [set viziPsd viziPsd + lealdade]
          vote = votaPcp [set viziPcp viziPcp + lealdade]
          vote = votaCds [set viziCds viziCds + lealdade]
      )
end

;; Efeito Direita Esquerda
to atribui-efeito-orientacao-poltica

    ifelse pxcor < centro-politico
    [
      set viziPs viziPs + peso-orientacao-politica / 50
      set viziPcp viziPcp + peso-orientacao-politica / 50
    ]
    [
     set viziPsd viziPsd + peso-orientacao-politica / 50
      set viziCds viziCds + peso-orientacao-politica / 50
    ]
end

;; beneficia partidos ao centro e prejudica nos extremos
to efeito-catch-all-party

     if pxcor > limiar-ext-esquerda and pxcor < limiar-ext-direita
    [
      if catch-all-ps [set viziPs viziPs + peso-orientacao-politica / 50]
      if catch-all-psd [set viziPsd viziPsd + peso-orientacao-politica / 50]
      if catch-all-pcp [set viziPcp viziPcp + peso-orientacao-politica / 50]
      if catch-all-cds [set viziCds viziCds + peso-orientacao-politica / 50 ]
    ]

     if pxcor < limiar-ext-esquerda [
      if not catch-all-ps [set viziPs viziPs + peso-orientacao-politica / 60]
      if not catch-all-pcp [set viziPcp viziPcp + peso-orientacao-politica / 60]
    ]
    if pxcor > limiar-ext-direita [
      if not catch-all-psd [set viziPsd viziPsd + peso-orientacao-politica / 60]
      if not catch-all-cds [set viziCds viziCds + peso-orientacao-politica / 60 ]
    ]
end


;; Caso a economia esteja acima de 100 beneficia o partido do poder e também (em menor escala) o outro partido da mesma familia politica
;; Caso esteja abaixo de 100 faz o contário
to efeito-economia
  let pond-economia (peso-economia-partido-poder * ((economia - 100) / 100 ))
  let pond-economia-familia  pond-economia ;; neste caso esta a beneficiar de igual forma o partido do poder e o partido da mesma familia politica
  (
  ifelse
    partido-poder = votaPs or partido-poder = votaPcp[
      set viziPs viziPs + pond-economia
      set viziPcp viziPcp + pond-economia-familia
    ]
    partido-poder = votaPsd or partido-poder = votaCds[
      set viziPsd viziPsd + pond-economia
      set viziCds viziCds + pond-economia-familia
    ]
  )
end

;; atualiza qual o partido no poder (mais votado
to update-partido-poder
  ;; verifica e atualiza o partido do poder
  let total-votos-ps count patches with [vote = votaPs]
  let total-votos-psd count patches with [vote = votaPsd]
  let total-votos-cds count patches with [vote = votaCds]
  let total-votos-pcp count patches with [vote = votaPcp]
  let max-votos max (list total-votos-ps total-votos-psd total-votos-cds total-votos-pcp)
  (
    ifelse
    max-votos = total-votos-ps [ set partido-poder votaPs ]
    max-votos = total-votos-psd [ set partido-poder votaPsd ]
    max-votos = total-votos-pcp [ set partido-poder votaPcp ]
    max-votos = total-votos-cds [ set partido-poder votaCds ]
  )
end

;; Altera o valor da economia
to update-economia
  let variacao ( random-float 10 ) - 5

  ;; caso a economia passe abaixo de 70 ou acima de 130 a variação será no sentido de evitar valores extremos
  (
  Ifelse
    economia + variacao < 70 [set economia economia + abs variacao]
    economia + variacao > 130 [set economia economia - abs variacao]
    [set economia economia + variacao]
  )
end

  ;; Economia acima de 100 provoca: 1) deslocamento do centro politico para a direita | b) alargamento do centro (e diminuição dos extremos)
to update-espectro-politico

  let ecopower ((100 - economia ) / 100) * -3.33  ;; Varia entre ]-1, 1[
  set centro-politico peso-economia-espectro * ecopower * (-1)               ;; Centro politico pode variar de -75 a 75
  set limiar-ext-direita 75 - (75 - centro-politico) /  (2 + ecopower)       ;; Ponto medio entre o centro politico e o final do mapa
  set limiar-ext-esquerda -75 - (-75 - centro-politico) /  (2 + ecopower)    ;; ponderado pelo ecopower

  ;; atualiza posição das turtles de marcação do espectro politico
  if show_lim [
    ask turtle 0 [
      set xcor centro-politico
    ]
    ask turtle 1 [
      set xcor limiar-ext-esquerda
    ]
    ask turtle 2 [
      set xcor limiar-ext-direita
    ]
  ]

end

;; Decide o sentido de voto de cada patch
to decide-voto
  ;; keep track of whether any patch has changed their vote
    let any-votes-changed? false
    let next-vote vote ;; variavel onde vai ser guardado o proxim

    ;; Verificacao do partido com mais votos na vizinhança
    if viziPsd > viziPs [
        if viziPsd > viziPcp [
          if viziPsd  > viziCds [
            set next-vote votaPsd
          ]
        ]
      ]

    if viziPs > viziPsd [
        if viziPs > viziPcp [
          if viziPs > viziCds [
            set next-vote votaPs
          ]
        ]
      ]

    if viziPcp > viziPs [
        if viziPcp > viziPsd [
          if viziPcp > viziCds [
            set next-vote votaPcp
          ]
        ]
      ]

    if viziCds > viziPsd [
        if viziCds > viziPcp [
          if viziCds > viziPs [
            set next-vote votaCds
          ]
        ]
      ]


    if vote != next-vote [
      ;;set any-votes-changed? true
      set vote next-vote
      recolor-patch
    ]


  ;; if the votes have stabilized, we stop the simulation
  if not any-votes-changed? [ stop ]

end


;; atrivui a cor aos patches
to recolor-patch
  if vote = votaPsd  [ set pcolor psd ]
  if vote = votaPs  [ set pcolor ps ]
  if vote = votaPcp  [ set pcolor pcp ]
  if vote = votaCds  [ set pcolor cds ]

end

;; This procedure checks to see if the SETUP procedure sets up the model with
;; roughly expected numbers, given the value of the initial-green-pct slider
to check-setup
  let expected-green (count patches * initial-psd-votes / 100)
  let diff-green (count patches with [ vote = 0 ]) - expected-green
  if diff-green > (.1 * expected-green) [
    print "Initial number of green voters is more than expected."
  ]
  if diff-green < (- .1 * expected-green) [
    print "Initial number of green voters is less than expected."
  ]
end

; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
230
10
691
472
-1
-1
3.0
1
10
1
1
1
0
1
1
1
-75
75
-75
75
1
1
1
ticks
30.0

BUTTON
716
442
781
475
setup
setup
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
790
442
850
475
Go forever
go
T
1
T
OBSERVER
NIL
X
NIL
NIL
0

MONITOR
717
281
809
326
Votos PS
count patches with\n  [ pcolor = ps ]
0
1
11

MONITOR
822
281
914
326
Votos PSD
count patches with\n  [ pcolor = psd ]
0
1
11

PLOT
714
14
874
134
Votos PS em %
NIL
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count patches with [pcolor = ps] / 240"

PLOT
890
14
1050
134
Votos PSD em %
NIL
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot count patches with [pcolor = psd] / 240"

MONITOR
717
331
807
376
Votos pcp
count patches with\n  [ pcolor = pcp ]
17
1
11

MONITOR
822
331
912
376
Votos CDS
count patches with\n  [ pcolor = cds ]
17
1
11

PLOT
714
144
874
264
Votos PCP em %
NIL
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count patches with [pcolor = pcp] / 240"

PLOT
890
144
1050
264
Votos CDS em %
NIL
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -10263788 true "" "plot count patches with [pcolor = cds] / 240"

SLIDER
10
10
125
43
initial-psd-votes
initial-psd-votes
0
100
35.0
1
1
NIL
HORIZONTAL

SLIDER
10
51
125
84
initial-ps-votes
initial-ps-votes
0
100 - initial-psd-votes
35.0
1
1
NIL
HORIZONTAL

SLIDER
10
90
125
123
initial-pcp-votes
initial-pcp-votes
0
100 - initial-psd-votes - initial-ps-votes
15.0
1
1
NIL
HORIZONTAL

SLIDER
10
131
125
164
inital-cds-votes
inital-cds-votes
0
100 - initial-psd-votes - initial-ps-votes - initial-pcp-votes
15.0
1
1
NIL
HORIZONTAL

BUTTON
866
442
926
475
Go Once
go
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

SLIDER
10
215
120
248
lealdade
lealdade
-5
10
2.5
0.5
1
NIL
HORIZONTAL

SLIDER
10
175
120
208
incerteza
incerteza
0
100
61.0
1
1
NIL
HORIZONTAL

SLIDER
10
255
120
288
peso-orientacao-politica
peso-orientacao-politica
0
100
37.0
1
1
NIL
HORIZONTAL

SWITCH
130
10
220
43
catch-all-psd
catch-all-psd
0
1
-1000

SWITCH
130
51
220
84
catch-all-ps
catch-all-ps
0
1
-1000

SWITCH
130
90
220
123
catch-all-pcp
catch-all-pcp
1
1
-1000

SWITCH
130
131
220
164
catch-all-cds
catch-all-cds
1
1
-1000

MONITOR
717
387
807
432
Votos Esquerda
count patches with\n  [ pcolor = ps ] + \n  count patches with \n  [ pcolor = pcp ]
17
1
11

MONITOR
822
387
912
432
Votos Direita
count patches with\n  [ pcolor = psd ] + \n  count patches with \n  [ pcolor = Cds ]
17
1
11

SWITCH
10
390
145
423
rede-aleatoria
rede-aleatoria
1
1
-1000

SLIDER
10
300
190
333
peso-economia-partido-poder
peso-economia-partido-poder
0
10
4.0
1
1
NIL
HORIZONTAL

PLOT
1061
16
1221
136
Evolucao Economica
NIL
NIL
0.0
10.0
70.0
130.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" "plot economia"

MONITOR
1055
140
1122
185
NIL
economia
17
1
11

SWITCH
10
432
145
465
rede-small-world
rede-small-world
1
1
-1000

TEXTBOX
777
286
792
304
█
10
105.0
1

TEXTBOX
777
337
792
355
█
10
15.0
1

TEXTBOX
887
286
902
304
█
10
25.0
1

TEXTBOX
887
337
902
355
█
10
45.0
1

SLIDER
10
340
192
373
peso-economia-espectro
peso-economia-espectro
0
75
22.0
1
1
NIL
HORIZONTAL

MONITOR
1125
140
1217
185
NIL
centro-politico
17
1
11

SWITCH
925
280
1027
313
show_lim
show_lim
0
1
-1000

@#$#@#$#@
## ACKNOWLEDGMENT

This model is from Chapter Seven of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## WHAT IS IT?

This model is a simple cellular automaton that simulates voting distribution by having each patch take a "vote" of its eight surrounding neighbors, then perhaps change its own vote according to the outcome. The sensitivity version of this model alters the original model by allowing the user to specify the initial percentage of the green patches in the model and to test whether the model's behavior is sensitive to the initial percentages of the colors.

## HOW TO USE IT

Click the SETUP button to create an approximately equal but random distribution of blue and green patches.  Click GO to run the simulation.

When both switches are off, the central patch changes its color to match the majority vote, but if there is a 4-4 tie, then it does not change.

If the CHANGE-VOTE-IF-TIED? switch is on, then in the case of a tie, the central patch will always change its vote.

If the AWARD-CLOSE-CALLS-TO-LOSER? switch is on, then if the result is 5-3, the central patch votes with the losing side instead of the winning side.

The INITIAL-GREEN-PCT slider controls the percentage of initial green patches.

## THINGS TO NOTICE

How does the INITIAL-GREEN-PCT affect the results of the model?

## THINGS TO TRY

Run the sensitivity-experiment in BehaviorSpace and graph the results using your favorite statistical analysis package.

## EXTENDING THE MODEL

The model currently has two monitors that show the number of green and blue patches. It would be nice to add a plot that shows the relationship between these two numbers. It could be a line plot showing the percentage of green patches, or it could be a histogram showing the count for each color. Why don't you try both and see which one you like best?

## RELATED MODELS

This is a slight variant of the Voting model in the Social Sciences section of the NetLogo models library.

It is a companion model to another model from Chapter seven of the Textbook, Voting Component Verification.

Another related model is Ising in the Chemistry and Physics section of the NetLogo models library. Although it's a physics model, the rules are very similar.

## CREDITS AND REFERENCES

This model is described in Rudy Rucker's "Artificial Life Lab", published in 1993 by Waite Group Press.

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W., Wilensky, U. (2008).  NetLogo Voting Sensitivity Analysis model.  http://ccl.northwestern.edu/netlogo/models/VotingSensitivityAnalysis.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Rand, W., Wilensky, U. -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="sensitivity-experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count patches with [ vote = 0 ] / count patches</metric>
    <steppedValueSet variable="initial-green-pct" first="25" step="5" last="75"/>
    <enumeratedValueSet variable="award-close-calls-to-loser?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-vote-if-tied?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
