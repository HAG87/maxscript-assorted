(
	/*
		FILTER SELECTION BY MATERIAL CLASS
		The algortihm will look 1-level deep in MultiMaterials
		1 - Start by selecting the nodes you want to filter
	*/
	clearListener()
	local mtlClass = VRayMtl ---> 2 - THE TYPE OF MATERIAL YOU WANT TO EXCLUDE IN THE SEARCH
	local listOfObjs = #()
	for o in selection where ClassOf o.material != mtlClass do (
		if ClassOf o.material == MultiMaterial then (
			local hasinvalidMtl = false
			for m in o.Material.materialList while ClassOf m != mtlClass do hasinvalidMtl = true
			if hasinvalidMtl then (
				format "% || %\n" o.name o.material
				append listOfObjs o
			)
		) else (
			format "% || %\n" o.name o.material
			append listOfObjs o
		)	
	)
	clearSelection()
	select listOfObjs
)
