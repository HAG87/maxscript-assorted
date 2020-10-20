/*
    These MacroScripts are designed to look for the source script in either Scripts / User scripts folders.
*/
-- Node Merge tool
MacroScript HAG_nodeMerge
	category:   "HAG tools"
	ButtonText: "Merge nodes"
	(
		local _Tool
		on execute do
		(
			_Tool = if _Tool == undefined then (
				try (
					fileIn("$Scripts\\HAG_Merge_tool.ms")
				) catch (
					fileIn("$UserScripts\\HAG_Merge_tool.ms")
				)
			) else _Tool

			if _Tool != undefined then (
				_Tool.nodeMerge (getCurrentSelection()) backup:(queryBox "Keep original nodes?" title:"Node Merge tool")
			)
		)
	)
-- Node Explode Tool
MacroScript HAG_nodeExplode
	category:   "HAG tools"
	ButtonText: "Explode nodes"
	(
		local _Tool
		on execute do
		(
			_Tool = if _Tool == undefined then (
				try (
					fileIn("$Scripts\\HAG_Merge_tool.ms")
				) catch (
					fileIn("$UserScripts\\HAG_Merge_tool.ms")
				)
			) else _Tool

			if _Tool != undefined then (
				_Tool.nodeExplode (getCurrentSelection()) backup:(queryBox "Keep original nodes?" title:"Node Explode tool")
			)
		)
	)