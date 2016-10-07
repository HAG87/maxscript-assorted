macroScript HAG_VrayMts_rnd
	category:"HAG tools" 
	ButtonText:"VrayMtl rndC" 
	toolTip:"Populate Medit Slots with Vray Materials apply random coloring"
(
	on execute do (	
		include "$userScripts/HAG_VrayMtlPopulate.ms"
		setMat=vrayPop()
		if queryBox "conserve scene materials slots?" then(
			setMat.setVraySlots rndColor:true chk:true
		)else(
			setMat.setVraySlots rndColor:true chk:false
		)
	)
)
