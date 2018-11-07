/*
* -----------------------------------------------------------------------------------
* -----------------------------------------------------------------------------------
*/
macroScript HAG_CamMngr
			category:         "HAG tools"
			ButtonText:       "CamMngr"
			silentErrors:     true
			tooltip:"Manage Cameras"
(
	-- 		global roll_cambatch
	
	rollout roll_cambatch "Camera Manager" width:250
	(
		local roll_w = roll_cambatch.width
		--------------------------------
		group "Active Camera"
		(
			label lbl_cam "" align:#left across:2
			button btn_1 "Refresh" align:#right
			button btn_s "Select" width:(roll_w - 25) height:25
		)
		group "Scene cameras"
		(
			listbox lst_1 "" height:5
			button btn_2 "<<" width:60 align:#left across:3
			button btn_3 "Set active" width:60 align:#center
			button btn_4 ">>" width:60 align:#right
		)
		group "Add to Batch"
		(
			radiobuttons rd_1 "" labels:#("Active", "Selected in list") default:1 align:#left
			edittext txt_1 "View name: " fieldWidth:160 bold:true align:#right
			edittext txt_2 "Output: " fieldWidth:160 align:#right
			edittext txt_3 "File name: " fieldWidth:160 align:#right
			button btn_p "Change path" align:#right height:25
			button btn_v "Add View" width:(roll_w - 25) height:25
		)
		--------------------------------
		local active_cam
		local list_cam
		local curr_itm = 1
		local batch_view
		local view_name = ""
		local view_path = undefined
		--------------------------------
		fn selCam n =
		(
			max modify mode
			if isValidNode n then select n
		)
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
		fn change_active =
		(
			active_cam = getActiveCamera()
			lbl_cam.text = if active_cam != undefined then active_cam.name else "None"
		)
		fn setActiveCam n =
		(
			if n != undefined then (
				local cam = getNodeByName n
				if isValidNode cam and (isKindOf cam camera) then viewport.SetCamera cam
				change_active()
			)
		)
		
		fn update_Path cam: =
		(
			if view_path != undefined then (
				txt_2.text = getFilenamePath view_path
				txt_3.text = filenameFromPath view_path
			)
		)
		
		fn view_settings =
		(
			local temp_cam = undefined
			case rd_1.state of (
				-- Active camera
				(1):(temp_cam = active_cam)
				-- Selected in list
				(2):(temp_cam = getNodeByName (lst_1.selected))
			)
			if (temp_cam != undefined) then (
				txt_1.text = temp_cam.name
					
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
		fn view_add =
		(
			local temp_cam = undefined
			case rd_1.state of (
				-- Active camera
				(1):(temp_cam = active_cam)
				-- Selected in list
				(2):(temp_cam = getNodeByName (lst_1.selected))
			)
			
			if temp_cam != undefined then (
				--	format "%\n%\n%\n----\n" temp_cam txt_1.text view_path
				if (batchRenderMgr.FindView txt_1.text) == 0 then (
					local new_view = batchRenderMgr.CreateView temp_cam
					new_view.name = txt_1.text
					new_view.outputFilename = view_path
				) else messageBox "View Already exist.\nChange name and try again."
			)
		)
		--------------------------------
		on roll_cambatch open do
		(
			change_active()
			relist_cams()
			view_settings()
		)
		on btn_1 pressed do  change_active()
		on btn_s pressed do ( selCam active_cam )
		on lst_1 selected item do
		(
			curr_itm = item
			setActiveCam lst_1.selected
			view_settings()
		)
		on btn_2 pressed do
		(
			if curr_itm > 1 then curr_itm -=1
			lst_1.selection = curr_itm
			view_settings()
		)
		on btn_3 pressed do
		(
			setActiveCam lst_1.selected
			view_settings()
		)
		on btn_4 pressed do
		(
			if curr_itm < lst_1.items.count then curr_itm +=1
			lst_1.selection = curr_itm
			view_settings()
		)
		on btn_p pressed do
		(
			view_path = getBitmapSaveFileName()
			update_Path()
		)
		on btn_v pressed do
		(
			view_settings()
			view_add()
		)
		
	)
	on execute do (
		try (DestroyDialog roll_cambatch)catch()
		CreateDialog roll_cambatch 
	)
)