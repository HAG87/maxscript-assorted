macroScript BUMP_normalGammaCorrect
	category:   "BUMP tools"
	buttonText: "Normal map gamma correct"
	toolTip:    "Dstlbx - Change the gamma value of normal maps"
(
	-------------------------------------------------CONFIGURATION
	-- RENDERER PRESETS. ADD YOUR OWN FOLOWING THE SAME PATTERN
	/*
	-- EXAMPLE: ADD SUPPORT FOR OTHER RENDERER
	struct _RENDERER_OR MATERIAL_NAME
	(
		-- display name
		mat_name = "Corona physical material",
	
		-- Class of the shader
		mat_filter_class   = "Material_Class",
	
		-- Shader bump/normal property name
		bitmap_filter      = #texmap_Bump_Property,
	
		-- renderer specific bump/normal map class and property for the normal texturemap.
		-- this can be more than one. i.e: look for Arnold implementation
		renderer_normalmap = #(
			#("Shader_Normal_Map", #normal_Map_Property)
		),
	
		-- renderer specific textureMap implementation
		renderer_BitmapTexture   = "Renderer_Bitmap"
		
		-- gamma property. Must be a float value property
		gammaProperty = #gamma
		
		-- color space properties, for OCIO workflow
		colorSpaceProperty = #(#(#colorSpace_1, 2), #(#colorSpace_2, "raw"))		
	)
	-- */
	struct _std
	(
		mat_name           = "Physical material",
		mat_filter_class   = "PhysicalMaterial",
		bitmap_filter      = #bump_map,
		renderer_normalmap = #(
			#("Normal_Bump", #normal_map)
		),
		renderer_BitmapTexture = "bitmap",
		gammaProperty = #gamma,
		colorSpaceProperty = #()
	)
	struct _Arnold
	(
		mat_name           = "Arnold material",
		mat_filter_class   = "ai_standard_surface",
		bitmap_filter      = #normal_shader,
		renderer_normalmap = #(
			#("ai_normal_map", #normal_shader),
			#("ai_bump2d", #normal_shader),
			#("ai_bump3d", #normal_shader)
		),
		renderer_BitmapTexture = "bitmap",
		gammaProperty = #gamma,
		colorSpaceProperty = #()
	)
	struct _Vray
	(
		mat_name           = "Vray material",
		mat_filter_class   = "VRayMtl",
		bitmap_filter      = #texmap_bump,
		renderer_normalmap = #(
			#("VRayNormalMap", #normal_map)
		),
		renderer_BitmapTexture = "VRayBitmap",
		gammaProperty = #gamma,
		colorSpaceProperty = #(#(#rgbColorSpace, 3), #(#color_space,4))
	)
	struct _Corona_legacy
	(
		mat_name           = "Corona legacy material",
		mat_filter_class   = "CoronaLegacyMtl",
		bitmap_filter      = #texmapBump,
		renderer_normalmap = #(
			#("CoronaNormal", #normalMap)
		),
		renderer_BitmapTexture = "CoronaBitmap",
		gammaProperty = #gamma,
		colorSpaceProperty = #(#(#colorSpace, 2))
	)
	struct _Corona_pbr
	(
		mat_name           = "Corona physical material",
		mat_filter_class   = "_CoronaPhysicalMtl",
		bitmap_filter      = #baseBumpTexmap,
		renderer_normalmap = #(
			#("CoronaNormal", #normalMap)
		),
		renderer_BitmapTexture = "CoronaBitmap",
		gammaProperty = #gamma,
		colorSpaceProperty = #(#(#colorSpace, 2))
	)
	-- Add render engines
	fn checkRenderEngines =
	(
		local res = #(_std())
		-----------------------------------------------------------------
		-- ADD MORE:
		-- if classof MATERIAL_CLASS      == material do append res ( _RENDERER_OR MATERIAL_NAME() )
		-----------------------------------------------------------------
		if classof ai_standard_surface == material do join res #( _Arnold() )
		if classof VRayMtl             == material do join res #( _Vray() )
		if classof CoronaMtl           == material do join res #( _Corona_legacy(), _Corona_pbr() )
		res
	)	
	-----------------------------------------------------------------
	-- MAIN CODE -- DO NOT MODIFY!
	-- change bitmap gamma
	fn changeBmpGamma bmpTxt gammavalue:1.0 colorSpace:unsupplied =
	(
		local curr_bitmap = bmpTxt.bitmap
		try (
			local new_bitmap =
				openBitMap curr_bitmap.filename \
					gamma:gammavalue \
					channels:curr_bitmap.channels \
					colorSpace:(if colorSpace != unsupplied OR colorSpace != undefined then colorSpace else unsupplied)
			setproperty bmpTxt #bitmap new_bitmap
		) catch (
			format "Conversion error: %\m" (getCurrentException())
		)
	)
	-- change renderer bitmap implementation
	fn changeRndrBmpGamma bmpTxt gammaProperty:#gamma gammaValue:1.0 colorSpaceProperty:#() changeColorSpace:true =
	(
		--	showProperties bmpTxt
		
		local temp_gamma = gammaValue
		if not (isKindOf gammaValue float) then (
			temp_gamma = if gammaValue == #auto then 1.0 else 2.2
		)		
		-- set the new gamma value
		setProperty bmpTxt gammaProperty temp_gamma
		-- set the color space
		if changeColorSpace then 
		(
			for p in colorSpaceProperty do (
				SetProperty bmpTxt p[1] p[2]
			)
		)
	)
	-- search function.
	-- src parameter is the struct with the render engine parameters
	-- if "mats" is unsupplied it defaults to scene materials
	fn reassignMaps src mats:unsupplied _gamma:1.0 colorSpace:unsupplied =
	(
		-- get the material collection
		local mat_loop = if mats == unsupplied OR mats == undefined then sceneMaterials else mats
		-- failsafe		
		if mat_loop == undeifned then return undefined;

		-- handle Multimaterial and filter collection to valid material class
		local actual_mat_list = #()
		
		for mat in mat_loop do
		(
			-- single materials
			if ((classOf mat) as String == src.mat_filter_class) then
			(
				append actual_mat_list mat
			)
			else if (isKindOf mat Multimaterial) then
			(
			-- Multimaterial
				local multimat_childerns =
					for i in mat where ( (classOf i) as String == src.mat_filter_class ) collect i				
				join actual_mat_list multimat_childerns
			)
		)
		
		-- cleanup
		makeUniqueArray actual_mat_list

		-- change the properties
		for mat in actual_mat_list do (
			format "---------------------------\n"  mat
			format "material: %\n"  mat
			-----------------------------------
			-- check for shader bitmap
			if ( isProperty mat src.bitmap_filter ) then (
				
				local texturenode = getProperty mat src.bitmap_filter				
				-----------------------------------
				format "property: %\n" texturenode
				-----------------------------------				
				-- property must not be undefined
				if texturenode != undefined then
				(
					-- check for Bitmaptexture
					if (ClassOf texturenode == Bitmaptexture) then
					(
						-- CASE_A: standard bitmaptexture
						changeBmpGamma texturenode gammavalue:_gamma colorSpace:colorSpace
					)
					else
					(
						-- CASE_B: renderer-specific normalMap. This generally implements some sort of a direct gamma property
						for i in src.renderer_normalmap where ((ClassOf texturenode) as String == i[1]) do
						(
							-- get the normalMap property
							local thebitmap = getProperty texturenode i[2]
							if thebitmap != undefined then
							(
								-----------------------------------------------------------------
								format "bitmap: % | type: %\n" thebitmap.name (ClassOf thebitmap)
								-----------------------------------------------------------------
								if ClassOf thebitmap == Bitmaptexture then (
									-- CASE_B_1: standard bitmap
									changeBmpGamma thebitmap gammavalue:_gamma colorSpace:colorSpace
									-- DONE
								) else (								
									-- CASE_B_2: render specific bitmap
									if src.renderer_BitmapTexture.count > 1 then
									(
										if (ClassOf thebitmap) as string == src.renderer_BitmapTexture then
										(											
											-- apply
											changeRndrBmpGamma thebitmap \
												gammaProperty:src.gammaProperty \
												gammaValue:_gamma \
												colorSpaceProperty: src.colorSpaceProperty \
												changeColorSpace:true
										)
									)
								)
							)
						)
					)
				)
			)
		)
	)
	-------------------------------------------------UI
	rollout roll_normalGamma "Change Normal Maps gamma" width:300
	(
		Dropdownlist cb_renders "Render engine / shader" labelOnTop:true
		group  "Operate on"
		(
			radiobuttons rd_1 "" labels:#("Scene materials", "Material editor slots", "Selection") offsets:#([0,0],[0,5],[0,10]) align:#left
		)
		GroupBox grp_1 "Gamma mode" height:100 width:145 align:#left offset:[-10,0] across:2
		GroupBox grp_2 "Color space" height:100 width:145 align:#right offset:[10,0]
		radiobuttons rd_modes "" labels:#("Auto", "Default", "Override") offsets:#([0,0],[0,5],[0,10]) align:#left offset:[0,-85] across:2
		checkbox btn_ccspace "Change color space" checked:true triState:1 align:#left offset:[10,-85]
		spinner spn_1 "Value: " type:#float range:[-100.0,100.0,1.0] align:#left offset:[0,0] across:2		
		DropDownlist cb_color "" enabled:false width:130 align:#left offset:[10,-35] \
			tooltip:"This is for standard bitmaps.\nFor render engine specific bitmaps, a default value will be used"		
		checkButton btn_raw "Set to RAW" enabled:false width:130 align:#left offset:[147,-30] \
			tooltip:"This is for standard bitmaps.\nFor render engine specific bitmaps, a default value will be used"
		label lbl_3 "WARNING!!! THIS OPERATION CAN'T BE UNDONE"  offset:[0,10]
		button btn_change "Change values" height:30 width:140
		--------------------
		local MATERIAL_TYPES
		--------------------
		on roll_normalGamma open do
		(
			-- load render engines
			MATERIAL_TYPES = checkRenderEngines()
			-- UI
			cb_renders.items = for i in MATERIAL_TYPES collect i.mat_name
			
			if ColorPipelineMgr != undefined then (
				cb_color.items = ColorPipelineMgr.GetFileIOColorSpaceList()
				cb_color.selection = findItem cb_color.items "Raw"
				cb_color.enabled = true
				btn_raw.enabled = true
			)
			-- tooltip
			btn_change.tooltip =
			"If you know some scripting,\nyou can edit this script to add more render engine options.\nLook for the file: "+(getThisScriptFilename())
		)
		on btn_change pressed do
		(
			-- material collection
			local mats_col =
				case rd_1.state of
				(
					1: unsupplied
					2: meditMaterials
					3: for i in (getCurrentSelection()) where i.material != undefined collect i.material
					defualt: unsupplied
				)
			-- "Auto", "Default", "Override"
			local gamma_value =
				case rd_modes.state of
				(
					1: #auto
					2: #default
					3: spn_1.value
				)
			local color_space =
				if btn_raw.state then "raw" else cb_color.selected			
			-- execute
			if btn_ccspace.state then 
				reassignMaps (MATERIAL_TYPES[cb_renders.selection]) mats:mats_col _gamma:gamma_value colorSpace:color_space
			else
				reassignMaps (MATERIAL_TYPES[cb_renders.selection]) mats:mats_col _gamma:gamma_value colorSpace:undefined			
		)
	)
	-- execute macro	
	on execute do (
		try (DestroyDialog roll_normalGamma) catch ()
		CreateDialog roll_normalGamma
	)
)