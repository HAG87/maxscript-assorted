/*
------------------------------------------------------------------------------------------------------------------
https://atelierbump.com
Change gamma of normal maps - works with standard and Vray Normal maps.
------------------------------------------------------------------------------------------------------------------
*/
macroScript HAG_changeGamma
	category:"HAG tools"
	ButtonText:"NRMGAMMA"
	toolTip:"Change gamma of normal maps - works with standard and Vray Normal maps"
(
	rollout roll_gamma "Normal Maps gamma" height:220
	(
		group "Map type"
		(
			radiobuttons rd_1 "" labels:#("Normal Map", "Vray Normal Map") align:#left
		)
		group  "Operate on"
		(
			radiobuttons rd_2 "" labels:#("Scene materials", "Material editor slots") align:#left
		)
		group "New gamma value"
		(
			spinner spn_1 "Gamma: " type:#float range:[-100.0,100.0,1.0] align:#right
		)
		button btn_1 "Convert" width:(roll_gamma.width - 20) height:30
		progressbar prg_1  width:(roll_gamma.width) align:#center
		-----------------------------------------------------------------------------------------------------------
		fn NormalMapGammaConvert _class:VrayNormalMap _target:sceneMaterials _gamma:1.0f progress: =
		(
			local normal_maps = getClassInstances _class target:_target processChildren:true
			local curr_map, curr_bitmap, new_bitmap
			local tot_progress
			with redraw off
			(
				undo "Normal Maps Gamma" on
				(
					if normal_maps.count > 0 then (
						tot_progress = 100.0 / normal_maps.count
						for i=1 to normal_maps.count do (
							if progress != unsupplied then progress = (i * tot_progress) as Integer
						--	/*
							curr_map = np[i].normal_map
							if isKIndOf curr_map bitmapTexture then (
								curr_bitmap = curr_map.bitmap
								if doesFileExist (curr_bitmap.filename) and (curr_bitmap.InputGammaValue != _gamma) then (
									local new_bitmap = openBitMap curr_bitmap.filename gamma:_gamma channels:curr_bitmap.channels
									curr_map.bitmap = new_bitmap
								)
							)
						--	*/
						)
					)
				)
			)
			free curr_map
			free curr_bitmap
			free new_bitmap
			free normal_maps
			freeSceneBitmaps()
			gc light:on
		)
		-----------------------------------------------------------------------------------------------------------
		on btn_1 pressed do (
			local c = case rd_1.state of (
				1:(Normal_Bump)
				2:(VrayNormalMap)
			)
			local op = case rd_2.state of (
				1:(sceneMaterials)
				2:(meditMaterials)
			)
			NormalMapGammaConvert _class:c _target:op _gamma:spn_1.value progress:&(prg_1.value)
			prg_1.value = 100
		)
	)
	on isEnabled do roll_gamma.open
	on execute do CreateDialog roll_gamma
)

