/*  Vray Mat Populate v2.3
	AUTHOR: HAG
	DATE: 19-02-2014
	TESTED ON: 3ds Max 2014+
	----------------------------------------------------------------------------------------------------------
	This scipt replaces Medir Slots with v-ray materials options: random color / gray color / retain existing materials
	----------------------------------------------------------------------------------------------------------
*/
(
	struct vrayPop
	(
		fn assignMat r id =
		(
			local vraymat= vraymtl ()
			local n= ("vrayMtl_"+ (floor(random 1 100) as integer )as String)
			vraymat.name=n
			if r== true then (
				vraymat.diffuse = (color (random 1 254 as integer) (random 1 254 as integer) (random 1 254 as integer))
			)
			--Test for N uniqness
			if okMtlForScene vraymat==false then (vraymat.name+="_1")
			setMeditMaterial id vraymat
			showTextureMap vraymat true 
			setMTLMEditFlags vraymat #{2..4}
		),
		fn setVraySlots rndColor:false chk:true =
		(
			case chk of
			(
				true:
				(	
					for i=1 to meditMaterials.count do (
						if (findItem sceneMaterials meditMaterials[i]) == 0 then ( assignMat rndColor i)
					)
				)
				false:
				(
					for i=1 to meditMaterials.count do ( assignMat rndColor i )
				)
			)
		)
	)
	_t = vrayPop()
)