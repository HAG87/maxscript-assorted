/*
VIEWPORT COMPOSITION GUIDES
2020
*/
macroscript DSTLBX_vpComp
	category:         "BUMP tools"
	buttontext:       "Photographic composition guides"
	tooltip:          "Photographic Composition guides"
(
	local vpCompositionGuides
	on execute do (
		-- vpCompositionGuides = undefined
		if vpCompositionGuides == undefined then vpCompositionGuides = (fileIn "$Scripts/vpCompositionGuides.mse")()
		vpCompositionGuides.showUI()
	)
	on isChecked do if (isProperty vpCompositionGuides #roll_compGuide) then vpCompositionGuides.roll_compGuide != undefined
)