/*
    These MacroScripts are designed to look for the source script in either Scripts / User scripts folders.
*/
-- Node Merge tool
MacroScript BUMP_nodeMerge
	category:   "BUMP tools"
	ButtonText: "Merge nodes"
	(
		local _Tool
		on execute do
		(
			_Tool = if _Tool == undefined then (
				try (
					fileIn("$Scripts\\BUMP_Merge_tool.ms")
				) catch (
					fileIn("$UserScripts\\BUMP_Merge_tool.ms")
				)
			) else _Tool

			if _Tool != undefined then (
				_Tool.nodeMerge (getCurrentSelection()) backup:(queryBox "Keep original nodes?" title:"Node Merge tool")
			)
		)
	)
-- Node Explode Tool
MacroScript BUMP_nodeExplode
	category:   "BUMP tools"
	ButtonText: "Explode nodes"
	(
		local _Tool
		on execute do
		(
			_Tool = if _Tool == undefined then (
				try (
					fileIn("$Scripts\\BUMP_Merge_tool.ms")
				) catch (
					fileIn("$UserScripts\\BUMP_Merge_tool.ms")
				)
			) else _Tool

			if _Tool != undefined then (
				_Tool.nodeExplode (getCurrentSelection()) backup:(queryBox "Keep original nodes?" title:"Node Explode tool")
			)
		)
	)