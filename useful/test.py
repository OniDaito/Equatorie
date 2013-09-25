#!/usr/bin/python

import ephem,sys,math

date = sys.argv[1] + " 12:00:00"

moon = ephem.Moon()
moon.compute(date)
moone = ephem.Ecliptic(moon)
print("Moon:", moone.lon, moone.lat)

sys.exit()




'''
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

print(ephem.julian_date(date))
'''


mercury = ephem.Mercury()

y = 1901
while y <= 2013:

  for m in ['01','03','05','07','08','10','12']:

    d = 31

    date = str(y) + "/" + m + "/" + str(d) + " 12:00:00"
    mercury.compute(date)
    mercurye = ephem.Ecliptic(mercury)
    print(date + "," + str(float(repr(mercurye.lon)) / (2 * math.pi) * 360))

  y+=1
