/*
* -------------------------------------------------------------------------------------------------------
* https://atelierbump.com
* Category: "BUMP tools"
* last updated: 01-05-2023
* MODIFY AT YOUR OWN RISK
* -------------------------------------------------------------------------------------------------------
* BUMP_mapLoader   | Load multiple bitmapTextures to the slate material editor
* BUMP_fnameToBMap | Change the names of Bitmap Textures to the name of the loaded files.
* BUMP_remove_mats | Remove material from selection
* BUMP_selNoMat    | Filter nodes without material in current selection.
* BUMP_ObjIDbyCAM  | Set objects ID for current camera view
* BUMP_faceSel     | Select faces with same material ID
* BUMP_RndIDSet    | Set random material IDs for selected faces
* BUMP_qIDSet      | Set material IDs for selected faces
* BUMP_listMtl     | List materials in selection
* BUMP_selByMat    | Select objects with the same material as the current selection
*/
/* Change mtl bump value */
macroScript DSTLBX_bumpToOneHundred
	category:   "BUMP tools"
	ButtonText: "bumpTo100"
	toolTip:    "Material Bump value to 100"
(
	on execute do (
		local warning = messageBox "Warning! this will change the bump amount value of scene materials. Works only with Vray materials for now"
		if warning AND VRayMtl != undefined then (
			-- for Vray materials only!
			-- TODO: Implement physical, standard, Arnold, Corona...
			local mats = getClassInstances VRayMtl
			mats = makeUniqueArray mats
			for m in mats where classOf (m.texmap_bump) == VRayNormalMap do m.texmap_bump_multiplier = 100.0
		)
	)
)
/* Load texture maps */
macroScript BUMP_mapLoader
	category:   "BUMP tools"
	ButtonText: "Bitmap multi-loader"
	toolTip:    "Load multiple bitmapTextures to the slate material editor"
(
	-- open files dialog
	fn GetMultiOpenFilenames caption:"Open" filename:"" types:"image Files (*.*)|*.*" default:1 =
	(
		local dlg = DotNetObject "System.Windows.Forms.OpenFileDialog"
		dlg.multiSelect = true
		dlg.title       = caption
		local p = getFilenamePath filename
		if doesFileExist p then dlg.initialDirectory = p
		dlg.filter      = types
		dlg.filterIndex = default
		local result = dlg.ShowDialog()
		if (result.Equals result.OK) then dlg.filenames else undefined
	)
	-- load TextureMaps
	fn loadTextureMaps files _gamma _basename =
	(
		for i=1 to files.count do (

			local _path = files[i]
			local tx = openBitMap _path gamma:_gamma

			if tx != undefined then (
				local map  = Bitmaptexture()
				map.bitmap = tx
				map.name   = _basename + (try (getFilenameFile _path ) catch ( uniqueName (getFilenameFile _path) ))

				local smeView = sme.GetView(SME.activeView)
				smeView.CreateNode map (smeView.position + [0, 0 + (40 * i - 1)])
			)
		)
	)
	rollout roll_loadbitmaps "Load bitmaps"
	(
		Group "Gamma"
		(
			radiobuttons rd_1 labels:#("Auto", "Override")
			spinner spn_1 "Gamma value:" range:[1.0, 100.0, 1.0] units:#float
		)
		edittext txt_1 "Name Prefix:" text:"Map_" labelOnTop:true
		button btn_1 "Load Maps" width:150 height:30 offset:[0,5]

		local
		_gamma, _basename

		on roll_loadbitmaps open do
		(
			_gamma = #Auto
			_basename = "Map_"
		)
		on roll_loadbitmaps close do updateToolbarButtons()

		on rd_1 changed index do
		(
			case index of
			(
				1: (_gamma = #Auto)
				2: ( _gamma = spn_1.value)
			)
		)
		on spn_1 changed val do
		(
			if _gamma != #Auto then (
				_gamma = val
			)
		)
		on btn_1 pressed do
		(
			local paths
			if (paths = GetMultiOpenFilenames()) != undefined then
			(
				print paths
				loadTextureMaps paths _gamma _basename
			)
		)
	)
	on isChecked do roll_loadbitmaps.open
	on execute do CreateDialog roll_loadbitmaps style:#(#style_toolwindow,#style_sysmenu)
	on CloseDialogs do DestroyDialog roll_loadbitmaps
)
/* Map - Material related tools */
macroScript BUMP_fnameToBMap
	category:   "BUMP tools"
	buttonText: "Map name from file"
	toolTip:    "Change the names of Bitmap Textures to the name of the loaded files."
(
	local msg = "This will rename all Bitmap maps to the filename of the source. Are you sure to continue?"

	fn renameTxtMapFromFileName =
	(
		undo "Map name from file" on (
			for i in (getClassInstances BitmapTexture) do (
				i.name = (getFilenameFile i.filename + getFilenameType  i.filename)
			)
		)
	)
	on execute do
	(
		if queryBox msg then renameTxtMapFromFileName()
	)
)
/* Remove material from selection */
macroScript BUMP_remove_mats
	category:   "BUMP tools"
	buttonText: "Remove materials"
	toolTip:    "Remove material from selection"
