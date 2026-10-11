-- snaps manager tool
MacroScript BUMP_snapSets
	category:        "DSTLBX tools"
	ButtonText:      "Snap state sets"
	toolTip:         "Dstlbx - Snap state sets: Save Snap settings States"
	iconName:        "DesignToolbox/magnet"
	silentErrors:    true
	(
		local comboSnap
		on execute do (
			if comboSnap == undefined then comboSnap = fileIN @"$UserScripts/BUMP_SnapSets.mse"
			comboSnap.show_ui()
		)
		on isChecked do if comboSnap != undefined then comboSnap.open else false
		on closeDialogs do if comboSnap != undefined then comboSnap.close_ui()
	)