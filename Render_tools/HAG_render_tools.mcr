/*
* -----------------------------------------------------------------------------------
* -----------------------------------------------------------------------------------
*/
macroScript HAG_CamMngr
			category:         "HAG tools"
			ButtonText:       "CamMngr"
			silentErrors:     false
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
		)
		group "Output size"
		(
			spinner spn_1 "Width" type:#integer range:[1,1000000,100]
			spinner spn_2 "Height" type:#integer range:[1,1000000,100]
			spinner spn_3 "Ratio" type:#float range:[0.0,6.0,1.33]
			button p1 "0.63" across:6
			button p2 "0.75"
			button p3 "1.00"
			button p4 "1.33"
			button p5 "1.60"
			button p6 "2.00"
			checkbutton chk_1 "Override resolution in view" align:#right
		)		
		button btn_v "Add View to batch" width:(roll_w - 70) height:25 across:2 align:#left
		button btn_b "OPEN" align:#right height:25
		listbox lst_2 "Batch Views" height:10
		
		--------------------------------
		local active_cam
		local list_cam
		local curr_itm = 1
		local batch_view
		local view_name = ""
		local view_path = undefined
		--------------------------------
		fn get_output_values =
		(
			spn_1.value = renderWidth
			spn_2.value = renderHeight
			spn_3.value = rendImageAspectRatio
		)
		fn set_output_res val =
		(
			rendImageAspectRatio = val			
			if renderSceneDialog.isOpen() then renderSceneDialog.update()
			spn_1.value = renderWidth
			spn_2.value = renderHeight
		)
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
			RedrawViews()
		)
		fn setActiveCam n =
		(
			if n != undefined then (
				local cam = if (isKindOf n string) then ( getNodeByName n) else n					
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
		fn get_view_params index =
		(
			local the_view = try (batchRenderMgr.GetView index) catch undefined
			if the_view != undefined then (
				local cam = the_view.camera
				if isValidNode cam then (
					setActiveCam cam
					view_settings()
				)
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
		on btn_1 pressed do  (
			change_active()
			relist_cams()
			--	view_settings()

		)
		on spn_3 changed val do ( set_output_res val )		
		
		on p1 pressed do (
			spn_3.value = execute p1.text
			set_output_res (spn_3.value)
		)
		on p2 pressed do (
			spn_3.value = execute p2.text
			set_output_res (spn_3.value)
		)
		on p3 pressed do (
			spn_3.value = execute p3.text
			set_output_res (spn_3.value)
		)
		on p4 pressed do (
			spn_3.value = execute p4.text
			set_output_res (spn_3.value)
		)
		on p5 pressed do (
			spn_3.value = execute p5.text
			set_output_res (spn_3.value)
		)
		on p6 pressed do (
			spn_3.value = execute p6.text
			set_output_res (spn_3.value)
		)
		
		on btn_b pressed do (actionMan.executeAction -43434444 "4096")

		on btn_s pressed do ( selCam active_cam )
		
		on lst_1 selected item do
		(
			curr_itm = item
			setActiveCam lst_1.selected
			view_settings()
		)
		
		on lst_2 selected item do (
			get_view_params item
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