(
	on execute do
	(
		local msg = "This will remove the materials assigned to the node selection. Are you sure to continue?"
		if queryBox msg then (
			undo "Remove materials" on (
				for i in selection where (isValidNode i) do i.material = undefined
				CompleteRedraw()
			)
		)
	)
)
/* Filter nodes without material in current selection. */
macroScript BUMP_selNoMat
	category:   "BUMP tools"
	buttonText: "Select nodes without material"
	toolTip:    "Filter nodes without material in current selection."
(
	fn SelectNoMaterial =
	(
		max create mode
		with redraw off
		(
			local objs = getCurrentSelection()
			ClearSelection()
			for i in objs where (i.material == undefined) do selectMore i
		)
	)
	on execute do SelectNoMaterial()
)
-- Poly - Node Id related tools
macroScript BUMP_ObjIDbyCAM
	category:   "BUMP tools"
	buttonText: "ID from camera"
	toolTip:    "Set objects ID for current camera view"
 	icon:      #("Material_Modifiers",2)
(
	fn setObjID =
	(
		local cam = getActiveCamera()
		if cam != undefined then (
			local bbx = box2 [0,0] [gw.getWinSizeX(),gw.getWinSizeY()]
			local objsel = boxPickNode bbx
			local campos = cam.pos
			fn compareFN v1 v2 ref: =
			(
				local a = distance ref v1.pos
				local b = distance ref v2.pos
				local d = a - b
				case of
				(
					(d < 0.): -1
					(d > 0.): 1
					default: 0
				)
			)
			qsort objsel compareFN ref:campos
			for i=1 to objsel.count do (
				objsel[i].gbufferChannel = i
			)

		)
	)
	on execute do setObjID()
)
/* Select faces with same material ID */
macroScript BUMP_faceSel
	category:   "BUMP tools"
	buttonText: "Face ID"
	toolTip:    "Select faces with same material ID"
	icon:       #("UVWUnwrapSelection",12)
(
	fn EPOLY_selectMatID obj =
	(
		if obj != undefined then (
			if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4)) then (

				local faceCount   = polyop.getNumFaces obj
				local currFace    = polyop.getFaceSelection obj
				local currFaceArr = currFace as Array

				if currFaceArr[1] != undefined then (
					local faceID = polyop.getFaceMatID obj currFaceArr[1]
					local tempFaces = for i=1 to faceCount where (polyop.getFaceMatID obj i == faceID) collect i
					polyop.setFaceSelection obj tempFaces
					redrawViews()
				)
			)
		)
	)
	On IsEnabled do Filters.Is_EditPoly()
	--	On IsVisible do Filters.Is_EditPoly()
	on execute do
	(
		local theObj = if selection[1] != undefined then selection[1] else undefined
		EPOLY_selectMatID theObj
	)
)
/* Set random material IDs for selected faces */
macroScript BUMP_RndIDSet
	category:     "BUMP tools"
	ButtonText:   "Random ID Set"
	tooltip:      "Set random material IDs for selected faces"
	silentErrors: true
(
	fn randMatID obj min:1 max:5 =
	(
		if obj !=undefined then (
			if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4)) then (
				local faceCount = polyop.getNumFaces obj
				local currFace = polyop.getFaceSelection obj
				local currFaceArr = currFace as Array
				if currFaceArr[1] != undefined then (
					for i in currFaceArr do polyop.setFaceMatID obj i (abs (floor (random min max)))
					redrawViews()
				)
			)
		)
	)
	on execute do try (randMatID $) catch ()
)
/* Set material IDs for selected faces */
macroScript BUMP_qIDSet
	category:     "BUMP tools"
	ButtonText:   "Quick material ID Set"
	tooltip:      "Set material IDs for selected faces"
	silentErrors: true
