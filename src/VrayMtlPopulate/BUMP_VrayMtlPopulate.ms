/*  Vray Mat Populate v2.4
	AUTHOR: BUMP
	DATE: 17-09-2017
	TESTED ON: 3ds Max 2014+
	----------------------------------------------------------------------------------------------------------
	This scipt replaces Medir Slots with (v-ray) materials. options: random color / gray color / retain existing materials
	----------------------------------------------------------------------------------------------------------
*/
(
	struct matPop
	(
		/*
		* rand: random color true|false
		* id Material editor slot <int>[1-24]
		* prefix: name prefix
		* matClass: material type i.e: vraymtl, CoronaMtl, ...
		*/
		mapped fn assignMat id rand prefix:"VRayMtl_" matClass:vraymtl =
		(
			if matClass != undefined then (
				local mat = matClass ()
				-- Name
				mat.name = prefix + (abs(random 1 100)) as String
				-- Test for unique name
				if not (okMtlForScene mat) then (mat.name += "_1")
				-- Random color
				if rand then (
					local
					R = abs (random 1 254),
					G = abs (random 1 254),
					B = abs (random 1 254) 
					mat.diffuse = color R G B 
				)
				-- assign to material slot
				setMeditMaterial id mat
				-- options
				showTextureMap mat true 
				setMTLMEditFlags mat #{2..4}
				-- return
			)
			true
		),
		fn setSlots rndColor:false chk:true prefix:"VRayMtl_" matClass:vraymtl =
		(
			local matIndx = #{1..24} as Array
			if chk then (
				for i=1 to matIndx.count where ((findItem sceneMaterials meditMaterials[i]) == 0) do (
					assignMat i rndColor prefix:prefix matClass:matClass
				) 
			) else (
				assignMat matIndx rndColor prefix:prefix matClass:matClass
			)
			true
		)
	)
	_t = matPop()
)