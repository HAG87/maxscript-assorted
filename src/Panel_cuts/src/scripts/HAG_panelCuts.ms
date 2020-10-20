(
	/*
-------------------------------------------------------------------------------------------------------
HAG Panel Cuts
HAG 2016
version 1.0 - 12-16
-------------------------------------------------------------------------------------------------------
*/
	----	STRINGS
	Local
	r_title	= "PANEL CUTS",
	c_name = "Name:",
	c_h = "Height: ",
	c_l = "Length: ",
	c_w = "Thickness: ",
	c_ck_h = "HEIGHT",
	c_ck_l = "LENGTH",
	c_f = "Finish: ",
	c_t = "Part: ",
	c_c = "Caption: ",
	c_d = "Description: ",
	c_ss = "SELECTION",
	c_s = "Selected",
	c_ps = " > SAVE TO FILE - Current Selection",
	c_pa = " > SAVE TO FILE - All Objects",
	c_i = "REPORT ",
	l_o = "Grain Direction",
	l_cp = "--------------  SHEET QNT  --------------",
	l_dm = "Sheet dimensions: ",
	sc_u = "Scale Up",
	sc_d = "Scale Down",
	----
	drp_itms = #("Vertical","Horizontal"),
	----
	strf_p1 = "Estimated Sheets quantity with a wastage of ",
	strf_p2 = "taking into account the selected objects",
	str_q1 = "This operation will scale up computed dimensions on x% factor. Are you sure?",
	str_q2 = "This operation will scale down computed dimensions on x% factor. Are you sure?",
	str_cap = "CUTS REPORT",
	----
	str_titles = "\"HEIGHT\",\"LENGTH\",\"THICKNESS\",\"ORIENTATION\",\"FINISH\",\"PART\",\"DESCRIPTION\"\n",
	str_titles_2 = "\"QUANT.\",\"HEIGHT\",\"LENGTH\",\"THICKNESS\",\"ORIENTATION\",\"FINISH\",\"PART\",\"DESCRIPTION\"\n",
	----
	str_ok = "COMMIT",
	----	TOOLTIPS
	t1 = "Commit changes, right click on button to change all objects in selection.",
	t2 = "Set selected objects as active object collection. Use previous and next buttons to navigate through the object collection.",
	t3 = "Previuos object. Right click to commit parameter changes.",
	t4 = "Next object. Right click to commit parameter changes.",
	t5 = "Pick object in viewport and set it as active.",
	t6 = "Scale measured object units (not reflected in geometry).",
	t7 = "Compute sheet area use.",
	t8 = "Conversion factor for units."
	---- DEFAULT VALUES
	local vals_to_file = #("h","l","w","orientation","mat","part","description")
	----
	struct _props
	(
		obj,
		l,w,h,
		orientation,
		_name, part, description,
		mat
	)
	struct _gw
	(
		fn GW_text p txt RGBcolor:(color 8 180 150) =
		(
			if (p != undefined and txt != undefined) then (
				gw.setTransform (matrix3 1)
				local _p = gw.hTransPoint p
				gw.hText _p txt color:black
				local pr = gw.getTextExtent txt
				p1 = [_p.x,_p.y] - [2.5,0.0]
				p2 = pr + p1 + 5.0
				local bx = Box2 p1 p2
				gw.hRect bx RGBcolor
				gw.enlargeUpdateRect #whole  
				gw.updateScreen()
			)
		)
	)
	struct _cm
	(
		------------------------------------------------------------------------------------ Object checking
		fn check_obj obj = (if (obj != undefined) and (superClassOf obj == GeometryClass) then obj else undefined),
		fn getObjSelect =
		(
			local tmp = (selection as Array)
			local validObjs =
			if tmp[1] != undefined then (
				for i in tmp where (superClassOf i == GeometryClass) collect i
			) else undefined
		),
		fn selector objs indx: = 
		(
			for i in objs do (
				if isValidNode i then (
					if i.displayByLayer then i.displayByLayer = false
					i.boxmode = true
				)
			)
			if indx != unsupplied then objs[indx].boxmode = false
			objs[indx]	
		),
		fn unselector objs = 
		(
			if objs != undefined then (
				for i in objs do (
					if isValidNode i then (
						i.boxmode = false
					)
				)
			)
		),
		------------------------------------------------------------------------------------ Math functions
		fn CalculateVolumeAndCenterOfMass obj =
		(
			if (superclassof obj) == geometryclass then (
				local Volume= 0.0
				local Center= [0.0, 0.0, 0.0]
				local theMesh = snapshotasmesh obj
				local numFaces = theMesh.numfaces
				for i = 1 to numFaces do
				(
				  local Face= getFace theMesh i
				  local vert2 = getVert theMesh Face.z
				  local vert1 = getVert theMesh Face.y
				  local vert0 = getVert theMesh Face.x
				  local dV = Dot (Cross (vert1 - vert0) (vert2 - vert0)) vert0
				  Volume+= dV
				  Center+= (vert0 + vert1 + vert2) * dV
				)
				delete theMesh
				Volume /= 6
				Center /= 24
				Center /= Volume
				#(Volume,Center)
			) else #(undefined, undefined)
		),
		fn changeUnits _objs up:true factor:10.0 =
		(
			if _objs != undefined then (
				for o in _objs do (
					local h = getUserProp o "h"
					local l = getUserProp o "l"
					local w = getUserProp o "w"
					---
					if isKindOf h float then setUserProp o "h" (if up then h*factor else h/factor)
					if isKindOf l float then setUserProp o "l" (if up then l*factor else l/factor)
					if isKindOf w float then setUserProp o "w" (if up then w*factor else w/factor)
				)
			)
		),
		fn ReverseArray arr = (for i=arr.count to 1 by -1 collect arr[i]),
		fn sortMax arr1 arr2 maxtomin:true =
		(
			local first = arr1[1],
			second = arr2[1]
			if (isKindOf first float) and (isKindOf second float) then (
				case of (
					(first < second): if maxtomin then 1 else -1
					(first > second): if maxtomin then -1 else 1
					default:0
				)
			) else 0
		),
		fn getDims obj = 
		(
			if (obj != undefined) and (superClassOf obj == GeometryClass) then (
					local bbx = in coordsys local nodeLocalBoundingBox obj 
					local dim = bbx[2] - bbx[1]
					local coords = _cm.ReverseArray (sort #(dim.x, dim.y, dim.z))
			) else undefined
		),
		------------------------------------------------------------------------------------ userProps functions
		fn setUserProps obj getFrom =
		(
			try(
				local prop = getPropNames getFrom
				for i in prop do (
					local p = getProperty getFrom i
					if (getHashValue p 10) != undefined then (
						setUserProp obj (toLower (i as string) ) p
					)
				)
			) catch (displayTempPrompt (getCurrentException()) 6000 )		
		),
		------------------------------------------------------------------------------------ file functions
		fn saveFile str fname =
		(
			local fnArr = filterString fname  "*.*"
			try (
				local out_name = GetSaveFileName filename:fname types:("*."+fnArr[2])
				if out_name != undefined then (
					local out_file = createfile out_name
					format (str as String) to:out_file
					close out_file
				)
				return out_name
			) catch (return undefined)
		),
		------------------------------------------------------------------------------------ Save UserProps to file
		fn prop_str _objs caption: titles:"" vals:#("h","l","w","orientation","finish","part","description") =
		(
			if titles != unsupplied and vals != unsupplied then (
				-- rows
				local obj_v = #()
				for o in _objs do (
					local temp_v = for i=1 to vals.count collect
					(
						local v = getUserProp o vals[i]
						v = if v != undefined then v else "-"
					)
					append obj_v temp_v
				)
				-- sort array
				qsort obj_v _cm.sortMax
			--	/*
				-- add row number
				for i in obj_v do ( insertItem 1 i 1 )
				-- group similars
				local del_sim = deepCopy obj_v
				for i = del_sim.count to 2 by -1 do (
					if ( (del_sim[i][2] == del_sim[i-1][2]) and (del_sim[i][3] == del_sim[i-1][3]) ) and (del_sim[i][5] == del_sim[i-1][5]) then (
						del_sim[i-1][1] += del_sim[i][1]
						deleteItem del_sim i
					)
				)
				-- generate file
				local theFile = StringStream ""
				if caption != unsupplied do ( append theFile (caption + "\n") )
				append theFile titles
				for i in del_sim do (
					for f=1 to i.count do (
						if f < i.count then (
							format "\"%\"," i[f] to:theFile
						) else (
							format "\"%\"\n" i[f] to:theFile
						)
					)
				)
				free obj_v
				free del_sim
				theFile
			--	*/
			)
		)
	)
	fn PanelCuts = 
	(
		rollout roll_props r_title width:270
		(
				EditText txt_1 c_name fieldWidth:(roll_props.width - 20) readOnly:true align:#right labelOnTop:true
				EditText txt_2_1 c_h fieldWidth:180 readOnly:true align:#right
				EditText txt_2_2 c_l fieldWidth:180 readOnly:true align:#right
				EditText txt_2_3 c_w fieldWidth:180 readOnly:true align:#right
			imgTag sep3 width:(roll_props.width - 30) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) offset:[0,5] align:#center
			label lbl_sep1 "PROPERTIES" align:#center
				dropdownlist drp_1 l_o items:drp_itms
				checkBox ck_o1 c_ck_h checked:true across:2 align:#left enabled:false
				checkBox ck_o2 c_ck_l align:#left enabled:false
			imgTag sep2 width:(roll_props.width - 30) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) offset:[0,5] align:#center
				editText txt_m c_f fieldWidth:245 labelOnTop:true
				listbox lst_m "" height:3 width:245
				editText txt_3 c_t  fieldWidth:245 labelOnTop:true
				listbox lst_t height:5 width:245
				editText txt_4 c_d height:50 fieldWidth:245 labelOnTop:true
				button btn_1 str_ok height:30 width: 245 tooltip:t1
			imgTag sep4 width:(roll_props.width - 30) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) offset:[0,5] align:#center
			label lbl_sep2 "SELECT PARTS" align:#center
				button btn_p "<<" align:#left height:30 across:3 tooltip:t3
				button btn_sg c_ss height:30 width:170 tooltip:t2
				button btn_n ">>" height:30 align:#right tooltip:t4
				checkbutton btn_a "Viewport select" highlightColor:(color 80 120 30) height:25 width:240 align:#center offset:[0,10] tooltip:t5
			
			
			group "UTILITIES"
			(
				label lbl_sep4 "Scale Units" align:#left offset:[0,10]	
				imgTag sep6 width:(roll_props.width - 30) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) offset:[0,0] align:#center
					spinner spn_f "Factor:"  type:#float range:[1.0,1000000.0,10.0] width:150 align:#left across:2
					button btn_m1 sc_u width:80 align:#right tooltip:t6
					button btn_m2 sc_d width:80 align:#right tooltip:t6
					
				label lbl_sep5 "Sheet use" align:#left	
				imgTag sep7 width:(roll_props.width - 30) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) offset:[0,0] align:#center
					label l_dmns l_dm align:#left
					spinner spn_p1 "W:  "  type:#worldunits range:[1.0,1000000.0,183.0] fieldwidth:70 align:#right across:2
					spinner spn_p2 "H:  " type:#worldunits range:[1.0,1000000.0,260.0] fieldwidth:70 align:#right
					spinner spn_p3 "Waste %: " type:#float range:[1.0,100.0,20.0] fieldwidth:70  offset:[0,10] align:#right
					spinner spn_p4 "Unit conversion: " type:#float range:[1.0,100.0,1.0] fieldwidth:70  align:#right tooltip:t8
					button btn_p1 c_i width:240 height:25 align:#center offset:[0,10] tooltip:t7
				
				label lbl_sep6 "Save to file" align:#left	
				imgTag sep8 width:(roll_props.width - 30) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) offset:[0,0] align:#center
					editText txt_c c_c text:str_cap fieldwidth:240 labelonTop:true
					button btn_lst_s c_ps width:240 height:30 align:#center offset:[0,10]
					button btn_lst_a c_pa width:240 height:30 align:#center offset:[0,10]
			)
			------------------------------------------------------------------------------------ UI VALUES
			local dimTxt = #(txt_2_2, txt_2_1, txt_2_3)
			local propsTxt = #(txt_3, txt_4)
			------------------------------------------------------------------------------------ COMMON VALUES
			local props
			local obj
			local objs
			local index
			local tempSel
			local callbackItem
			local tempPoint, tempText
			------------------------------------------------------------------------------------ Graphic functions
			fn GW_txt_callback = (_gw.GW_text tempPoint tempText)
			------------------------------------------------------------------------------------ selection functions
			fn startSelector &item call = ( item = NodeEventCallback mouseup:true delay:1000 selectionChanged:call )
			fn stopSelector &item = ( item = undefined; gc light:true )
			------------------------------------------------------------------------------------
			-- rewrite
			fn getValues obj &props =
			(
				if (obj != undefined) and (superClassOf obj == GeometryClass) then (
					props.obj = obj.name
					local coords = _cm.getDims obj
					props.L = coords[2]; props.H = coords[1]; props.W = coords[3]
					
					props.orientation = getUserProp obj "orientation"
					props.part = getUserProp obj "part"
					props.description = getUserProp obj "description"
					props.mat = getUserProp obj "mat"
				)
			)
			fn setValues &props val: _props:#("_name","Lenght","Width","Height","Orient","Part","Description","mat") =
			(
				props.obj = _props[1]
				props.orientation = _props[5]
				props.part = _props[6]
				props.description = _props[7]
				props.mat = _props[8]
			)
			fn set_val_toObj obj objs _update_all:false =
			(
				if obj != undefined then (
					local d = #("V","H")
					if _update_all then (
						for i in objs do (
							getValues i &props	
							setValues &props _props:#(txt_1.text,"Lenght","Width","Height",d[drp_1.selection],txt_3.text ,txt_4.text,txt_m.text)
							_cm.setUserProps i props
						)
					) else (
						setValues &props _props:#(txt_1.text,"Lenght","Width","Height",d[drp_1.selection],txt_3.text ,txt_4.text,txt_m.text)
						_cm.setUserProps obj props
					)
				)
			)
			-- UI update
			fn loadToUI props = 
			(
				try (
					txt_1.text = props.obj
					txt_2_1.text = units.formatValue props.H
					txt_2_2.text = units.formatValue props.L
					txt_2_3.text = units.formatValue props.W
				) catch()
				
				if 	props.orientation == "V" then (
					drp_1.selection = 1
					ck_o1.checked = true; ck_o2.checked = false
				) else (
					drp_1.selection = 2
					ck_o1.checked = false; ck_o2.checked = true
				)
				ck_o1.caption = c_ck_h + ": " + txt_2_1.text
				ck_o2.caption = c_ck_l + ": " + txt_2_2.text

				txt_3.text = if props.part != undefined then (props.part as string) else ""
				txt_4.text = if props.description != undefined then (props.description as string) else ""
				txt_m.text = if props.mat != undefined then props.mat else ""
			)
			fn validate = ( getValues obj &props; loadToUI props )
			fn sel_shuffle &i _t _to:#up =
			(
				case _to of (
					#up:(if i < objs.count do i +=1)
					#down:(if i > 1 do i -=1)
				)
				_cm.selector objs indx:i
				obj = objs[i]
				validate()
				tempPoint = (_cm.CalculateVolumeAndCenterOfMass obj)[2]
				tempText = (props.l as string)+"x"+(props.h as string)+"x"+(props.w as string)
			)
			------------------------------------------------------------------------------------ selector Callback
			fn CallBackSel ev nd =
			(
				obj = _cm.check_obj (selection[1])
				if obj != undefined then validate()
				tempPoint = (_cm.CalculateVolumeAndCenterOfMass obj)[2]
				tempText = (props.l as string)+"x"+(props.h as string)+"x"+(props.w as string)
			)
			------------------------------------------------------------------------------------ EVENTS
			on roll_props open do ( props = _props() )
			on roll_props close do
			(
				if objs != undefined do ( _cm.unselector objs )
				unregisterRedrawViewsCallback GW_txt_callback
			)
			------------------------------------------------------------------------------------ objects selection
			on btn_sg pressed do
			(
				if objs != undefined do ( _cm.unselector objs )
				unregisterRedrawViewsCallback GW_txt_callback
				tempPoint = undefined
				btn_sg.caption = c_ss
				objs = _cm.getObjSelect()
				if objs != undefined do (
					index = 1
					btn_sg.caption = c_ss + "("+(objs.count as String)+")"
					_cm.selector objs indx:index
					obj = objs[index]
					validate()
					tempPoint = (_cm.CalculateVolumeAndCenterOfMass obj)[2]
					tempText = (props.l as string)+"x"+(props.h as string)+"x"+(props.w as string)
					registerRedrawViewsCallback GW_txt_callback
				)
			)
			------------------------------------------------------------------------------------ automatic selection
			on btn_a changed state do
			(
				if state then (
					registerRedrawViewsCallback GW_txt_callback
					startSelector &callbackItem CallBackSel
				) else (
					stopSelector &callbackItem
					unregisterRedrawViewsCallback GW_txt_callback
				)
			)
			------------------------------------------------------------------------------------
			on txt_m entered val do ( lst_m.items = append (lst_m.items) val )
			on lst_m selected itm do (txt_m.text = lst_m.items[itm])
			on txt_3 entered val do ( lst_t.items = append (lst_t.items) val )
			on lst_t selected itm do (txt_3.text = lst_t.items[itm])
			------------------------------------------------------------------------------------
			on drp_1 selected itm do
			(
				case itm of (
					1:(
						props.orientation = "V"
						local t = copy props.H
						props.H = props.L
						props.L = t
					)
					2:(
						props.orientation = "H"
						local t = copy props.L
						props.L = props.H
						props.H = t
					)
				)
				loadToUI props
			)
			------------------------------------------------------------------------------------
			on btn_n pressed do (
				sel_shuffle &index (objs.count) _to:#up
			)
			on btn_n rightclick do (
				set_val_toObj obj objs _update_all:false
				sel_shuffle &index (objs.count) _to:#up
			)
			-- update option
			on btn_p pressed do (
				sel_shuffle &index (objs.count) _to:#down
			)
			on btn_p rightclick do (
				set_val_toObj obj objs _update_all:false
				sel_shuffle &index (objs.count) _to:#down
			)
			------------------------------------------------------------------------------------ establece valores
			on btn_1 pressed do (
				set_val_toObj obj objs _update_all:false
			)
			-- apply to all
			on btn_1 rightclick do (
				set_val_toObj obj objs _update_all:true
			)
			------------------------------------------------------------------------------------ Save to file
			on btn_lst_s pressed do
			(
				if objs != undefined then (
					local the_caption = (if txt_c.text != "" then txt_c.text else unsupplied)
					local f = _cm.prop_str objs caption:the_caption titles:str_titles_2 vals:vals_to_file
					if f != "" do _cm.saveFile f ("cuts_"+(txt_c.text)+".csv")
					free f
					dispose 
				)
			)
			on btn_lst_a pressed do
			(
				local
				the_objs = objects,
				objs_count = the_objs.count,
				temp_nodelist = #()
				for i=1 to objs_count do (
					local temp_node = the_objs[i]
					if isValidNode temp_node then (
						if getUserProp temp_node "obj" != undefined then (
							append temp_nodelist temp_node
						)
					)
				)
				if temp_nodelist != #() then (
					local the_caption = (if txt_c.text != "" then txt_c.text else unsupplied)
					local f = _cm.prop_str temp_nodelist caption:the_caption titles:str_titles_2 vals:vals_to_file
					if f != "" do _cm.saveFile f ("cuts_"+(txt_c.text)+".csv")
					free f
					dispose 
				)
			)
			------------------------------------------------------------------------------------ report
			on btn_p1 pressed do (
				local p_area =  spn_p4.value * (spn_p1.value * spn_p2.value )
				local o_area = 0.0
				if objs != undefined then (
					for i in objs do (
						local coords = _cm.getDims i
						local a = coords[2] * coords[1]
						o_area += a
					)
				) else if obj != undefined then (
					local coords = _cm.getDims obj
					o_area = coords[2] * coords[1]
				)
				if o_area > 0.0 then (
					local d = spn_p3.value / 100 
					local c_sheet = (o_area / p_area) + (d * o_area) / p_area
					--	(o_area / p_area) + ( (o_area / p_area) * (spn_p3.value /100 ))
					local str = StringStream ""
					format "% %\% %:-------------------- % u." strf_p1 (spn_p3.value) strf_p2 c_sheet to:str
					messageBox str
				)
			)
			------------------------------------------------------------------------------------ change units
			on btn_m1 pressed do
			(
				local st = "" as stringStream
				format str_q1 (spn_f.value) to:st
				if (queryBox st) then (
					_cm.changeUnits objs factor:spn_f.value
				)
			)
			on btn_m2 pressed do
			(
				local st = "" as stringStream
				format str_q2 (spn_f.value) to:st
				if (queryBox st) then (
					_cm.changeUnits objs factor:spn_f.value up:false
				)
			)
		)
		m_props = newRolloutFloater r_title 280 950
		addRollout roll_props m_props border:true
		m_props.pos = [100,20]
		cui.RegisterDialogBar m_props  style:#(#cui_dock_vert,#cui_floatable) parent:(Windows.GetMAXHWND()) minsize:[295,600] maxsize:[295,960]
	)
	PanelCuts()
)