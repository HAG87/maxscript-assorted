macroScript HAG_VrayMts_gray
	category:"HAG tools" 
	ButtonText:"VrayMtl" 
	toolTip:"Populate Medit Slots with Vray Materials"
(
	on execute do (	
		include "$userScripts/HAG_VrayMtlPopulate.ms"
		setMat=vrayPop()
		if queryBox "conserve scene materials slots?" then(
			setMat.setVraySlots rndColor:false chk:true
		)else(
			setMat.setVraySlots rndColor:false chk:false
		)
	)
)
