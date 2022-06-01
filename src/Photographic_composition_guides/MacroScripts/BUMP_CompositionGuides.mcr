/*
VIEWPORT COMPOSITION GUIDES
2020
2022 - Added compatibility with Autodesk Exchange store
*/
macroscript DSTLBX_vpComp
	category:         "BUMP tools"
	buttontext:       "Photographic composition guides"
	tooltip:          "Photographic Composition guides"
(
	-- this will contain an instance of the tool
	local vpCompositionGuides
	-- run each time the MacrosCript is executed...
	on execute do (
		-- vpCompositionGuides = undefined
		-- safe load with support for Exchange store
		fn loadScriptFile =
		(
			local ExchangeStorePath = "$publicExchangeStoreInstallPath/Photographic composition guides.bundle/Contents/scripts/vpCompositionGuides.mse"
			local LegacyPath = "$Scripts/vpCompositionGuides.mse"

			if doesFileExist ExchangeStorePath
			then (filein ExchangeStorePath)()
			else if doesFileExist LegacyPath
			then (filein LegacyPath)()
			else undefined
		)

		if vpCompositionGuides == undefined then (
			-- load the script file in to memory
			vpCompositionGuides = loadScriptFile()
		) else (
			-- open the tool UI
			vpCompositionGuides.showUI()
		)
	)
	-- check ui button state
	on isChecked do if (isProperty vpCompositionGuides #roll_compGuide) then vpCompositionGuides.roll_compGuide != undefined
)