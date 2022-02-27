macroScript BUMP_VrayMts_gray
	category:"BUMP tools" 
	ButtonText:"VrayMtl" 
	toolTip:"Populate Medit Slots with Vray Materials"
(
	on execute do (	
		local setMat = fileIn @"$userScripts/BUMP_VrayMtlPopulate.ms"
		setMat.setSlots rndColor:false chk:(queryBox "Conserve scene materials slots?")
	)
)
macroScript BUMP_VrayMts_rnd
	category:"BUMP tools" 
	ButtonText:"VrayMtl rnd" 
	toolTip:"Populate Medit Slots with Vray Materials, apply random diffuse color"
(
	on execute do (	
		local setMat = fileIn @"$userScripts/BUMP_VrayMtlPopulate.ms"
		setMat.setSlots rndColor:true chk:(queryBox "Conserve scene materials slots?")
	)
)
