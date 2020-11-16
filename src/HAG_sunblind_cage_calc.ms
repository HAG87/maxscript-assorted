----------------------------------------------------
/* https://atelierbump.com */
----------------------------------------------------
-- Units in Centimeters
(
	-- Input data
	----------------------------------------------------
	-- Reel axis radius
	local r_eje = 5
	-- courtain length
	local l_total = 230
	-- courtain tickness
	local esp_cortina = 2
	----------------------------------------------------
	
	fn sunBlindCageCalc r_eje l_total esp_cortina =
	(
		-- calc - do not modify
		local cant_vueltas = 0
		local r_calculo    = 0
		while l_total > 0 do (
			r_calculo    =  r_eje + ((esp_cortina * cant_vueltas)/2)
			perim        =  (2 * pi * r_calculo)
			cant_vueltas += 1
			l_total      -= perim
		)
		#(r_calculo, perim, cant_vueltas, l_total)
	)

	rollout roll_ui "SunBlindCage" width:300
	(
		spinner spn_1 "Reel radius"        type:#float align:#left
		spinner spn_2 "Courtain length"    type:#float align:#left
		spinner spn_3 "Courtain thickness" type:#float align:#left

		button btn_1 "Calc" width:150
		editText txt_1 "" heigth:300 

		on btn_1 pressed do (

			local res = sunBlindCageCalc spn_1.value spn_2.value spn_3.length
			local res_str = "" as StringStream
			-- output
			format "-----------DIMENSIONS - IN CM-----------\n"             to:res_str
			format "FULL REEL DIAMETER: %\n" ((r_calculo*2) as String)      to:res_str
			format "COURTAIN REVOLUTIONS: %\n" (cant_vueltas as String)     to:res_str
			format "SQUARE CAGE SIDE: %\n" ((r_calculo * 2 + 10) as String) to:res_str
			txt_1.text = res_str as string
		)
	)
)
