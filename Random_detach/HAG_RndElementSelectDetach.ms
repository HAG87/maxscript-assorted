/*
------------------------------------------------------------------------------------------------------------------------
RANDOM ELEMENTS SELECTOR
------------------------------------------------------------------------------------------------------------------------
Author: HAG 2014
Version: 1.4
Date: 07-03-2014
Tested on: 3D Max 2014
*/
(	
	struct Detach (_node,_poly,_selection,_faces)
	local _detach = Detach()
	local returnElems, flattenArr, EleRandomizer, EleDetacher, setSelection
	try(destroyDialog roll_rndElem; cui.UnRegisterDialogBar roll_rndElem)catch()
	global roll_rndElem, _dock
	rollout roll_rndElem "Random Elements Select/Detach" width:90 height:366
	(
		button btn_c "CLOSE" width:90 height:20 pos:[0,0] align:#center
		GroupBox grp_1 "" width:90 height:5 pos:[0,20] align:#center
		label lbl_so "Select Objects" align:#center width:70 height:15
		fn pick_filter obj= (classOf obj==Editable_Poly)
		pickbutton pk_obj "Pick Poly"  width:85 align:#center filter:pick_filter autoDisplay: true
		checkbutton chb_copy "Copy Src" width:85  align:#center highlightColor:(color 28 89 177)
		group "options"
		(
			label lbl_s "Seed" align:#left
			spinner spn_Seed "" width:70 align:#center range:[0,1000,150]
			label lbl_p "Percent" align:#left 
			spinner spn_Percent "" width:70 height:16 align:#center range:[0,100,50]
			label lbl_id "Mat ID's" align:#left
			spinner spn_ID "" width:70 height:16 align:#center range:[0,100,1] type:#integer
		)
		button btn_Select "Select" width:85 height:40 align:#center
		button btn_Detach "Detach" width:85 height:25 align:#center offset:[0,5]
		button btn_DetachAll "Detach Unique" width:85 height:25 align:#center
		progressBar br_p value:0 color:(color 246 151 27) Width:90 height:6 pos:[0,360]align:#center
		local prev_pos=[10,10]
		local SDrag=false
		fn updateUI obj: =(
				roll_rndElem.lbl_so.caption= if obj!= unsupplied then "Selected" else "Select Object"
				for i=1 to roll_rndElem.controls.count do (if i>4 then roll_rndElem.controls[i].enabled=(if obj== unsupplied then false else true))
		)
		on roll_rndElem open do updateUI()
		on roll_rndElem lbuttondown p do (sDrag=true; prev_pos=p)
		on roll_rndElem mouseMove p do (print p; if sDrag==true then (try(SetDialogPos roll_rndElem (mouse.screenpos-prev_pos))catch()))
		on roll_rndElem lbuttonup p do sDrag=false
		on pk_obj picked obj do updateUI obj:obj
		on btn_c pressed do (if roll_rndElem.dialogBar==true then (cui.UnRegisterDialogBar roll_rndElem; destroyDialog roll_rndElem) else destroyDialog roll_rndElem)
		on btn_c rightclick do	(popUpMenu _dock rollout:roll_rndElem)
		on btn_Select pressed do  setSelection sel: roll_rndElem.pk_obj.object
		on btn_Detach pressed do (if _detach._node!=undefined then  EleDetacher _detach._node _detach._poly _detach._selection _detach._faces roll_rndElem.spn_ID.value unit:false)
		on btn_DetachAll pressed do (if _detach._node!=undefined then EleDetacher _detach._node _detach._poly _detach._selection _detach._faces roll_rndElem.spn_ID.value unit:true) 
	)--End Rollout
	rcmenu _dock
	(
		menuitem rc_dl "Dock Left"
		menuitem rc_dr "Dock Right"
		separator b	
		menuitem rc_ud "Undock"
		on rc_dl picked do(
			if roll_rndElem.dialogBar==true then(
				cui.DockDialogBar roll_rndElem #cui_dock_left
				)else(
				cui.RegisterDialogBar roll_rndElem style:#(#cui_dock_vert,#cui_floatable)
				cui.DockDialogBar roll_rndElem #cui_dock_left	
			)
		)
		on rc_dr picked do(
			if roll_rndElem.dialogBar==true then(
				cui.DockDialogBar roll_rndElem #cui_dock_right
				)else(
				cui.RegisterDialogBar roll_rndElem style:#(#cui_dock_vert,#cui_floatable)
				cui.DockDialogBar roll_rndElem #cui_dock_right	
			)
		)	
		on rc_ud picked do(if roll_rndElem.dialogBar==true then cui.UnRegisterDialogBar roll_rndElem)
	)--End RC
	fn progress val: tot: =(
		if val!=unsupplied and tot!=unsupplied then roll_rndElem.br_p.value= ((val*100)/tot)	else  roll_rndElem.br_p.value=0
	)
	fn flattenArr arr=(
			local tempArr=#()
			for i in arr do join tempArr i
			tempArr
	)
	fn returnElems obj=(
		try(
			local num_faces=polyop.getNumFaces obj
			local elem_arr=#()
			local done=#()
				for f=1 to num_faces do(
					if (findItem done f)==0 then (
						local faces= (polyop.getElementsUsingFace obj f) as BitArray
						append elem_arr faces
						join done faces
						progress val:f tot:num_faces
					)
				)
			progress()
			free done 
		)catch(return undefined)
		elem_arr
	)
	
	fn EleRandomizer obj eles delta: dSeed: sel:false =(
		if eles.count>1 then(
			if dSeed==unsupplied then (dSeed= eles.count)
			seed dSeed	
			local rands=#()		
			local umbral = if delta <1 or delta!=unsupplied then floor(eles.count*delta) else eles.count
			for r=1 to umbral do(
				local rnd=floor(random 1.0 eles.count)
				if (findItem rands eles[rnd])==0 then(
					append rands eles[rnd]
					progress val:r tot:umbral
				)
			)
			progress()
		)else rands=eles
		local flat=(flattenArr rands)
		_detach._faces=flat
		polyop.setFaceSelection obj #none
		polyop.setFaceSelection obj (flat as BitArray)
		if sel==true then (
			max modify mode
			modPanel.setCurrentObject obj
			subobjectlevel = 4
			return rands	
		)else return rands
	)
	fn EleDetacher nod obj eles faces rID unit:true =(
		if eles.count==1 and not (queryBox "WARING! Only one element selected, do you want to continue?") then return undefined
		case unit of (
			true:( 
				undo on(
					for i=1 to eles.count do(
						polyop.setFaceMatID obj eles[i] (floor(random 1 rID))
						polyop.detachFaces obj eles[i] name: (uniqueName "Elem_") delete:false asNode:true node:nod
						progress val:1 	tot:eles.count
					)
					polyop.deleteFaces obj faces
					progress()
				)
			)			
			false:(
				undo on (polyop.detachFaces obj (faces as BitArray) name:(uniqueName "Elem_") asNode:true node:nod)	
			)
		)
	)
	fn setSelection sel: =(
		if classOf sel.baseobject==Editable_poly then(
			if roll_rndElem.chb_copy.checked==true then copy sel
			_detach._node= sel
			_detach._poly= _detach._node.baseobject
			_detach._selection= EleRandomizer _detach._poly (returnElems _detach._poly) delta:((roll_rndElem.spn_Percent.value/100)) dSeed: roll_rndElem.spn_Seed.value sel:true
		return true
		)else return false
	)
	createdialog roll_rndElem pos:[100,200] style:#()
)--END OF SCRIPT