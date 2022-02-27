macroScript BUMP_AdvPathMngr
	category:"BUMP tools"
	ButtonText:"APM"
	toolTip:"Advanced User Paths manager"
(

	local path_a = "$UserScripts/BUMP_AdvPathMngr.ms"
	local path_b = "$scripts/BUMP_AdvPathMngr.ms"
	
	-- safe execution. Check if script is present in either scripts or userScripts folder
	on execute do (
		if doesFileExist path_a then
			filein path_a
		else if doesFileExist path_b then
			filein path_b
		else
			messageBox "Script file missing!"
	)
)
