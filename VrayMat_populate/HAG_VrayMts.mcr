macroScript HAG_VrayMts_gray
	category:"HAG tools" 
	ButtonText:"VrayMtl" 
	toolTip:"Populate Medit Slots with Vray Materials"
(
	on execute do (	
		local setMat = fileIn @"$userScripts/HAG tools/HAG_VrayMtlPopulate.ms"
		setMat.setSlots rndColor:false chk:(queryBox "Conserve scene materials slots?")
	)
)
macroScript HAG_VrayMts_rnd
	category:"HAG tools" 
	ButtonText:"VrayMtl rnd" 
	toolTip:"Populate Medit Slots with Vray Materials, apply random diffuse color"
(
	on execute do (	
		local setMat = fileIn @"$userScripts/HAG tools/HAG_VrayMtlPopulate.ms"
		setMat.setSlots rndColor:true chk:(queryBox "Conserve scene materials slots?")
	)
)