(
	local roll_qID
	rollout roll_qID "Quick polygon ID set" width:200 --*height:300
	(
		-- label lblCurr "Current ID: " align:#left height:25 across:2
		-- label lblCurrID "10" align:#right height:25 offset:[-10,0]
		checkbutton utl1 "Set / Select" height:25 align:#left across:2
		label lbl1 "SET MODE" offset:[0,5]-- align:#right
		button btn1 "1" width:32 height:32 across:5
		button btn2 "2" width:32 height:32
		button btn3 "3" width:32 height:32
		button btn4 "4" width:32 height:32
		button btn5 "5" width:32 height:32
		button btn6 "6" width:32 height:32 across:5
		button btn7 "7" width:32 height:32
		button btn8 "8" width:32 height:32
		button btn9 "9" width:32 height:32
		button btn10 "10" width:32 height:32
		button btn11 "Sel. Selected face ID" width:170 height:32 align:#left offset:[0,5] enabled:false

		-- local str1 = "Sel. Selected face ID"
		
		mapped fn polyID obj id:1 =
		(
			if obj != undefined then (
				if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4 OR subObjectLevel == 5)) then (
					local faceCount = polyop.getNumFaces obj
					local currFace= polyop.getFaceSelection obj
					local currFaceArr = currFace as Array
					if currFaceArr[1] != undefined then (
						with redraw off for i in currFaceArr do polyop.setFaceMatID obj i id
						redrawViews()
					)
				)
			)
		)
		mapped fn selectMatID obj id:1 =
		(
			if obj != undefined then (
				if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4 OR subObjectLevel == 5)) then (
					local faceCount   = polyop.getNumFaces obj
					local currFace    = polyop.getFaceSelection obj
					-- accelerator
					local _getID = polyop.getFaceMatID
					local tempFaces = for i=1 to faceCount where (_getID obj i == id) collect i
					polyop.setFaceSelection obj tempFaces
					redrawViews()
				)
			)
		)
		
		fn currFaceMatID obj &faceID =
		(
			if obj != undefined then (
				if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4)) then (
					local faceCount   = polyop.getNumFaces obj
					local currFace    = polyop.getFaceSelection obj
					local currFaceArr = currFace as Array

					if currFaceArr[1] != undefined then (
						faceID = polyop.getFaceMatID obj currFaceArr[1]
						local tempFaces = for i=1 to faceCount where (polyop.getFaceMatID obj i == faceID) collect i
						polyop.setFaceSelection obj tempFaces
						redrawViews()
					)
				)
			)
		)
		
		on utl1 changed state do (
			if state then (
				lbl1.text = "SELECT MODE"
				btn11.enabled = true
			) else (
				lbl1.text = "SET MODE"
				btn11.enabled = false
			)				
			-- lbl1.text = if state then "SELECT MODE" else "SET MODE"
		)
		on btn1 pressed do if utl1.checked then selectMatID $ id:1 else polyID $ id:1
		on btn2 pressed do if utl1.checked then selectMatID $ id:2 else polyID $ id:2
		on btn3 pressed do if utl1.checked then selectMatID $ id:3 else polyID $ id:3
		on btn4 pressed do if utl1.checked then selectMatID $ id:4 else polyID $ id:4
		on btn5 pressed do if utl1.checked then selectMatID $ id:5 else polyID $ id:5
		on btn6 pressed do if utl1.checked then selectMatID $ id:6 else polyID $ id:6
		on btn7 pressed do if utl1.checked then selectMatID $ id:7 else polyID $ id:7
		on btn8 pressed do if utl1.checked then selectMatID $ id:8 else polyID $ id:8
		on btn9 pressed do if utl1.checked then selectMatID $ id:9 else polyID $ id:9
		on btn10 pressed do if utl1.checked then selectMatID $ id:10 else polyID $ id:10
		on btn11 pressed do currFaceMatID $ &faceID
	)

	on isChecked do if roll_qID != undefined then roll_qID.open else false
	on execute do (
		try (
			if not roll_qID.open then CreateDialog roll_qID
		) catch (
			DestroyDialog roll_qID
			CreateDialog roll_qID
		)
	)
)
/* Select by material */
macroScript BUMP_selByMat
	category:     "BUMP tools"
	ButtonText:   "Select by Material"
	tooltip:      "Select objects with the same material as the current selection."
	silentErrors: true
(
	on execute do
	(
		-- current selection material
		local mats = for i in (getCurrentSelection()) where i.material != undefined collect i.material
		-- unique array of materials
		makeuniquearray mats
		-- look for objects with the same material
		local sim = for i in objects where findItem mats i.material collect i
		-- select the resul
		if sim.count > 0 then select sim
	)
)
/* List materials in selection */
macroScript BUMP_listMtl
	category:     "BUMP tools"
	ButtonText:   "List Materials"
	tooltip:      "List materials of selected nodes"
	silentErrors: true
(
	fn listMats sel =
	(
		local mats = #()
		local undef = #()
		for i in sel do
		(
			if i.material != undefined then (
				appendIfUnique mats i.material
			) else (
				-- print (classof i)
				append undef i
			)
		)
		for m in mats do format "% :: %\n" m.name (classof m)
		if undef.count > 0 then (
			format "Undefined Materials at:\n"
			for u in undef do format "% :: %\n" u.name (classof u)
			select undef
		)
		OK
	)

	on execute do
	(
		listMats $
	)
)
/*
-- Max UI related tools
macroScript TrackbarToggle
	category:   "BUMP tools"
	buttonText: "Toggle Trackbar"
	toolTip:    "Toggle Timeslider and Trackbar"
	Icon:       #("TrackViewStatus",11)
	(
		on isChecked do	not (timeslider.isVisible())
		on execute do
		(
			timeslider.setvisible (not timeslider.isVisible())
		)
	)
	*/