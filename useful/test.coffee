{EquatorieSystem} = require '../src/system'
{CoffeeGL} = require '../lib/coffeegl/coffeegl'

eq = new EquatorieSystem()

###
x = 1901
while x <= 2013 

  for y in [0,2,4,6,7,9,11]
    
    d = new Date]x,y,30)
    if y not in [8,3,5,10]
      d = new Date]x,y,31)
    if y == 1
      d = new Date]x,y,28)

    d.setHours]12)
    eq.solveForPlanetDate]"mars", d)
    console.log]d + "," + eq.state.truePlace)
  x++
###

evans = [
  [283,256,244,46],
  [294,262,245,46],
  [306,268,246,48],
  [318,274,246,49],
  [330,280,247,50],
  [341,286,246,51],
  [353,292,246,52],
  [5,297,245,53],
  [17,302,244,55],
  [29,307,242,56],
  [41,312,241,58],
  [53,316,240,59],
  [66,319,239,60],
  [78,321,238,61],
  [90,322,237,62],
  [103,322,237,63],  
  [115,320,236,64],
  [127,318,237,65],
  [140,315,237,65],
  [152,313,238,66],
  [164,312,239,66],
  [177,312,240,66],
  [189,314,242,67],
  [202,316,243,67],
  [214,318,245,66],
  [227,322,247,66],
  [239,328,249,65],
  [252,333,251,64],
  [264,340,253,63],
  [277,346,256,61],
  [289,352,258,60],
  [302,358,261,59],
  [314,5,263,59],
  [326,12,265,59],
  [338,18,267,58],
  [350,24,269,58],
  [2,31,271,59],
  [14,38,273,59],
  [26,44,274,60],
  [37,51,276,61],
  [48,57,277,61],
  [59,64,278,62],
  [69,70,278,64],
  [78,77,279,65],
  [86,84,279,66],
  [91,90,278,67],
  [95,97,278,69],
  [94,103,277,70],
  [89,109,276,72],
  [83,115,274,73],
  [77,122,273,74],
  [76,128,271,75],
  [80,134,270,76],
  [85,141,269,77],
  [93,147,269,78],
  [101,153,268,79],
  [111,160,268,79],
  [121,166,269,80],
  [132,173,269,80],
  [143,179,270,80],
  [154,186,271,80],
  [166,192,272,80],
  [178,198,274,81],
  [190,205,276,80],
  [202,212,278,79],
  [214,218,280,78],
  [227,225,282,77],
  [239,232,284,76],
  [252,238,287,75],
  [264,245,289,74],
  [277,252,291,73],
  [289,259,294,73],
  [302,266,296,73],
  [315,272,298,73],
  [327,280,300,73],
  [340,287,303,74],
  [352,294,305,74],
  [4,301,306,75],
  [17,308,308,76],
  [29,315,309,77],
  [41,322,310,78],
  [54,329,311,79],
  [66,336,312,81],
  [79,343,312,82],
  [91,350,312,83],
  [103,357,312,85],
  [116,4,312,86],
  [128,10,311,87],
  [140,16,310,89],
  [152,22,308,89],
  [164,27,306,90],
  [176,31,305,91],
  [188,35,304,92],
  [200,38,303,93],
  [211,39,302,94],
  [223,39,302,94],
  [235,38,302,94],
  [246,35,302,95],
  [257,32,303,94],
  [268,29,304,94],
]



x = 10
i = 0
d = new Date(1971,1,7)

ve = 0
me = 0
je = 0
se = 0 

while d.getFullYear() < 1984 and i < evans.length
 
  d.setDate(d.getDate()+x)

  d.setHours(12)
  out = d + ":"
  #eq.solveForPlanetDate]"sun", d)
  #out += eq.state.truePlace.toFixed]0) + ","
  #eq.solveForPlanetDate]"mercury", d)
  #out += eq.state.truePlace.toFixed]0) + ","
  eq.solveForPlanetDate("venus", d)
  r = eq.state.truePlace.toFixed(0)
  a = evans[i][0] - r
  a = (a + 180) % 360 - 180
  ve += Math.abs a

  out += r
  
  eq.solveForPlanetDate("mars", d)
  r = eq.state.truePlace.toFixed(0)
  a = evans[i][1] - r
  a = (a + 180) % 360 - 180
  me += Math.abs a

  out += r + ","

  eq.solveForPlanetDate("jupiter", d)
  r = eq.state.truePlace.toFixed(0)
  a = evans[i][2] - r
  a = (a + 180) % 360 - 180
  je += Math.abs a
  out += r + ","

  eq.solveForPlanetDate("saturn", d)
  r = eq.state.truePlace.toFixed(0)
  a = evans[i][3] - r
  a = (a + 180) % 360 - 180
  se += Math.abs a
  out += r

  console.log out
  i+=1

ve = ve/evans.length
me = me/evans.length
je = je/evans.length
se = se/evans.length

vs = 0
ms = 0
js = 0
ss = 0

d = new Date(1971,1,7)

i=0
while  i < evans.length
  d.setDate(d.getDate()+x)
  eq.solveForPlanetDate("venus", d)
  r = evans[i][0] - eq.state.truePlace.toFixed(0)
  e = (r + 180) % 360 - 180
  vs += (e*e)

  eq.solveForPlanetDate("mars", d)
  r = evans[i][1] - eq.state.truePlace.toFixed(0)
  e = (r + 180) % 360 - 180
  ms += (e*e)

  eq.solveForPlanetDate("jupiter", d)
  r = evans[i][2] - eq.state.truePlace.toFixed(0)
  e = (r + 180) % 360 - 180
  js += (e*e)

  eq.solveForPlanetDate("saturn", d)
  r = evans[i][3] - eq.state.truePlace.toFixed(0)
  e = (r + 180) % 360 - 180
  ss += (e*e)

  i+=1

vs = Math.sqrt(vs / evans.length)
ms = Math.sqrt(ms / evans.length)
js = Math.sqrt(js / evans.length)
ss = Math.sqrt(ss / evans.length)

console.log ve,me,je,se
console.log vs,ms,js,ss