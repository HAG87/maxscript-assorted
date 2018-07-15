-- Units in Centimeters
(
	----------------------------------------------------
	-- Imput data
	-- Reel axis radius
	local r_eje = 5
	-- courtain length
	local l_total = 230
	-- courtain tickness
	local esp_cortina = 2
	----------------------------------------------------
	-- calc - do not modify
	local cant_vueltas = 0
	local r_calculo = 0
	while l_total > 0 do (
		r_calculo = r_eje + ((esp_cortina * cant_vueltas)/2)
		perim = (2 * pi * r_calculo)
		cant_vueltas += 1
		l_total -= perim
	)
	-- output
	print "-----------DIMENSIONS - IN CM----------------------------------------------------\n"
	format "FULL REEL DIAMETER: %\n" ((r_calculo*2) as String)
	format "COURTAIN REVOLUTIONS: %\n" (cant_vueltas as String)
	format "SQUARE CAGE SIDE: %\n" ((r_calculo * 2 + 10) as String)
)
