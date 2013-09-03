#!/usr/bin/python

import ephem,sys,math

date = sys.argv[1] + " 12:00:00"

mercury = ephem.Mercury()
mercury.compute(date)
mercurye = ephem.Ecliptic(mercury)
print("Mercury:", mercurye.lon)

venus = ephem.Venus()
venus.compute(date)
venuse = ephem.Ecliptic(venus)
print("Venus:", venuse.lon)

mars = ephem.Mars()
mars.compute(date)
marse = ephem.Ecliptic(mars)
print("Mars:", marse.lon)


jupiter = ephem.Jupiter()
jupiter.compute(date)
jupitere = ephem.Ecliptic(jupiter)
print("Jupiter:", jupitere.lon)

saturn = ephem.Saturn()
saturn.compute(date)
saturne = ephem.Ecliptic(saturn)
print("Saturn:", saturne.lon)

h = 12
d = K = 1
m = J = 1
y = I = 1970


a = K - 32075 + 1461 * (I + 4800 + (J - 14) // 12 ) //4
b = 367 * (J - 2 -(J - 14)//12 * 12) // 12
c = 3 * ((I + 4900 + (J - 14)//12) // 100 ) // 4
j = a + b - c

a = (14 - m) // 12
yp = y + 4800 - a
mp = m + (12 * a) - 3

a1 = ( (153 * mp + 2 ) // 5 )
a2 = (365 * yp) 
a3 = (yp//4)
a4 = (yp//100) 
a5 = (yp//400) 

j = d + a1 + a2 + a3 - a4 + a5 - 32045

print(ephem.julian_date(date))

print(j,a,yp,mp,a1,a2,a3,a4,a5)