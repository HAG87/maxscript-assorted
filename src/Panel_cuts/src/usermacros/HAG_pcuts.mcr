macroScript HAG_panelcuts
	category:"HAG tools"
	ButtonText:"PQT"
	toolTip:"Tool for generating wood panel cuts reports."
	icon: #("panel_cuts",1)
	(
		on execute do (
			fileIN @"$UserScripts/HAG_panelCuts.ms"
		)
	)