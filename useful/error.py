#!/usr/bin/python3

import math

planet= "saturn"

dates = []

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
  dates.append(splits[0])

f.close()

errors = []

total_from_nasa = 0
total_from_ephem = 0
nasa_max = 0
ephem_max = 0

std_n = 0
std_p = 0

def dtr (a): return a/360 * 2 * math.pi
def rtd (a): return a / (2*math.pi) * 360

for i in range(0,len(nasa)-1):
  n = float(nasa[i])
  p = float(ephem[i])
  e = float(eq[i])

  nd = n-e
  nd = (nd + 180) % 360 - 180
  pd = p-e
  pd = (pd + 180) % 360 - 180

  total_from_nasa += nd
  total_from_ephem += pd

  if nd > nasa_max:
    nasa_max = nd
  if pd > ephem_max:
    ephem_max = pd

total_from_nasa /= len(nasa)
total_from_ephem /= len(ephem)

for i in range(0,len(nasa)-1):
  n = float(nasa[i])
  p = float(ephem[i])
  e = float(eq[i])

  nd = n-e
  nd = (nd + 180) % 360 - 180
  pd = p-e
  pd = (pd + 180) % 360 - 180

  std_n += (nd * nd)
  std_p += (pd * pd)

  if nd > total_from_nasa * 2:
    print ("NASA Big Change", dates[i], nd)

  #if pe > total_from_nasa:
  #  print ("Ephem Big Change", dates[i], ne)

std_n = math.sqrt(std_n / len(nasa))
std_p = math.sqrt(std_p / len(nasa))

print("NASA Error", total_from_nasa)
print("Ephem Error", total_from_ephem)
print("NASA Max Error", nasa_max)
print("Ephem Max Error", ephem_max)
print("NASA Deviation", std_n)
print("Ephem Deviation", std_p)