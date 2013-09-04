{EquatorieSystem} = require '../src/system'

eq = new EquatorieSystem()

x = 1901
while x <= 2013 

  for y in [0,2,4,6,7,9,11]
    
    d = new Date(x,y,30)
    if y not in [8,3,5,10]
      d = new Date(x,y,31)
    if y == 1
      d = new Date(x,y,28)

    d.setHours(12)
    eq.solveForPlanetDate("mars", d)
    console.log(d + "," + eq.state.truePlace)
  x++