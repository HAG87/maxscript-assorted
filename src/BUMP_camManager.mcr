/*
* -------------------------------------------------------------------------------------------
* Camera Manager - FREE VERSION. COMPLETE VERSION IS PART OF DESIGTOOLBOX
* htpps://atelierbump.com
* Bump 2019-2022
* rev 1.5 03/06/2019
* 02-2021
* 01-2022
* Added Shutter parameters, reordered parameters, changed presets to common aspect ratios
* 04-2026
* feat: Restore scene state for the batch view
* feat: Arrange batch views by  buttons up and down
* feat: roll_Cams close event saves its position and size to an INI file.
* feat: fn compareCamNames to sort camera names alphabetically.
* feat: Resizes the Floater based on the height of its rollouts.
* -------------------------------------------------------------------------------------------
*/
macroScript BUMP_CamMngr
	category:     "BUMP tools"
	ButtonText:   "Camera manager"
	tooltip:      "Manage Cameras and render batch views"
	silentErrors: false
	icon:         #("extratools", 1)
(
	-- For holding batc view data
	struct viewData (
		name, enabled, overridePreset, startFrame, endFrame,
		width, height, pixelAspect, outputFilename, 
		camera, sceneStateName, presetFile
	)
	
	struct camManagerTool
	(
		CamFloater,		
		dialog_width = 250,
		Active_preview = false,
		roll_Cams,
		roll_Batch,
		roll_active,
		
		private
		fn resizeFloater = 
		(
			local h=CamFloater.rollouts.count * 30 
			for i in 1 to CamFloater.rollouts.count do (
				if CamFloater.rollouts[i].open then h+= CamFloater.rollouts[i].height
			)
			local scale_dpi = ((dotNetClass "System.Drawing.Graphics").fromHwnd 0).dpiX / 100
			CamFloater.size = [CamFloater.size[1], h / scale_dpi]
		),
		
		private
		/* CAMS ROLLOUT */
		fn ui_cams =
		(
			rollout roll_Cams "Camera Manager"
			(
				local roll_w = 250 --roll_Cams.width
				local owner = if owner != undefined then owner
				--------------------------------
				label lbl_001 "Active Cam:" align:#left across:2
				label lbl_cam "" align:#left height:25
				
				group "Scene cameras"
				(
					listbox lst_cams "" height:20
					button btn_prev_cam "<<" width:60 align:#left across:3
						tooltip:"Previous camera"
					button btn_s "Select" width:80 align:#center
						tooltip:"Select active camera"
					button btn_next_cam ">>" width:60 align:#right
						tooltip: "Next camera"
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
					if (isvalidnode cam) and classOf cam == Physical then
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
				fn compareCamNames a b = case of (
					(a.name < b.name): -1
					(a.name > b.name): 1
					default: 0
				)
				fn listCameras =
				(
					local ls = for cam in cameras where (isKindOf cam camera) and not cam.isHidden collect cam
					qsort ls compareCamNames
					ls
				)
				/* UPDATE CAMERA LIST */
				fn relist_cams =
				(
					list_cam = listCameras()
					lst_cams.items = for cam in list_cam collect cam.name
					-- local only_names = for i in list_cam where (isKindOf i[1] camera) collect i[2]
					-- local only_cams  = for i in list_cam where (isKindOf i[1] camera) collect i[1]
					-- lst_cams.items = only_names
				)		
				/* GET THE ACTIVE CAMERA */
				fn change_active =
				(
					if active_cam == undefined or not (isvalidnode active_cam) then active_cam = getActiveCamera()			
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
						
						-- search old active_cam
						local store_old_active_cam = viewport.activeViewport
						for i in 1 to viewport.numViews do (
							if (viewport.getCamera index:i) == active_cam do (
								viewport.activeViewport = i
							)
						)
						
						if isValidNode cam AND (isKindOf cam camera) then (
							if viewport.CanSetToViewport cam then viewport.SetCamera cam
							viewport.activeViewport = store_old_active_cam
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
				
				on roll_Cams close do (
					updateToolbarButtons()
					-- Save position to INI
					local iniPath = getmaxinifile()
					setINISetting iniPath "CamManager" "Position" (CamFloater.pos as string)
					setINISetting iniPath "CamManager" "WindowsSize" (CamFloater.size as string)
					if roll_Cams.open then setINISetting iniPath "CamManager" "RolloutOpened" "Cams"
				)
				
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

				on roll_Cams rolledUp state do (
					for i in 1 to CamFloater.rollouts.count do (
						if CamFloater.rollouts[i] != roll_Cams do (
							CamFloater.rollouts[i].open = not state
						)
					)
					resizeFloater()
				)
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
				button btn_b "Batch Views" width:80 height:25 align:#left offset:[-10,0]
				button btn_refresh "🔄️ Refresh" width:(roll_w - 120) height:25 align:#left offset:[65,-30] tooltip:"Update the views list" 
				listbox lst_views "" height:20  offset:[-10,0]
				
				button btn_togleEnabled "☑️" align:#right width:24 height:25 tooltip:"Toggle enabled" offset:[14,-272]
				button btn_togleEnabledAll "✓✓" align:#right width:24 height:25 tooltip:"Toggle enabled ALL" offset:[14,0]
				button btn_up "↑" height:55 align:#right tooltip:"Move view up" offset:[14,2]
				button btn_add_sep "—" width:24 align:#right tooltip:"Add separator" offset:[14,0]
				button btn_down "↓"  height:55 align:#right tooltip:"Move view down" offset:[14,0]
				button btn_dup "📋" width:24 height:25 align:#right offset:[14,2] tooltip:"Duplicate view" 
				button btn_rem "❌" width:24 height:25 align:#right offset:[14,0]
				
				checkbutton btn_net_render "🕸️ Net" width:80 height:25 align:#left offset:[-10,0]
				button btn_render "🫖 Render" height:25 width:(roll_w - 120) align:#left offset:[65,-30]
				
				label lbl_separator_1 "" offset:[0, -5]
				group "Edit batch view" (
					edittext txt_1 "View name" fieldWidth:(roll_w - 35) bold:true labelOnTop:true 
					edittext txt_2 "Output path" fieldWidth:(roll_w - 80) labelOnTop:true
					button btn_open_in_explorer "Open" align:#right width:40 offset:[5,-25] tooltip:"Open folder in explorer" 
					edittext txt_3 "File name" fieldWidth:(roll_w - 80) labelOnTop:true
					button btn_p "..." align:#right width:40 offset:[5,-25] tooltip:"Use save file dialog"
					
					checkbox chk_1 "Override output size in view" align:#left \
										tooltip:"Set active render output size as view override"
					label lbl_res "Resolution" across:2 align:#left offset:[65,3]
					button btn_use_current_res "📐" align:#right width:40 offset:[5,0]\
						tooltip:"Use current render resolution.\nChange resolution on the Camera rollout."
					dropdownlist drdwn_cam "Camera" Width:(roll_w - 80) items:#("---------------------") across:2 offset:[0,-23]
					button btn_use_active_cam "🎥" align:#right width:40 offset:[5,-5] tooltip:"Use active camera"
					dropdownlist drdwn_state "Scene State" items:#("---------------------")
					button btn_v "➕ Add View to batch" height:25 align:#left
				)
				
				label lbl_separator_2 "" offset:[0, -5]
				group "Global Settings" (
					slider sld_global_res "Scale:  100%" range:[1,7,4] type:#integer ticks:7 across:2
					checkbox chk_affect_to_all "Affect ALL views" checked:true offset:[0,-2]
					button btn_apply_res "Apply" height:25 width:120 align:#left offset:[100,-35]
					
					button btn_set_folder "📂 Set output folder for all views" width:(roll_w - 40) height:25 offset:[0,5]
				)
				--------------------------------
				local batch_view
				local view_name   = ""
				local view_path   = undefined
				local active_view = undefined
				--------------------------------
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
				
				/* ENABLING MOVE BUTTONS */
				-- [side-effect] Меняет enabled/caption у btn_up, btn_down, btn_togleEnabled, btn_rem
				fn lst_views_update_buttons = (
					index = lst_views.selection
					
					if lst_views.selection == 0 or lst_views.items.count <= 1 then (
						btn_up.enabled = false
						btn_down.enabled = false
					) else if index == 1 then (
						btn_up.enabled = false
						btn_down.enabled = true
					) else if index == lst_views.items.count then (
						btn_up.enabled = true
						btn_down.enabled = false
					) else (
						btn_up.enabled = true
						btn_down.enabled = true
					)
					
					if index > 0 then (
						local the_view = batchRenderMgr.GetView index
						btn_togleEnabled.enabled = true
						btn_rem.enabled = true
						btn_togleEnabled.caption = if the_view.enabled then "✅" else "☑️"
						btn_rem.caption = "❌"
					) else (
						btn_togleEnabled.enabled = false
						btn_rem.enabled = false
						btn_togleEnabled.caption = "✓"
						btn_rem.caption = "X"
					)
				)
				
				/* POPULATE CAMERA DROPDOWN */
				fn sortCams a b = case of (
						(a.name < b.name): -1
						(a.name > b.name): 1
						default: 0
					)
				
				fn list_cameras_for_batch = (
					local cams = for cam in cameras where (isKindOf cam camera) and not cam.isHidden collect cam
					qsort cams sortCams
					local cam_names = for cam in cams collect cam.name
					drdwn_cam.items = #("---------------------") + cam_names
				)

				/* LIST BATCH VIEWS */
				-- [side-effect] Меняет lst_views.items, drdwn_state.items, btn_net_render.checked, UI кнопки
				fn list_views =
				(
					local gv =  batchRenderMgr.GetView
					local num = batchRenderMgr.numViews
					local col = for i=1 to num collect (
						local the_view = gv i
						local st
						if substring the_view.name 1 5 == "-----" then (
							st = ""
						) else (
							st = if the_view.enabled then "[v] " else "[ ] "
						)
						st + the_view.name
					)
					lst_views.items = col
					lst_views_update_buttons()
					
					list_cameras_for_batch()
					
					states_names = for i in 1 to sceneStateMgr.getCount() collect (sceneStateMgr.GetSceneState i)
					drdwn_state.items = #("---------------------") + states_names
					
					btn_net_render.checked = batchRenderMgr.netRender
				)
				
				/* VIEW RESILUTION FUNCTIONS */

				/* ============================================================
				   ПРОЦЕНТЫ ДЛЯ СЛАЙДЕРА
				   ============================================================ */

				-- Массив доступных процентов
				global g_scaleValues = #(0.25, 0.5, 0.666667, 1.0, 1.25, 1.5, 2.0)
				-- Массив доступных пропорция изображения
				global g_standardAspects = #(
					1.0,
					4.0/3.0, 3.0/2.0, 16.0/10.0, 16.0/9.0, 2.0, 21.0/9.0,
					3.0/4.0, 2.0/3.0, 5.0/8.0, 9.0/16.0, 1.0/2.0
				)
				-- Допуск для определения близости к стандартной пропорции
				global g_aspectTolerance = 0.01
				-- Размер сетки и допуск для округления
				global g_gridW = 32  -- для ширины
				global g_gridH = 16   -- для высоты
				global g_gridTolerance = 16  -- ±16 пикселей для ширины, ±8 для высоты

				-- Вспомогательные функции округдения
				-- Округлить число до ближайшего кратного
				fn roundToNearestMultiple value multiple = (
					if multiple <= 0 then return value
					local remainder = mod value multiple
					local half = multiple / 2.0
					if remainder < half then return value - remainder
					else return value + (multiple - remainder)
				)

				-- Проверить, можно ли округлить до кратного, и вернуть результат
				-- Если разница ≤ tolerance — возвращает ближайшее кратное, иначе — исходное
				fn tryRoundToMultiple value multiple tolerance = (
					local nearest = roundToNearestMultiple value multiple
					if abs(value - nearest) <= tolerance then nearest else value
				)

				-- Найти ближайшую стандартную пропорцию
				fn findStandardAspect ratio = (
					local closest = undefined
					local minDiff = 999999.0
					
					for asp in g_standardAspects do (
						local diff = abs(ratio - asp)
						if diff < minDiff then (
							minDiff = diff
							closest = asp
						)
					)
					
					if closest != undefined and minDiff <= g_aspectTolerance then (
						return closest
					)
					return undefined
				)


				-- Основная функция округления
				-- Вычислить разрешение с умным округлением
				fn calculateSmartResolution w h = (
					local newW = w
					local newH = h
					
					-- Шаг 1: Округляем ширину до кратного 16 (или 8 как запасной вариант)
					newW = tryRoundToMultiple w g_gridW g_gridTolerance
					if newW == w then newW = tryRoundToMultiple w 8 4
					
					-- Шаг 2: Проверяем пропорцию
					local currentAspect = w as float / h as float
					local stdAspect = findStandardAspect currentAspect
					local useAspect = if stdAspect != undefined then stdAspect else currentAspect
					newH = (newW / useAspect) as integer
					
					-- Округляем высоту до кратного 8
					newH = tryRoundToMultiple newH g_gridH (g_gridTolerance/2)
					
					return #(newW, newH, stdAspect != undefined)
				)

				-- Получить процент по индексу слайдера
				fn getPercentFromSlider = (
					local idx = sld_global_res.value as integer
					if idx < 1 then idx = 1
					if idx > g_scaleValues.count then idx = g_scaleValues.count

					return g_scaleValues[idx]
				)

				-- Получить ближайшее значение из списка
				-- [side-effect] Может добавить значение в g_scaleValues и изменить sld_global_res.range
				fn getClosestScaleValue percent = (
					local closest = 1
					local minDiff = 999999
					
					for val in g_scaleValues do (
						local diff = abs(val - percent)
						if diff < minDiff then (
							minDiff = diff
							closest = val
						)
					)
					
					-- Если разница больше допуска (0.05 = 5%), добавляем новое значение
					if minDiff > 0.05 then (
						append g_scaleValues percent
						sort g_scaleValues
						-- Обновляем диапазон слайдера
						sld_global_res.range = [1, g_scaleValues.count, 1]
						return percent
					)
					
					return closest
				)

				-- Получить индекс слайдера по проценту (один проход)
				-- [side-effect] Может добавить значение в g_scaleValues и изменить sld_global_res.range
				fn getSliderIndexByPercent percent = (
					local bestIdx = 1
					local bestDiff = 999.0
					for i = 1 to g_scaleValues.count do (
						local diff = abs(g_scaleValues[i] - percent)
						if diff < bestDiff then (
							bestDiff = diff
							bestIdx = i
						)
					)
					-- Если разница больше допуска, добавляем значение в список
					if bestDiff > 0.02 then (
						append g_scaleValues percent
						sort g_scaleValues
						sld_global_res.range = [1, g_scaleValues.count, 1]
						for i = 1 to g_scaleValues.count do (
							if g_scaleValues[i] == percent then return i
						)
					)
					return bestIdx
				)

				-- Обновить отображение
				fn updateScaleDisplay percent = (
					if percent == undefined then percent = 1
					
					-- Округляем до ближайшего значения из списка
					local displayPercent = getClosestScaleValue percent
					
					sld_global_res.text = "Scale: " + ((displayPercent * 100) as integer) as string + "%"
					
					-- Устанавливаем слайдер на нужный индекс
					local idx = getSliderIndexByPercent displayPercent
					sld_global_res.value = idx
				)

				/* ============================================================
				   ФУНКЦИИ ДЛЯ РАБОТЫ С ИМЕНЕМ ВИДА
				   ============================================================ */

				-- Получить данные из имени: #(процент, ширина, высота)
				fn getViewDataFromName viewName = (
					local percent = 1
					local w = 0
					local h = 0
					
					if viewName == undefined or viewName == "" then return #(percent, w, h)
					
					local pattern = "\\((\\d+)%\\s+(\\d+)x(\\d+)\\)"
					local regex = dotNetObject "System.Text.RegularExpressions.Regex" pattern
					local match = regex.Match viewName
					
					if match.Success then (
						percent = match.Groups.Item[1].Value
						w = match.Groups.Item[2].Value as integer
						h = match.Groups.Item[3].Value as integer
					)
					return #(percent, w, h)
				)

				-- Очистить имя от данных (процент и разрешение)
				fn getCleanViewName viewName = (
					if viewName == undefined or viewName == "" then return "View"
					
					local pattern = "\\s*\\(\\d+%\\s+\\d+x\\d+\\)\\s*$"
					local regex = dotNetObject "System.Text.RegularExpressions.Regex" pattern
					local cleanName = regex.Replace viewName ""
					cleanName = trimRight cleanName
					
					return if cleanName == "" then "View" else cleanName
				)

				-- Проверить уникальность имени (исключая указанный вид)
				fn isViewNameUnique viewName excludeView = (
					local num = batchRenderMgr.numViews
					for i = 1 to num do (
						local v = batchRenderMgr.GetView i
						if v.name == viewName and v.name != excludeView then return false
					)
					return true
				)

				-- Получить уникальное имя, если занято
				fn getUniqueViewName baseName excludeView = (
					local newName = baseName
					local counter = 1
					while not (isViewNameUnique newName excludeView) do (
						newName = baseName + "_" + (counter as string)
						counter += 1
					)
					return newName
				)

				-- Безопасно установить имя виду (с проверкой уникальности)
				fn safeSetViewName the_view newName = (
					if the_view == undefined then return false
					if the_view.name == newName then return true  -- Имя не меняется
					
					-- Проверяем уникальность
					if isViewNameUnique newName the_view then (
						the_view.name = newName
					) else (
						-- Генерируем уникальное
						local unique_name = getUniqueViewName (getCleanViewName newName) the_view
						-- Добавляем данные обратно, если они были
						local data = getViewDataFromName newName
						if data[2] > 0 and data[3] > 0 then (
							unique_name = unique_name + " (" + (data[1] as string) + "% " + (data[2] as string) + "x" + (data[3] as string) + ")"
						)
						the_view.name = unique_name
					)
					return true
				)

					
				---------------------------------------------------------------
				-- ОСНОВНЫЕ ФУНКЦИИ РАБОТЫ С РАЗРЕШЕНИЕМ
				---------------------------------------------------------------

				-- Применить масштаб к одному виду с умным округлением
				-- [side-effect] Меняет the_view.width/height/name, renderWidth/renderHeight, lbl_res.text
				fn applyScaleToView the_view percent = (
					if the_view == undefined then return false
					
					-- Пропускаем виды без override — их размер задаётся в настройках рендера
					if not the_view.overridePreset then return false
					
					percent = if percent == undefined then 1 else percent
					
					-- Получаем исходное разрешение (из имени или настроек)
					local baseRes = (
						local nd = getViewDataFromName the_view.name
						if nd[2] > 0 and nd[3] > 0 then #(nd[2], nd[3])
						else if the_view.overridePreset then #(the_view.width, the_view.height)
						else #(renderWidth, renderHeight)
					)
					if baseRes[1] <= 0 or baseRes[2] <= 0 then (
						baseRes = #(renderWidth, renderHeight)
						if baseRes[1] <= 0 or baseRes[2] <= 0 then return false
					)
					
					-- Вычисляем сырое разрешение
					local rawW = (baseRes[1] * percent) as integer
					local rawH = (baseRes[2] * percent) as integer
					
					-- Применяем умное округление
					local smartRes = calculateSmartResolution rawW rawH
					local newW = smartRes[1]
					local newH = smartRes[2]
					
					-- Устанавливаем новое разрешение
					the_view.width = newW
					the_view.height = newH
					
					-- Вычисляем реальный процент для отображения
					local realPercent = newW as float / baseRes[1]
					
					-- Формируем имя: "Имя (70% 1920x1280)" — исходное разрешение в скобках
					-- При 100% скобки убираются
					local cleanName = getCleanViewName the_view.name
					local newName = if realPercent == 1 or baseRes[1] <= 0 or baseRes[2] <= 0 then cleanName else (
						local dp = ((getClosestScaleValue realPercent) * 100) as integer
						cleanName + " (" + dp as string + "% " + baseRes[1] as string + "x" + baseRes[2] as string + ")"
					)
					safeSetViewName the_view newName

					-- Обновляем UI если это активный вид
					if lst_views.selection > 0 then (
						local active = batchRenderMgr.GetView lst_views.selection
						if active == the_view then (
							renderWidth = newW
							renderHeight = newH
							lbl_res.text = newW as string + "x" + newH as string + " (" + ((realPercent * 100) as integer) as string + "%)"
						)
					)
					
					return true
				)

				-- Применить масштаб ко всем видам
				fn applyScaleToAllViews percent = (
					percent = if percent == undefined then 1 else percent
					
					disableSceneRedraw()
					local count = 0
					local num = batchRenderMgr.numViews
					
					for i = 1 to num do (
						local v = batchRenderMgr.GetView i
						if v != undefined and substring v.name 1 5 != "-----" then (
							if applyScaleToView v percent then count += 1
						)
					)
					
					enableSceneRedraw()
					list_views()
					
					if lst_views.selection > 0 and get_view_params != undefined then (
						get_view_params lst_views.selection
					)
					
					return count
				)

				-- Установить текущее разрешение как новую базу (100%)
				fn setAsNewBase the_view = (
					if the_view == undefined then return false
					
					-- Получаем текущее разрешение
					local w = if the_view.overridePreset then the_view.width else renderWidth
					local h = if the_view.overridePreset then the_view.height else renderHeight
					
					if w <= 0 or h <= 0 then (
						messageBox "Invalid resolution!" title:"Error"
						return false
					)
					
					-- Сохраняем как новую базу
					the_view.overridePreset = true
					the_view.width = w
					the_view.height = h
					
					local cleanName = getCleanViewName the_view.name
					safeSetViewName the_view cleanName  -- Убираем скобки (100%)
					
					-- Обновляем UI
					if lst_views.selection > 0 then (
						local active = batchRenderMgr.GetView lst_views.selection
						if active == the_view then (
							renderWidth = w
							renderHeight = h
							lbl_res.text = w as string + "x" + h as string
							sld_global_res.value = getSliderIndexByPercent 1
							sld_global_res.text = "Scale: 100%"
						)
					)
					
					list_views()
					if lst_views.selection > 0 and get_view_params != undefined then (
						get_view_params lst_views.selection
					)
					
					return true
				)

				-- Применить процент и установить как новую базу для всех
				fn applyAndSetAsBaseAllViews percent = (
					if percent == 1 then (
						messageBox "Already at 100%" title:"Info"
						return false
					)
					
					disableSceneRedraw()
					local count = 0
					local num = batchRenderMgr.numViews
					
					for i = 1 to num do (
						local v = batchRenderMgr.GetView i
						if v != undefined and substring v.name 1 5 != "-----" then (
							if applyScaleToView v percent then (
								setAsNewBase v
								count += 1
							)
						)
					)
					
					enableSceneRedraw()
					list_views()
					
					if lst_views.selection > 0 and get_view_params != undefined then (
						get_view_params lst_views.selection
					)
					
					return count
				)

				------------------------------------------------------------
				-- ФУНКЦИЯ ЗАГРУЗКИ ПАРАМЕТРОВ ВИДА (ОБНОВЛЕНА)
				------------------------------------------------------------

				fn get_view_params index =
				(
					local the_view = try (batchRenderMgr.GetView index) catch undefined
					if the_view == undefined then return undefined
					
					disableSceneRedraw()
					
					-- Основные параметры
					txt_1.text = the_view.name
					
					local cam = the_view.camera
					if isValidNode cam then (
						owner.roll_Cams.setActiveCam cam
						local camIdx = FindItem owner.roll_Cams.lst_cams.Items cam.name
						if camIdx != 0 then owner.roll_Cams.lst_cams.selection = camIdx
						-- Set camera dropdown
						local drdwnIdx = findItem drdwn_cam.items cam.name
						drdwn_cam.selection = if drdwnIdx == 0 then 1 else drdwnIdx
					) else (
						drdwn_cam.selection = 1
					)
					
					-- Путь
					if the_view.outputFilename != "" then (
						txt_2.text = getFilenamePath the_view.outputFilename
						txt_3.text = filenameFromPath the_view.outputFilename
					) else (
						txt_2.text = ""
						txt_3.text = ""
					)
					
					-- Scene State
					local idx = finditem drdwn_state.items the_view.sceneStateName
					drdwn_state.selection = if idx == 0 then 1 else idx
					if the_view.sceneStateName != "" do (
						local ssp = sceneStateMgr.GetParts the_view.sceneStateName
						sceneStateMgr.Restore the_view.sceneStateName ssp
					)
					
					-- Разрешение
					local data = getViewDataFromName the_view.name
					local baseW = data[2]
					local baseH = data[3]
					local percent = data[1]
					
					-- Проверка: если реальное разрешение не совпадает с записанным в имени,
					-- значит пользователь поменял размер вручную — принимаем за новую базу (100%)
					if baseW > 0 and baseH > 0 and the_view.overridePreset then (
						local namePercent = percent as float
						local expectedW = (baseW * namePercent / 100.0) as integer
						local expectedH = (baseH * namePercent / 100.0) as integer
						if abs(the_view.width - expectedW) > 16 or abs(the_view.height - expectedH) > 16 then (
							local cleanName = getCleanViewName the_view.name
							safeSetViewName the_view cleanName
							baseW = 0
							baseH = 0
						)
					)
					
					chk_1.checked = the_view.overridePreset
					
					if the_view.overridePreset then (
						renderWidth = the_view.width
						renderHeight = the_view.height
						
						-- Вычисляем процент с округлением
						local currentPercent = 100
						local closestRatio = 1.0
						if baseW > 0 then (
							local ratio = the_view.width as float / baseW as float
							closestRatio = getClosestScaleValue ratio
							currentPercent = (closestRatio * 100) as integer
						)
						
						lbl_res.text = renderWidth as string + "x" + renderHeight as string + " (" + currentPercent as string + "%)"
						
						-- Обновляем слайдер
						updateScaleDisplay closestRatio
						
						owner.roll_Cams.get_output_values()
					) else (
						if baseW > 0 and baseH > 0 then (
							renderWidth = baseW
							renderHeight = baseH
							lbl_res.text = "Default (" + baseW as string + "x" + baseH as string + ")"
						) else (
							lbl_res.text = "Default"
						)
						updateScaleDisplay 1
					)
					
					enableSceneRedraw()
					the_view
				)

				/* LOAD VIEW PROPS */
				fn view_settings = (
					local temp_cam = owner.roll_Cams.active_cam
					if temp_cam != undefined then (
						txt_1.text = temp_cam.name + "-" + (rendImageAspectRatio as string)
						if view_path != undefined then (
							local root     = getFilenamePath view_path
							local type     = getFilenameType view_path
							local filename = filenameFromPath view_path
							
							local comp_filename = temp_cam.name + type
							for i in owner.roll_Cams.list_cam do (
								local n = i.name
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
				
				/* CLOSE BATHCH WINDOW */
				fn close_batch_window = (
					-- https://help.autodesk.com/view/MAXDEV/2026/ENU/?guid=GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845
					local batch_window = windows.getChildHWND 0 "Batch Render" parent:#max
					
					if batch_window != undefined \
					and batch_window[4] == "#32770" \ -- window class (filter other windows named "Batch Render")
					do (
						windows.sendMessage batch_window[1] 0x0010 0 0  -- 0x0010 = WM_CLOSE
						return true
					)
					
					return false
				)
				
				/* ADD VIEW */
				fn view_add =
				(
					local temp_cam = owner.roll_Cams.active_cam
					if temp_cam != undefined then (
						close_batch_window()
						local view_name = if txt_1.text == "" then "View" else txt_1.text

						if not (isViewNameUnique view_name "") do (
							view_name = getUniqueViewName view_name ""
						)

						local new_view = batchRenderMgr.CreateView temp_cam
						if (new_view.overridePreset = chk_1.state) then (
							new_view.width  = renderWidth
							new_view.height = renderHeight
						)
						new_view.name = view_name
						new_view.outputFilename = view_path
						list_views()
					) else messageBox "Select the camera in the Camera rollout"
				)
				
			/* UPDATE VIEW FILE PATHS */
				fn view_update =
				(
					if lst_views.selection != 0 do (
						local bv = batchRenderMgr.GetView lst_views.selection
						local any_changed = false
						
						-- Обработка чекбокса Override
						if chk_1.checked then (
							if not bv.overridePreset then (
								-- Включаем override: копируем текущие настройки рендера
								bv.overridePreset = true
								bv.width = renderWidth
								bv.height = renderHeight
								any_changed = true
							)
						) else (
							if bv.overridePreset then (
								-- Выключаем override: вид переходит на глобальные настройки рендера
								bv.overridePreset = false
								any_changed = true
							)
						)
						
						-- Change the name
						if bv.name != txt_1.text then (
							if batchRenderMgr.FindView txt_1.text do (
								messageBox "View Already exist.\nChange name AND try again."
								return undefined
							)
						bv.name = txt_1.text
						-- Синхронизируем override/разрешение из нового имени
						local syncData = getViewDataFromName bv.name
						if syncData[2] > 0 and syncData[3] > 0 then (
							bv.overridePreset = true
							bv.width = syncData[2]
							bv.height = syncData[3]
						)
							list_views()
							any_changed = true
						)
						
						-- Change path
						if txt_2.text == "" or txt_3.text == "" then (
							view_path = undefined
							bv.outputFilename = undefined
							txt_2.text = ""
							txt_3.text = ""
							any_changed = true
						) else if doesfileexist txt_2.text then (
							view_path = txt_2.text + txt_3.text
							bv.outputFilename = view_path
							any_changed = true
						) else (
							messageBox "Directory doesn't exists" title:"Error"
							return undefined
						)
						
						-- Change Scene State
						local selected_scene_state = if drdwn_state.selection > 1 then (
							drdwn_state.items[drdwn_state.selection]) else ("")
						
						if selected_scene_state != bv.sceneStateName do (
							bv.sceneStateName = selected_scene_state
							any_changed = true
						)
						
						if any_changed do (
							close_batch_window()
							list_views()
							if lst_views.selection > 0 then (
								get_view_params lst_views.selection
							)
						)
					)
				)

				on txt_1 entered txt do view_update()
				on txt_2 entered txt do view_update()
				on txt_3 entered txt do view_update()
				
				on chk_1 changed state do (
					if not state do lbl_res.caption = "Default"
					view_update()
				)
				
				on drdwn_state selected index do view_update()

				/* CAMERA SELECTION */
				on drdwn_cam selected index do (
					if lst_views.selection != 0 and index > 1 then (
						local bv = batchRenderMgr.GetView lst_views.selection
						if bv != undefined then (
							local cam_name = drdwn_cam.items[index]
							local cam = getNodeByName cam_name
							if isValidNode cam and (isKindOf cam camera) then (
								close_batch_window()
								bv.camera = cam
								-- Update active camera in viewport
								owner.roll_Cams.setActiveCam cam
								list_views()
								--lst_views.selection = lst_views.selection
							)
						)
					)
				)
				
				/* USE ACTIVE CAMERA */
				on btn_use_active_cam pressed do (
					if lst_views.selection != 0 then (
						local bv = batchRenderMgr.GetView lst_views.selection
						if bv != undefined then (
							local cam = getActiveCamera()
							if cam == undefined then (
								for i in 1 to viewport.numViews where cam == undefined do (
									local vc = viewport.getCamera index:i
									if vc != undefined and isValidNode vc and (isKindOf vc camera) do cam = vc
								)
							)
							if isValidNode cam and (isKindOf cam camera) then (
								close_batch_window()
								bv.camera = cam
								owner.roll_Cams.active_cam = cam
								owner.roll_Cams.change_active()
								-- Update dropdown
								local drdwnIdx = findItem drdwn_cam.items cam.name
								drdwn_cam.selection = if drdwnIdx == 0 then 1 else drdwnIdx
								list_views()
								--lst_views.selection = lst_views.selection
							)
						)
					)
				)
				
				/* USE CURRENT RENDER RESOLUTION */
				on btn_use_current_res pressed do (
					if lst_views.selection != 0 then (
						local bv = batchRenderMgr.GetView lst_views.selection
						if bv != undefined then (
							close_batch_window()
							bv.overridePreset = true
							chk_1.checked = true
							bv.width = renderWidth
							bv.height = renderHeight
							lbl_res.text = bv.width as string + "x" + bv.height as string
							sld_global_res.text = "Scale:  100%"
							sld_global_res.value = getSliderIndexByPercent 1
							local cleanName = getCleanViewName bv.name
							local oldData = getViewDataFromName bv.name
							safeSetViewName bv cleanName
							list_views()
							-- lst_views.selection = lst_views.selection
						)
					)
				)

				on btn_open_in_explorer pressed do (
					if txt_2.text != "" then (
						if doesfileexist txt_2.text then (
							ShellLaunch "explorer.exe" ("\"" + txt_2.text + "\"")
						) else messageBox "Directory doesn't exists" title:"Error"
					)
				)
				
				on btn_render pressed do (
					batchRenderMgr.render()
				)
				
				on btn_net_render changed state do (
					close_batch_window()
					batchRenderMgr.netRender = state
				)
				
				/* MOVE VIEW UP/DOWN IN BATCH LIST */
				fn move_view_index from_idx to_idx = (
					close_batch_window()
					if from_idx == to_idx or from_idx < 1 or to_idx < 1 then return false
					
					local num = batchRenderMgr.numViews
					if from_idx > num or to_idx > num then return false
						
					local min_replace_indx = if from_idx > to_idx then to_idx else from_idx
					
					-- Collect views data
					local views_data = for i = min_replace_indx to num collect (
						local v = batchRenderMgr.GetView i
						viewData v.name v.enabled v.overridePreset v.startFrame v.endFrame \
							v.width v.height v.pixelAspect v.outputFilename v.camera \
							v.sceneStateName v.presetFile
					)
					
					-- Reorder the data array
					local item = views_data[from_idx - min_replace_indx + 1]
					deleteItem views_data (from_idx - min_replace_indx + 1)
					insertItem item views_data (to_idx - min_replace_indx + 1)
					
					-- Delete views (from end to avoid index shift)
					for i = num to min_replace_indx by -1 do batchRenderMgr.DeleteView i
					
					-- Recreate views in new order
					for vd in views_data do (
						local new_v = batchRenderMgr.CreateView vd.camera
						if new_v != undefined then
						(
							if new_v.name != vd.name do new_v.name = vd.name
							new_v.enabled = vd.enabled
							new_v.overridePreset = vd.overridePreset
							new_v.startFrame = vd.startFrame
							new_v.endFrame = vd.endFrame
							new_v.width = vd.width
							new_v.height = vd.height
							new_v.pixelAspect = vd.pixelAspect
							new_v.outputFilename = vd.outputFilename
							new_v.sceneStateName = vd.sceneStateName
							new_v.presetFile = vd.presetFile
						)
					)

					return true
				)
				
				--------------------------------
				on roll_batch open do
				(
					list_views()
					lst_views.selection = 0
				)
				
				on roll_batch rolledUp state do (
					if state do (
						for i in 1 to CamFloater.rollouts.count do (
							if CamFloater.rollouts[i] != roll_batch do (
								CamFloater.rollouts[i].open = false
							)
						)
					)
					resizeFloater()
				)
				
				--------------------------------				
				/* GET BATCH VIEW PARAMS */
				on lst_views selected index do (
					active_view = get_view_params index
					lst_views_update_buttons()
				)
				
				/* SET VIEW OUTPUT */
				on btn_p pressed do
				(
					if view_path != undefined then (
						new_path = getBitmapSaveFileName filename:view_path
					) else if txt_3.text != "" then (
						new_path = getBitmapSaveFileName filename:txt_3.text
					) else (
						new_path = getBitmapSaveFileName()
					)
					if new_path != undefined then (
						view_path = new_path
						update_Path()
						if active_view != undefined then (
							if view_path != undefined then active_view.outputFilename = view_path
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
							active_view = undefined
							lst_views.selection = 0
							list_views()
						)
					)
				)
				
				/* DUPLICATE VIEW */
				on btn_dup pressed do (
					if lst_views.selection != 0 then (
						batchRenderMgr.DuplicateView lst_views.selection
						-- Reorder
						move_view_index batchRenderMgr.numViews (lst_views.selection + 1)
						lst_views.selection += 1
						-- refresh list
						list_views()
					)
				)
				
				/* UPDATE BATCH VIEWS LIST */
				on btn_refresh pressed do
				(
					batch_view  = undefined
					view_name   = ""
					--	view_path   = undefined
					active_view = undefined					
					list_views()
					owner.roll_Cams.relist_cams()
					owner.roll_Cams.change_active()
					if lst_views.selection > 0 do get_view_params lst_views.selection
				)
				
				/* OPEN RENDER BATCH */
				on btn_b pressed do (
					actionMan.executeAction -43434444 "4096"
				)
				
				/* TOGGLE ENABLED */
				on btn_togleEnabled pressed do (
					local v = batchRenderMgr.GetView lst_views.selection
					if substring v.name 1 5 != "-----" then (
						close_batch_window()
						v.enabled = not v.enabled
						list_views()
					)
				)
				
				/* TOGGLE ENABLED ALL*/
				on btn_togleEnabledAll pressed do (
					local num = batchRenderMgr.numViews
					local enb = 0
					local dsb = 0
					for i=1 to num collect (
						if (batchRenderMgr.GetView i).enabled then enb += 1 else dsb += 1
					)
					-- Если больше включёныйх, то всё выключить
					local action = not (enb > dsb)
					for i=1 to num collect (
						local the_view = batchRenderMgr.GetView i
						the_view.enabled = action
					)
					list_views()
				)
				
				/* MOVE VIEW UP */
				on btn_up pressed do
				(
					if lst_views.selection > 0 and lst_views.selection > 1 then
					(
						local sel = lst_views.selection
						if move_view_index sel (sel - 1) then
						(
							lst_views.selection = sel - 1
							list_views()
							active_view = batchRenderMgr.GetView (sel - 1)
						)
					)
				)
				
				/* ADD SEPARATOR */
				on btn_add_sep pressed do (
					local sep_name
					local n = 0
					do (
						n += 1
						sep_name = "----- " + n as string + " -----"
					) while (
						(batchRenderMgr.FindView sep_name) != 0
					)
					
					local sep_view = batchRenderMgr.CreateView undefined
					sep_view.name = sep_name
					sep_view.enabled = false
					
					-- Reorder
					if lst_views.selection > 0 then (
						move_view_index batchRenderMgr.numViews (lst_views.selection + 1)
						lst_views.selection += 1
					) else (
						lst_views.selection = batchRenderMgr.numViews
					)
					
					list_views()
					get_view_params lst_views.selection
				)
				
				/* MOVE VIEW DOWN */
				on btn_down pressed do
				(
					if lst_views.selection > 0 and lst_views.selection < lst_views.items.count then
					(
						local sel = lst_views.selection
						if move_view_index sel (sel + 1) then
						(
							lst_views.selection = sel + 1
							list_views()
							active_view = batchRenderMgr.GetView (sel + 1)
						)
					)
				)
				
				/* ОБРАБОТЧИКИ ГЛОБАЛЬНОГО РАЗРЕШЕНИЯ */
				-- Ползунок глобального масштаба
				on sld_global_res changed val do (
					-- val это индекс списка процентов
					local percent = getPercentFromSlider()
					updateScaleDisplay percent

					if chk_affect_to_all.checked then (
						applyScaleToAllViews percent
					) else if lst_views.selection > 0 then (
						local v = batchRenderMgr.GetView lst_views.selection
						if v != undefined and substring v.name 1 5 != "-----" then (
							applyScaleToView v percent
							list_views()
							if get_view_params != undefined then get_view_params lst_views.selection
						)
					) else (
						messageBox "Select a view first" title:"Warning"
					)
				)

				-- Кнопка "Применить и установить как новую базу"
				on btn_apply_res pressed do (
					if lst_views.selection == 0 then (
						messageBox "Select a view first" title:"Warning"
						return false
					)
					
					local v = batchRenderMgr.GetView lst_views.selection
					if v == undefined or substring v.name 1 5 == "-----" then (
						messageBox "Invalid view selected" title:"Warning"
						return false
					)
					
					local percent = getPercentFromSlider()
					if percent == 1 then (
						messageBox "Current scale is 100%. Nothing to apply." title:"Info"
						return false
					)
					
					if chk_affect_to_all.checked then (
						applyAndSetAsBaseAllViews percent
						-- messageBox "Applied to ALL views and set as new 100%"
					) else (
						if applyScaleToView v percent then (
							setAsNewBase v
							list_views()
							if get_view_params != undefined then get_view_params lst_views.selection
							-- messageBox "Applied and set as new 100% for selected view"
						)
					)
				)
				
				/* SET OUTPUT FOLDER FOR ALL VIEWS */
				on btn_set_folder pressed do (
					local folder = getSavePath caption:"Select output folder"
					if folder == undefined then return false
					close_batch_window()
					local count = 0
					local num = batchRenderMgr.numViews
					for i = 1 to num do (
						local v = batchRenderMgr.GetView i
						if v != undefined and substring v.name 1 5 != "-----" then (
							local fname = filenameFromPath v.outputFilename
							if fname != "" then (
								v.outputFilename = pathConfig.appendPath folder fname
								count += 1
							)
						)
					)
					if count > 0 then (
						list_views()
						if lst_views.selection > 0 then (
							get_view_params lst_views.selection
						)
					)
				)

				on roll_Batch close do (
					-- Save position to INI
					if roll_Batch.open then (
						local iniPath = getmaxinifile()
						setINISetting iniPath "CamManager" "RolloutOpened" "Batch"
					)
				)
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
					
					-- Restore position from INI
					local iniPath = getmaxinifile()
					local posStr = getINISetting iniPath "CamManager" "Position"
					local sizeStr = getINISetting iniPath "CamManager" "WindowsSize"
					if posStr != "" and sizeStr != "" then
					(
						local p = execute posStr
						local s = execute sizeStr
						CamFloater = newRolloutFloater "Camera Manager" s[1] s[2] p[1] p[2] lockHeight:false lockWidth:true
					) else (
						CamFloater = newRolloutFloater "Camera Manager" dialog_width 663 50 50 lockHeight:false lockWidth:true
					)
					local rolloutOpened = getINISetting iniPath "CamManager" "RolloutOpened"
					addRollout roll_Cams  CamFloater rolledup:(rolloutOpened != "Cams")
					addRollout roll_Batch CamFloater rolledUp:(rolloutOpened != "Batch")

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
