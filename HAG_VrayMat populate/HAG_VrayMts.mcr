macroScript HAG_VrayMts_gray
	category:"HAG tools" 
	ButtonText:"VrayMtl" 
	toolTip:"Populate Medit Slots with Vray Materials"
(
	on execute do (	
		local setMat = fileIn @"$userScripts/HAG tools/HAG_VrayMtlPopulate.ms"
		if queryBox "conserve scene materials slots?" then(
			setMat.setVraySlots rndColor:false chk:true
		)else(
			setMat.setVraySlots rndColor:false chk:false
		)
	)
)
macroScript HAG_VrayMts_rnd
	category:"HAG tools" 
	ButtonText:"VrayMtl rndC" 
	toolTip:"Populate Medit Slots with Vray Materials apply random coloring"
(
	on execute do (	
		local setMat = fileIn @"$userScripts/HAG tools/HAG_VrayMtlPopulate.ms"
		if queryBox "conserve scene materials slots?" then(
			setMat.setVraySlots rndColor:true chk:true
		)else(
			setMat.setVraySlots rndColor:true chk:false
		)
	)
)