-- DATOS - EN CM
(
local r_eje = 5
local l_total = 230
local esp_cortina = 2
local cant_vueltas = 0
local r_calculo = 0

while l_total > 0 do (
	r_calculo = r_eje + ((esp_cortina * cant_vueltas)/2)
	perim = (2 * pi * r_calculo)
	cant_vueltas += 1
	l_total -= perim
)
print ("-----------DIMENSIONS - IN CM----------------------------------------------------")
print ("REEL DIAMETER:" + (r_calculo*2) as String)
print ("REVOLUTIONS:" + (cant_vueltas) as String)
print ("SQUERE CAGE SIDE :" + (r_calculo * 2 +10) as String)
)
