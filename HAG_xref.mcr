/*
------------------------------------------------------------------------------------------------------------------
Xref Object Utilities
------------------------------------------------------------------------------------------------------------------
*/
macroScript	HAG_toXref
	category: "HAG tools"
	buttonText: "Replace with Xref"
	toolTip: "Replace selected node with Xref Record"
(
	fn centroid objs =
	(
		local sumpoints = [0.0f,0.0f,0.0f]
		for i in objs do (
			sumpoints += i.pos
		)
		sumpoints /= objs.count
	)
	-----------------------------------------
	fn place objs ref =
	(
		local cent = centroid objs
		for i in objs where (i.parent == undefined) do (
			i.pos = (cent - i.pos) + ref
		)
	)
	-----------------------------------------
	fn setXrefRecord obj filename deleteRef:true = 
	(
		if (not (isValidNode obj)) AND (not (doesFileExist filename)) then return false
		
		local xrefRecord
		local the_nodes = #()
			
		with redraw off (
			-- load XrefObject				
			xrefRecord = objXRefMgr.AddXRefItemsFromFile filename xrefOptions:#(#selectnodes)				
			if xrefRecord  == undefined then return false
			-- check for xref existence ?
			if (xrefRecord.Update()) then (
				format "RECORD LOADED\n"
				-- get items
				xrefRecord.GetItems #XRefObjectType &xrefItems
				if xrefItems  == undefined then return false
				-- get nodes					
				for itm in xrefItems where (isKindOf itm XRefObject) do (
					itm.getNodes &nodelist
					join the_nodes nodelist				
				)
				place the_nodes obj.pos
			)
			-- delete refnode
			if deleteRef then delete obj
		)
		-- update xrefs
		objXRefMgr.UpdateAllRecords()
		true
	)
	-----------------------------------------
	fn XrefReplace =
	(
		local file = getOpenFileName caption:"Xref Object file" types:"Max files (*.max)|*.max" historyCategory:"XREFOPEN"
		local obj = (getCurrentSelection())[1]
		setXrefRecord obj file
	)
	-----------------------------------------
	on execute do XrefReplace()
	-----------------------------------------
)