/*
* -----------------------------------------------------------------------------------
Camera manager utility
rev 1.5 03/06/2019
* -----------------------------------------------------------------------------------
*/
macroScript HAG_CamMngr
		category:     "HAG tools"
		ButtonText:   "Camera manager"
		tooltip:      "Manage Cameras and render batch views"
		silentErrors: false
		icon:         #("extratools", 1)
(
	-- 	global roll_cambatch
	rollout roll_cambatch "Camera Manager" width:250
	(
		local roll_w = roll_cambatch.width
		--------------------------------
		group "Active Camera"
		(
			label lbl_cam "" align:#left height:25 offset:[0,5]
		)
		group "Scene cameras"
		(
			listbox lst_1 "" height:8
			button btn_2 "<<" width:60 align:#left across:3
			button btn_s "Select" width:80 align:#center
			button btn_4 ">>" width:60 align:#right
		)
		button btn_1 "Refresh" height:25 width:(roll_w - 25)

		group "Output size"
		(
			spinner spn_1 "Width" type:#integer range:[1,1000000,100] fieldwidth:65 align:#right across:2
			spinner spn_3 "Ratio" type:#float range:[0.0,6.0,1.33] fieldwidth:65 align:#right
			spinner spn_2 "Height" type:#integer range:[1,1000000,100] fieldwidth:65 align:#right across:2
			checkButton chk_ratio "LOCK" height:18 width:75 align:#right
			label lbl_presets "Presets" align:#left
			button p1 "0.63" across:6
			button p2 "0.75"
			button p3 "1.00"
			button p4 "1.33"
			button p5 "1.60"
			button p6 "2.00"
		)

		group "Batch views"
		(
			listbox lst_2 "Batch Views" height:5
			/* radiobuttons rd_1 "" labels:#("Active", "Selected in list") default:1 align:#left */
			edittext txt_1 "View name" fieldWidth:(roll_w - 25) bold:true labelOnTop:true
			edittext txt_3 "File name" fieldWidth:(roll_w - 25) labelOnTop:true
			edittext txt_2 "Output" fieldWidth:(roll_w - 60) labelOnTop:true across:2
			button btn_p "..." align:#right offset:[0,15] tooltip:"Change path"
			checkbox chk_1 "Override resolution in view" align:#left \
			tooltip:"Set active render output size as view override"
			button btn_v "Add View to batch" width:(roll_w - 70) height:25 align:#left
		)

		button btn_bup "Refresh" width:(roll_w - 70) height:25 align:#left
		button btn_b "Open Batch window" width:(roll_w - 70) height:25 align:#left
		--------------------------------
		local active_cam
		local list_cam
		local curr_itm = 1
		local batch_view
		local view_name = ""
		local view_path = undefined
		--------------------------------
		/* GET RENDER RES VALUES */
		fn get_output_values =
		(
			spn_1.value = renderWidth
			spn_2.value = renderHeight
			spn_3.value = rendImageAspectRatio
		)
		/* CHANGE RENDER OUTPUT */
		fn set_output_res_ratio val =
		(
			rendImageAspectRatio = val

			spn_1.value = renderWidth
			spn_2.value = renderHeight

			if renderSceneDialog.isOpen() then renderSceneDialog.update()
		)
		fn set_output_res w h =
		(
			if w != undefined then renderWidth = w
			if h != undefined then renderHeight = h
			spn_3.value = rendImageAspectRatio
			if renderSceneDialog.isOpen() then renderSceneDialog.update()
		)
		/* SELECT ACTIVE CAMERA */
		fn selCam n =
		(
			max modify mode
			if isValidNode n then select n
		)
		/* LIST CAMERAS IN SCENE */
		fn listCameras =
		(
			for i=1 to cameras.count collect (
				local cam = cameras[i]
				#(cam, cam.name)
			)
		)
		fn relist_cams =
		(
			list_cam = listCameras()
			local only_names = for i in list_cam where (isKindOf i[1] camera) collect i[2]
			local only_cams = for i in list_cam where (isKindOf i[1] camera) collect i[1]
			lst_1.items = only_names
		)
		/* GET THE ACTIVE CAMERA */
		fn change_active =
		(
			active_cam = getActiveCamera()
			lbl_cam.text = if active_cam != undefined then active_cam.name else "None"
			RedrawViews()
		)
		/* SET ACTIVE CAMERA IN VIEWPORT */
		fn setActiveCam n =
		(
			if n != undefined then (
				local cam = if (isKindOf n string) then ( getNodeByName n) else n
				if isValidNode cam and (isKindOf cam camera) then viewport.SetCamera cam
				change_active()
			)
		)
		/* UPDATE BITMAP FILENAME */
		fn update_Path cam: =
		(
			if view_path != undefined then (
				txt_2.text = getFilenamePath view_path
				txt_3.text = filenameFromPath view_path
			)
		)
		fn findItemInList item lst =
		(
			local idx = FindItem lst.Items item
			if idx != 0 then lst.selection = idx
		)
		/* LOAD VIEW PROPS */
		fn view_settings =
		(
			/*
			local temp_cam = undefined
			case rd_1.state of (
				-- Active camera
				(1):(temp_cam = active_cam)
				-- Selected in list
				(2):(temp_cam = getNodeByName (lst_1.selected))
			)
			*/
			local temp_cam = active_cam
			if (temp_cam != undefined) then (
				txt_1.text = temp_cam.name + "-" + (rendImageAspectRatio as string)

				if (view_path != undefined) then (

					local root = getFilenamePath view_path
					local type = getFilenameType view_path
					local filename = filenameFromPath view_path

					local comp_filename = temp_cam.name + type

					for i in list_cam do (
						local n = i[2]
						local f = matchPattern filename pattern:("*"+n+"*")
						if f then (
							local filename_parse = findString filename n
							comp_filename = replace filename filename_parse (n.count) temp_cam.name
							exit
						)
					)
					-- compose Path
					view_path = pathConfig.appendPath root comp_filename
					update_Path()
				)
			)
		)
		/* LIST BATCH VIEWS */
		fn list_views =
		(
			local gv = batchRenderMgr.GetView
			local num = batchRenderMgr.numViews
			local col = for i=1 to num collect (
				local the_view = gv i
				local st = if the_view.enabled then "[x] " else "[o] "
				st+the_view.name
			)
			lst_2.items = col
		)
		/* ADD VIEW */
		fn view_add =
		(
			/*
			local temp_cam = undefined
			case rd_1.state of (
				-- Active camera
				(1):(temp_cam = active_cam)
				-- Selected in list
				(2):(temp_cam = getNodeByName (lst_1.selected))
			)
			*/
			local temp_cam = active_cam
			if temp_cam != undefined then (
				if (batchRenderMgr.FindView txt_1.text) == 0 then (
					local new_view = batchRenderMgr.CreateView temp_cam
					if (new_view.overridePreset = chk_1.state) then (
						new_view.width = renderWidth
						new_view.height = renderHeight
					)
					new_view.name = txt_1.text
					new_view.outputFilename = view_path

					list_views()

				) else messageBox "View Already exist.\nChange name and try again."
			)
		)
		/* LOAD VIEW PROPS */
		fn get_view_params index =
		(
			local the_view = try (batchRenderMgr.GetView index) catch undefined
			if the_view != undefined then (
				local cam = the_view.camera
				if isValidNode cam then (
					setActiveCam cam
					-- SET CAM IN LIST
					findItemInList cam.name lst_1
					view_settings()
				)
				-- SET RENDER OUTPUT TO THE VIEW OVERRIDE, USEFUL TO SEE THE CROP FRAME ETC...
				if the_view.overridePreset then (
					renderWidth = the_view.width
					renderHeight = the_view.height
					get_output_values()
				)
				CompleteRedraw()
			)
		)
		--------------------------------
		on roll_cambatch open do
		(
			change_active()
			relist_cams()
			view_settings()
			------------------------------------
			get_output_values()
			list_views()
		)
		/* SELECT CAMERA */
		on btn_s pressed do ( selCam active_cam )
		/* PREVIOUS CAMERA */
		on btn_2 pressed do
		(
			if curr_itm > 1 then curr_itm -=1
			lst_1.selection = curr_itm
			setActiveCam lst_1.selected
			view_settings()
		)
		/* NEXT CAMERA */
		on btn_4 pressed do
		(
			if curr_itm < lst_1.items.count then curr_itm +=1
			lst_1.selection = curr_itm
			setActiveCam lst_1.selected
			view_settings()
		)
		/* CHANGE ACTIVE CAMERA */
		on lst_1 selected item do
		(
			curr_itm = item
			setActiveCam lst_1.selected
			view_settings()
		)
		/* REFRESH CAM LIST */
		on btn_1 pressed do  (
			change_active()
			relist_cams()
		)
		/* CHANGE RENDER OUTPUT */
		on spn_1 changed val do (
			if chk_ratio.checked then spn_2.value = floor(val/spn_3.value)
			set_output_res val undefined
		)
		on spn_2 changed val do (
			set_output_res undefined val
			if chk_ratio.checked then  spn_1.value = floor(val*spn_3.value)
		)
		on spn_3 changed val do (
			set_output_res_ratio val
		)
		/* IMAGE RATIO PRESETS */
		on p1 pressed do (
			spn_3.value = execute p1.text
			set_output_res_ratio (spn_3.value)
		)
		on p2 pressed do (
			spn_3.value = execute p2.text
			set_output_res_ratio (spn_3.value)
		)
		on p3 pressed do (
			spn_3.value = execute p3.text
			set_output_res_ratio (spn_3.value)
		)
		on p4 pressed do (
			spn_3.value = execute p4.text
			set_output_res_ratio (spn_3.value)
		)
		on p5 pressed do (
			spn_3.value = execute p5.text
			set_output_res_ratio (spn_3.value)
		)
		on p6 pressed do (
			spn_3.value = execute p6.text
			set_output_res_ratio (spn_3.value)
		)
		/* GET BATCH VIEW PARAMS */
		on lst_2 selected item do (
			get_view_params item
		)
		/* SET VIEW OUTPUT */
		on btn_p pressed do
		(
			view_path = getBitmapSaveFileName()
			update_Path()
		)
		/* UPDATE BATCH VIEWS LIST */
		on btn_bup pressed do (
			list_views()
		)
		/* OPEN RENDER BATCH */
		on btn_b pressed do (actionMan.executeAction -43434444 "4096")
		/* ADD VIEW */
		on btn_v pressed do
		(
			view_settings()
			view_add()
		)
	)
	-----------------------------------------------------------------------------------------------------------------------------------------
	on execute do (
		try (DestroyDialog roll_cambatch)catch()
		CreateDialog roll_cambatch 250 -1 100 200
	)
)