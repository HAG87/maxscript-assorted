plugin simpleObject HexagonGrid
	name:"HexagonGrid"
	classID:#(0xc378ffe, 0x182ca757)
	category:"Examples"
(
	local vertList = #()
	local faceList = #()

	fn getNearestLowerMultiple nr mult =
		mult * int (nr / mult)

	fn getLuminance clr =
		(clr.r * 0.3 + clr.g * 0.59 + clr.b * 0.11) / 255

	fn getCirclePoints pos count radius axis1 axis2 rot:15.0 =
	(
		local step = 360 / count

		for angle = 0 to 360 - step by step collect
			pos + axis1 * radius * cos (angle+rot) + axis2 * radius * sin (angle+rot)
	)

	fn buildNGonCap tm sideCount radius _rot &vertCount = 
	(
		join vertList (getCirclePoints tm.pos sideCount radius tm.row1 tm.row2 rot:_rot)
		local Flist = for vert = vertCount+1 to (vertCount + sideCount ) collect vert
		append faceList Flist
	--	for vert = vertCount + 2 to vertCount + sideCount - 1 do 
	--	append faceList [vertCount + 1, vert, vert + 1]
		vertCount += sideCount
	)

	parameters main rollout:params
	(
		map ui:mbBitmap type:#textureMap subAnim:true
		width ui:spnWidth default:50 type:#worldUnits animatable:true
		radius ui:spnRadius default:5 type:#worldUnits animatable:true
		length ui:spnLength default:50 type:#worldUnits animatable:true
		Nsides type:#integer default:6 animatable:true
		sides ui:spnSides default:6 type:#integer animatable:true
		angRot ui:spnRot default:0.0 type:#float animatable:true
		irr_mode type:#boolean default:false animatable:false
		_off ui:spnOff type:#worldUnits default:0.0 animatable:true
	)

	rollout params "Parameters"
	(
		group "Map:"
		(
	--	label lblBitmap "Map:" align:#left offset:[0, 4]
		mapButton mbBitmap "NONE" toolTip:"TextureMap" width:120 align:#center
		button btnPutToMEdit "Put to MEdit Slot #1" width:120 align:#center
		)
		group ""
		(
		radiobuttons rdMode labels:#("Regular","Irregular") default:1
		dropdownlist drpSides items:#("triangle","square","hexagon") selection:3
		spinner spnSides "Ngon Sides" range:[3, 150, 6] type:#integer enabled:false
		)
		group ""
		(
		spinner spnWidth "Width:  " range:[0, 1e9, 5] type:#worldUnits
		spinner spnLength "Length: " range:[0, 1e9, 5] type:#worldUnits
		spinner spnRadius "Radius: " range:[0, 1e9, 5] type:#worldUnits
		)
		group ""
		(
		spinner spnRot "Rotate" range:[-360.0,360.0,0.0] type:#float
		spinner spnOff "Gap Offser" range:[-1000000.0,1000000.0,0.0] type:#worldunits	
		)
		
		on btnPutToMEdit pressed do try(meditMaterials[1] = this.map)catch()
		on drpSides selected itm do ( 
			Nsides = case itm of (
									1: 3
									2: 4
									3: 6
									default: 6 
								)
			)
		on rdMode changed state do (
			case state of (
				1: (irr_mode = false; spnSides.enabled = false)
				2: (irr_mode = true; spnSides.enabled = true)
			)
		)
	)

	on buildMesh do
	(
		vertList.count = 0
		faceList.count = 0
		local vertCount = 0
		/*
		local horizontalOffset = if Nsides != 4 then radius * 1.5 else radius
		local verticalOffset = if Nsides != 4 then -radius * sin (360/Nsides) else -radius
	--	*/
	--	/*
		local horizontalOffset, verticalOffset
		if not irr_mode then (
			horizontalOffset = if Nsides != 4 then radius * (1.5 + _off) else ( radius * (1.0 + _off))
			verticalOffset = if Nsides != 4 then -radius * (sin (360/Nsides) + _off) else ( -radius * (1.0 + _off))
		)else (
			horizontalOffset = radius * (2.0 + _off)
			verticalOffset = -radius * (2.0 + _off)
		)
	--	*/
		local horizontalSampleCount = amax 1 (int((width - horizontalOffset) / horizontalOffset))
	--	local horizontalSampleCount = amax 1 (int((width - horizontalOffset / 3) / horizontalOffset))
		local verticalSampleCount = amax 1 (int((length + verticalOffset) / -verticalOffset))

		local bmp = bitmap horizontalSampleCount verticalSampleCount color:white
		if this.map != undefined do renderMap this.map into:bmp

		for v = 0 to verticalSampleCount - 1 do
		(
			local row = getPixels bmp [0, v] horizontalSampleCount
			for h = (1 + mod v 2) to row.count by 2 where row[h].v > 0 do
				buildNGonCap (transMatrix [h * horizontalOffset - width / 2, v * verticalOffset + length / 2, 0]) (if irr_mode then sides else Nsides) (radius * getLuminance row[h]) angRot &vertCount				
		)
	--	*/
		setMesh mesh vertices:vertList faces:#()
		for f=1 to (faceList.count) where (faceList.count) >=1 do (
			meshop.createPolygon mesh faceList[f]
		)
	--	/*	
		/*
		setMesh mesh vertices:vertList faces:faceList
		for f = 0 to faceList.count - 1 by 4 do
			for i = 1 to 6 do setEdgeVis mesh (f + i/2 + 1) (1 + 2 * mod i 2) false
	--	*/
		free bmp
	)

	tool create
	(
		on mousePoint click do case click of
		(
			1: nodeTM.translation = gridPoint
			2: #stop
		)
		on mouseMove click do if click > 1 do
		(
			/*
				width = getNearestLowerMultiple (2 * abs gridDist.x) (if Nsides != 4 then radius * 1.5 else radius)
				length = getNearestLowerMultiple (2 * abs gridDist.y) (if Nsides != 4 then -radius * sin (360/Nsides) else -radius)
		--	*/
		--	/*
			if not irr_mode then (
				width = getNearestLowerMultiple (2 * abs gridDist.x) (if Nsides != 4 then radius * 1.5 else radius)
				length = getNearestLowerMultiple (2 * abs gridDist.y) (if Nsides != 4 then -radius * sin (360/Nsides) else -radius)
			) else (
				width = getNearestLowerMultiple (2 * abs gridDist.x) (radius)
				length = getNearestLowerMultiple (2 * abs gridDist.y) (-radius)
			)
		--	*/
		)
	)
)
