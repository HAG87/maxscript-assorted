/*
* -------------------------------------------------------------------------------------------
* Camera Manager - FREE VERSION. COMPLETE VERSION IS PART OF DESIGTOOLBOX
* htpps://atelierbump.com
* Bump 2019-2022
* rev 1.5 03/06/2019
* 02-2021
* 01-2022
* Added Shutter parameters, reordered parameters, changed presets to common aspect ratios
* -------------------------------------------------------------------------------------------
*/
macroScript BUMP_CamMngr
	category:     "BUMP tools"
	ButtonText:   "Camera manager"
	tooltip:      "Manage Cameras and render batch views"
	silentErrors: false
	icon:         #("extratools", 1)
(
	struct camManagerTool
	(
		CamFloater,		
		dialog_width = 250,
		Active_preview = false,
		roll_Cams,
		roll_Batch,
		roll_active,
		private
		/* CAMS ROLLOUT */
		fn ui_cams =
		(
			rollout roll_Cams "Camera Manager"
			(
				local roll_w = 250 --roll_Cams.width
				local owner = if owner != undefined then owner
				--------------------------------
				group "Active Camera"
				(
					label lbl_cam "" align:#left height:25 offset:[0,5]
				)
				
				group "Scene cameras"
				(
					listbox lst_cams "" height:8
					button btn_prev_cam "<<" width:60 align:#left across:3
						tooltip:"Previous camera"
					button btn_s "Select" width:80 align:#center
						tooltip:"Select active camera"
					button btn_next_cam ">>" width:60 align:#right
						tooltip: "Nex camera"
				)
				
				button btn_1 "Refresh" height:25 width:(roll_w - 25)
					tooltip:"Update scene cameras list"
				
				group "Parameters"
				(
					--LENS
					label lbl_fl "Focal length" align:#left across:2
					spinner spn_fl "mm" fieldWidth:70 align:#right
					checkbox chk_fov "Use FOV" align:#left across:2
					spinner spn_fov "FOV" fieldWidth:70 align:#right
					-- APERTURE
					checkbox chk_dof "Enable DOF" across:2
					spinner spn_f "f-" align:#right fieldWidth:70 align:#right
					checkbox chk_tilt "Perspective: Auto Vertical Tilt"
					-- EV
					label lbl_ex "Exposure:" align:#left				
					radiobuttons rd_ex labels:#("Manual", "Target") align:#left  offsets:#([0,0], [80,0])
					-- SHUTTER
					dropdownList drp_ev "Shutter" items:#("1 / seconds", "seconds", "degrees", "frames") width:112 align:#left across:2
					-- EV
					spinner spn_ev "EV" range:[0,1.0E6,6] fieldWidth:80 align:#right offset:[0,20]
					-- SHUTTER
					spinner spn_sh "Duration" range:[0,1.0E6,100] fieldWidth:60 align:#left			
					-- SENSOR
					spinner spn_iso "ISO" range:[0,1.0E6,100] fieldWidth:60 align:#left offset:[23,0]
				)								
				
				group "Output size"
				(
					spinner spn_w "Width" type:#integer range:[1,1000000,100] fieldwidth:65 align:#right across:2
					spinner spn_r "Ratio" type:#float range:[0.0,6.0,1.33] fieldwidth:65 align:#right
					spinner spn_h "Height" type:#integer range:[1,1000000,100] fieldwidth:65 align:#right across:2
					checkButton chk_ratio "LOCK" height:18 width:75 align:#right
					label lbl_presets "Presets" align:#left
					
					button p1 "9:16" width:40 across:5
					button p2 "2:3" width:40
					button p3 "4:5" width:40
					button p4 "3:4" width:40
					button p5 "1:1" width:40
					button p6 "4:3" width:40 across:5
					button p7 "16:10" width:40
					button p8 "16:9" width:40
					button p9 "2:1" width:40
					button p10 "21:9" width:40
				)
				--------------------------------
				local active_cam
				local list_cam
				local curr_itm = 1
				local ratios = #(0.5625, 0.666667, 0.8, 0.75, 1.0, 1.33333, 1.6, 1.77778, 2.0, 2.37037)
				--------------------------------
				/* Store Resolution settings in camera */
				fn set_cam_res cam w h r =
				(
					if isValidNode cam then (
						setUserProp cam "w_res" w
						setUserProp cam "h_res" h
						setUserProp cam "aspect_ratio" r			
					)
				)
				/* Set default aspect ratio */
				-- fn set_def_aspect cam r = ()
				
				/* Get stored cam resolution */
				fn get_cam_res cam &width &height &ratio =
				(
					if isValidNode cam then (
						
						local
						w = getUserProp cam "w_res",
						h = getUserProp cam "h_res",
						r = getUserProp cam "aspect_ratio"
						
						width  = if w != undefined then w as integer --else undefined
						height = if h != undefined then h as integer --else undefined
						ratio  = if r != undefined then r as float	 --else undefined
					)				
				)			
				/* Physical camera PROPERTIES */
				fn shutterType2Values cam =
				(
					case drp_ev.selection of (
						1: (spn_sh.value = 1.0 / cam.shutter_length_seconds)
						2: (spn_sh.value = cam.shutter_length_seconds)
						3: (spn_sh.value = cam.shutter_length_frames * 360)
						4: (spn_sh.value = cam.shutter_length_frames)
					)
				)
				fn shutterValue cam val =
				(
					case drp_ev.selection of (
						1: (cam.shutter_length_seconds = val / 1.0)
						2: (cam.shutter_length_seconds = val)
						3: (cam.shutter_length_frames = val / 360)
						4: (cam.shutter_length_frames = val)
					)
				)
				fn get_camprops cam =
				(
					if classOf cam == Physical then
					(
						-- Lens
						spn_fl.enabled = NOT cam.specify_fov
						spn_fov.enabled = cam.specify_fov
						
						spn_fl.value = cam.focal_length_mm
						spn_fov.value = cam.fov
						chk_fov.state = cam.specify_fov
						
						chk_dof.state = cam.use_dof
						spn_f.value = cam.f_number						
						chk_tilt.state = cam.auto_vertical_tilt_correction
						--shutter
						drp_ev.selection = cam.shutter_unit_type + 1
						shutterType2Values cam
						-- EV
						rd_ex.state = cam.exposure_gain_type + 1
						case cam.exposure_gain_type of
						(
							0:(spn_iso.enabled = true; spn_ev.enabled = false)
							1:(spn_iso.enabled = false; spn_ev.enabled = true)
						)
						spn_iso.value = cam.iso						
						spn_ev.value = cam.exposure_value
					)
				)
				/* DEPRECATED */
				fn set_camprops cam =
				(
					if classOf cam == Physical then
					(
						-- Lens
						cam.specify_fov = chk_fov.state
						cam.focal_length_mm = spn_fl.value
						cam.fov = spn_fov.value
						
						cam.use_dof = chk_dof.state
						cam.f_number = spn_f.value
						cam.auto_vertical_tilt_correction = chk_tilt.state

						-- shutter
						cam.shutter_unit_type = drp_ev.selection - 1
						shutterValue cam spn_sh.value
						-- EV
						cam.exposure_gain_type = rd_ex.state - 1
						case cam.exposure_gain_type of
						(
							0: (cam.iso = spn_iso.value)
							1: (cam.exposure_value = spn_ev.value)
						)
						spn_iso.value = cam.iso
						spn_ev.value = cam.exposure_value
					)
				)
				fn set_camprop cam prop val =
				(
					if classOf cam == Physical AND isProperty cam prop then (
						setProperty cam prop val
					)
				)
				/* GET RENDER RES VALUES */
				fn get_output_values =
				(
					spn_w.value = renderWidth
					spn_h.value = renderHeight
					spn_r.value = rendImageAspectRatio
				)
				/* CHANGE RENDER RATIO */
				fn set_output_ratio val =
				(
					if renderSceneDialog.isOpen() then renderSceneDialog.close()
					rendImageAspectRatio = val
					spn_w.value = renderWidth
					spn_h.value = renderHeight
					CompleteRedraw()
				)
				/* CHANGE RENDER RESOLUTION */
				fn set_output_res w h =
				(
					if renderSceneDialog.isOpen() then renderSceneDialog.close()
					if w != undefined then renderWidth  = w
					if h != undefined then renderHeight = h
					spn_r.value = rendImageAspectRatio
					redrawViews()
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
					for cam in cameras collect #(cam, cam.name)
				)
				/* UPDATE CAMERA LIST */
				fn relist_cams =
				(
					list_cam = listCameras()
					lst_cams.items = for i in list_cam where (isKindOf i[1] camera) collect i[2]					
					-- local only_names = for i in list_cam where (isKindOf i[1] camera) collect i[2]
					-- local only_cams  = for i in list_cam where (isKindOf i[1] camera) collect i[1]
					-- lst_cams.items = only_names
				)		
				/* GET THE ACTIVE CAMERA */
				fn change_active =
				(
					if active_cam == undefined then active_cam = getActiveCamera()			
					--active_cam = getActiveCamera()			
					if active_cam != undefined then (						
						-- camera properties
						get_camprops active_cam				
						-- load camera custom resolution AND assign to render settings						
						get_cam_res active_cam &w &h &r
						
						if w != undefined AND h != undefined then (
							-- Check if active preview is enabled
							if NOT owner.Active_preview then (
								set_output_res w h
								get_output_values()
							)						
							lbl_cam.text = active_cam.name + "(" + w as string + "x" + h as string + ")" + "@" + r as string							
						) else (
							lbl_cam.text = active_cam.name
						)
					) else (
						lbl_cam.text = "None"
					)
					RedrawViews()
				)
				/* SET ACTIVE CAMERA IN VIEWPORT */
				fn setActiveCam n =
				(
					if n != undefined then (
						local cam = if (isKindOf n string) then ( getNodeByName n) else n
						
						if isValidNode cam AND (isKindOf cam camera) then (
							if viewport.CanSetToViewport cam then viewport.SetCamera cam				
							active_cam = cam
							-- update
							change_active()				
						)
					)
				)
				--------------------------------
				on roll_Cams open do
				(
					change_active()
					relist_cams()			
					get_output_values()
					chk_ratio.checked = rendLockImageAspectRatio
				)
				on roll_Cams close do updateToolbarButtons()
				/* SELECT CAMERA */
				on btn_s pressed do ( selCam active_cam )
				/* PREVIOUS CAMERA */
				on btn_prev_cam pressed do
				(
					if curr_itm > 1 then curr_itm -=1
					lst_cams.selection = curr_itm
					setActiveCam lst_cams.selected
					
					owner.roll_batch.view_settings()
				)
				/* NEXT CAMERA */
				on btn_next_cam pressed do
				(
					if curr_itm < lst_cams.items.count then curr_itm +=1
					lst_cams.selection = curr_itm
					setActiveCam lst_cams.selected
					
					owner.roll_batch.view_settings()
				)
				/* CHANGE ACTIVE CAMERA */
				on lst_cams selected item do
				(
					curr_itm = item
					setActiveCam lst_cams.selected
					
					owner.roll_batch.view_settings()	
				)
				/* CAMERA PARAMETERS*/
				-- Lens
				on chk_fov changed state do
				(
					spn_fl.enabled = NOT state
					spn_fov.enabled = state
					set_camprop active_cam #specify_fov state
				)				
				on spn_lf   changed val do set_camprop active_cam #focal_length_mm val
				on spn_fov  changed val do set_camprop active_cam #fov val
				on chk_dof  changed state do set_camprop active_cam #use_dof state
				on chk_tilt changed state do set_camprop active_cam	#auto_vertical_tilt_correction state					
				-- Shutter
				on drp_ev selected idx do (
					shutterType2Values active_cam
					set_camprop active_cam #shutter_unit_type (idx - 1)
				)
				on spn_sh changed val do shutterValue active_cam val
				-- EV
				on rd_ex changed state do
				(
					case state of
					(
						1:(spn_iso.enabled = true; spn_ev.enabled = false)
						2:(spn_iso.enabled = false; spn_ev.enabled = true)
					)
					set_camprop active_cam #exposure_gain_type (state - 1)
				)
				on spn_iso  changed val do set_camprop active_cam #iso val
				on spn_ev   changed val do set_camprop active_cam #exposure_value val
				/* REFRESH CAM LIST */
				on btn_1 pressed do  (
					change_active()
					relist_cams()
				)
				/* LOCK STATUS OF RENDER RATIO */
				on chk_ratio changed status do (
					rendLockImageAspectRatio = status
				)
				/* CHANGE RENDER OUTPUT */
				on spn_w changed val do (
					
					if chk_ratio.checked then spn_h.value = floor(val/spn_r.value)
					-- set_output_res val undefined
					set_output_res val spn_h.value					
					-- save values in camera
					set_cam_res active_cam val spn_h.value spn_r.value
					-- change_active()
				)
				/* CHANGE RENDER HEIGHT */
				on spn_h changed val do (
					if chk_ratio.checked then spn_w.value = floor(val*spn_r.value)
					set_output_res spn_w.value val
					-- save values to camera
					set_cam_res active_cam spn_w.value val spn_r.value
					-- change_active()
				)
				/* CHANGE RENDER WIDTH */
				on spn_r changed val do (
					set_output_ratio val
					-- save values to camera
					set_cam_res active_cam spn_w.value spn_h.value val
					-- change_active()		
				)			
				/* IMAGE RATIO PRESETS */
				fn preset val =
				(
					set_output_ratio (spn_r.value = val)
					-- save values to camera
					set_cam_res active_cam spn_w.value spn_h.value spn_r.value
					change_active()
				)
				/* PRESETS */
				on p1 pressed do preset  ratios[1]
				on p2 pressed do preset  ratios[2]
				on p3 pressed do preset  ratios[3]
				on p4 pressed do preset  ratios[4]
				on p5 pressed do preset  ratios[5]
				on p6 pressed do preset  ratios[6]
				on p7 pressed do preset	 ratios[7]
				on p8 pressed do preset	 ratios[8]
				on p9 pressed do preset	 ratios[9]
				on p10 pressed do preset ratios[10]	
				/*------------------------------ ROLLOUT END ------------------------------*/
			)
			roll_Cams
		),
		/* BATCH ROLLOUT */
		fn ui_batch =
		(
			rollout roll_batch "Batch Render"
			(
				local roll_w = 250
				local owner = if owner != undefined then owner
				--------------------------------
				group "Batch views"
				(
					listbox lst_views "Batch Views" height:5
					edittext txt_1 "View name" fieldWidth:(roll_w - 25) bold:true labelOnTop:true
					edittext txt_3 "File name" fieldWidth:(roll_w - 25) labelOnTop:true
					edittext txt_2 "Output" fieldWidth:(roll_w - 60) labelOnTop:true across:2
					button btn_p "..." align:#right offset:[0,15] tooltip:"Change path"
					checkbox chk_1 "Override output size in view" align:#left \
											tooltip:"Set active render output size as view override"
					button btn_v "Add View to batch" width:(roll_w - 80) height:25 align:#left across:2
					button btn_rem "Delete" height:25 align:#right
				)		
				button btn_bup "Refresh" width:(roll_w - 70) height:25 align:#left
				tooltip:"Update the views list"
				button btn_b "Open Batch window" width:(roll_w - 70) height:25 align:#left
				--------------------------------
				local batch_view
				local view_name   = ""
				local view_path   = undefined
				local active_view = undefined
				--------------------------------
				/* FIND ITEM IN LIST */
				fn findItemInList item lst =
				(
					local idx = FindItem lst.Items item
					if idx != 0 then lst.selection = idx
				)		
				/* SET VIEW OUT PATH */
				fn SetViewPath the_view =
				(
					if view_path != undefined then the_view.outputFilename = view_path
				)
				/* UPDATE BITMAP FILENAME */
				fn update_Path cam: =
				(
					if view_path != undefined then (
						txt_2.text = getFilenamePath view_path
						txt_3.text = filenameFromPath view_path
					) else (
						txt_2.text = ""
						txt_3.text = ""
					)
				)
				/* LIST BATCH VIEWS */
				fn list_views =
				(
					local gv =  batchRenderMgr.GetView
					local num = batchRenderMgr.numViews
					local col = for i=1 to num collect (
						local the_view = gv i
						local st = if the_view.enabled then "[x] " else "[o] "
						st+the_view.name
					)
					lst_views.items = col
				)
				/* LOAD VIEW PROPS */
				fn get_view_params index =
				(
					local the_view = try (batchRenderMgr.GetView index) catch undefined
					if the_view != undefined then (
						txt_1.text = the_view.name
						local cam  = the_view.camera
						if isValidNode cam then (
							owner.roll_Cams.setActiveCam cam
							-- SET CAM IN LIST
							findItemInList cam.name owner.roll_Cams.lst_cams
							-- Get the view Path
							if the_view.outputFilename != undefined then (
								txt_2.text = getFilenamePath the_view.outputFilename
								txt_3.text = filenameFromPath the_view.outputFilename
							)
						)
						-- SET RENDER OUTPUT TO THE VIEW OVERRIDE, USEFUL TO SEE THE CROP FRAME ETC...
						if the_view.overridePreset then (
							renderWidth  = the_view.width
							renderHeight = the_view.height
							owner.roll_Cams.get_output_values()
						)
						CompleteRedraw()
					)
					the_view
				)
				/* LOAD VIEW PROPS */
				fn view_settings =
				(
					local temp_cam = owner.roll_Cams.active_cam
					if (temp_cam != undefined) then (
						txt_1.text = temp_cam.name + "-" + (rendImageAspectRatio as string)
						if (view_path != undefined) then (
							local root     = getFilenamePath view_path
							local type     = getFilenameType view_path
							local filename = filenameFromPath view_path
							
							local comp_filename = temp_cam.name + type
							for i in owner.roll_Cams.list_cam do (
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
						)
						update_Path()
					)
				)
				/* ADD VIEW */
				fn view_add =
				(
					local temp_cam = owner.roll_Cams.active_cam
					if temp_cam != undefined then (
						if (batchRenderMgr.FindView txt_1.text) == 0 then (
							local new_view = batchRenderMgr.CreateView temp_cam
							if (new_view.overridePreset = chk_1.state) then (
								new_view.width  = renderWidth
								new_view.height = renderHeight
							)
							new_view.name = txt_1.text
							new_view.outputFilename = view_path
							list_views()
						) else messageBox "View Already exist.\nChange name AND try again."
					)
				)
				--------------------------------
				on roll_batch open do
				(
					view_settings()
					list_views()
				)
				
				on roll_batch rolledUp state do (
					if NOT state then (
						owner.CamFloater.size.y -= roll_batch.height
					) else (
						owner.CamFloater.size.y += roll_batch.height
					)
				)
				--------------------------------				
				/* GET BATCH VIEW PARAMS */
				on lst_views selected item do ( active_view = get_view_params item )
				/* SET VIEW OUTPUT */
				on btn_p pressed do
				(
					if (view_path = getBitmapSaveFileName()) != undefined then (
						update_Path()
						if active_view != undefined then (
							SetViewPath active_view
						)
					)
				)
				/* ADD VIEW */
				on btn_v pressed do ( view_add() )
				/* DELETE VIEW */
				on btn_rem pressed do
				(
					if (queryBox "Confirm view Deletion?") then (
						if active_view != undefined then (
							batchRenderMgr.DeleteView lst_views.selection
							-- refresh list
							batch_view  = undefined
							view_name   = ""
							--	view_path   = undefined
							active_view = undefined
							list_views()
						)
					)
				)
				/* UPDATE BATCH VIEWS LIST */
				on btn_bup pressed do
				(
					batch_view  = undefined
					view_name   = ""
					--	view_path   = undefined
					active_view = undefined					
					list_views()
				)
				/* OPEN RENDER BATCH */
				on btn_b pressed do (actionMan.executeAction -43434444 "4096")
				/*------------------------------ ROLLOUT END ------------------------------*/
			)
			roll_batch
		),
		public
		/* TOOL MAIN UI */
		fn showUI =
		(
			local res = false
				-- TODO: LICENSING!
				if (CamFloater != undefined AND CamFloater.open) then (
					try (closeRolloutFloater CamFloater) catch ()
					CamFloater = undefined
					updateToolbarButtons()
				) else (			
					roll_Cams = ui_cams()
					roll_Batch = ui_batch()
					
					roll_Cams.owner = this
					roll_Batch.owner = this
					
					CamFloater = newRolloutFloater "Camera Manager" 270 663 50 50 lockHeight:true lockWidth:true
					addRollout roll_Cams  CamFloater border:false
					addRollout roll_Batch CamFloater
					res = true
				)
			res
		)
	)
	------------------------------------------------------
	cmt = camManagerTool()
	------------------------------------------------------
	on execute do (
		if cmt == undefined then cmt = camManagerTool()
		cmt.showUI()
	)
)