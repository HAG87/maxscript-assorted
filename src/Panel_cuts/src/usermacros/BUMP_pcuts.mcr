macroScript BUMP_panelcuts
	category:"BUMP tools"
	ButtonText:"PQT"
	toolTip:"Tool for generating wood panel cuts reports."
	icon: #("panel_cuts",1)
	(
		on execute do (
			fileIN @"$UserScripts/BUMP_panelCuts.ms"
		)
	)