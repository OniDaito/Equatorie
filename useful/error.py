#!/usr/bin/python3

import math

planet="saturn"

nasa=[]
f = open(planet +'_nasa.csv','r')
for line in f.readlines():
  splits = line.split(",")
  nasa.append(splits[3])

f.close()

ephem = []
f = open(planet+'_py.csv','r')
for line in f.readlines():
  splits = line.split(",")
  ephem.append(splits[1])

f.close()

eq = []
f = open(planet+'_eq.csv','r')
for line in f.readlines():
  splits = line.split(",")
  eq.append(splits[1])

f.close()

errors = []

total_from_nasa = 0
total_from_ephem = 0
nasa_max = 0
ephem_max = 0

def dtr (a): return a/360 * 2 * math.pi
def rtd (a): return a / (2*math.pi) * 360

for i in range(0,len(nasa)-1):
  n = float(nasa[i])
  p = float(ephem[i])
  e = float(eq[i])

  ne = rtd(math.fabs(math.sin(dtr(n))-math.sin(dtr(e))))
  pe = rtd(math.fabs(math.sin(dtr(p))-math.sin(dtr(e))))

  total_from_nasa += ne
  total_from_ephem += pe

  if ne > nasa_max:
    nasa_max = ne
  if pe > ephem_max:
    ephem_max = pe

total_from_nasa /= len(nasa)
total_from_ephem /= len(ephem)

print("NASA Error", total_from_nasa)
print("Ephem Error", total_from_ephem)
print("NASA Max Error", nasa_max)
print("Ephem Max Error", ephem_max)