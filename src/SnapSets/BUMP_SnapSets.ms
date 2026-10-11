/**
*	-------------------------------------------------------------------------------------------
*	DesignToolBox - SNAPS MANAGER TOOL
*	02-2021 separated module
*	-------------------------------------------------------------------------------------------
*/
(
    struct comboSnap
	(
		private
		CFG_FILE = pathConfig.appendPath (getDir #plugcfg) "destoolbx.ini",
		CAT = "utils csnap",

		fn get_active_snaps =
		(
			local active_snaps = #()
			for i = 1 to snapmode.numOSnaps do (
				for j = 1 to (snapmode.getOSnapNumItems i) where (snapmode.getOSnapItemActive i j) do (
					append active_snaps #(i,j)
				)
			)
			active_snaps
		),
		fn set_active_state _p =
		(
			if (isKindOf _p Array) then (
				for a=1 to snapmode.numOSnaps do
				(
					for b = 1 to (snapmode.getOSnapNumItems a) do (snapmode.setOSnapItemActive a b false)
				)
				for i in _p do (snapMode.setOSnapItemActive i[1] i[2] true)
			)
		),
		fn list_saved_snaps _sn =
		(
			for i in _sn collect (
				(snapmode.getOSnapName i[1]) + " > " + (snapmode.getOSnapItemName i[1] i[2])
			)
		),
		fn load_sets =
		(
			local ls = getINISetting CFG_FILE CAT
			if ls != "" then ls else undefined

		),
		fn load_setVal setname =
		(
			execute (getINISetting CFG_FILE CAT setname)
		),
		fn save_sets id curr =
		(
			if (id != undefined) AND (curr != undefined) then (
				setINISetting CFG_FILE CAT id (curr as string) forceUTF16:true
				true
			) else false
		),
		fn rem_Set id =
		(
			if (hasINISetting CFG_FILE CAT id) then (
				delIniSetting CFG_FILE CAT id
				true
			) else false
		),
		fn genBgnd w h b =
		(
			-- ui colors
			local			
			col_1 = ((colorMan.getColor #shadow) * 255.0) as color,
			col_2 = ((colorMan.getColor #background) * 255.0) as color,
			gammavalue = 1.0,
			colorSpaceVal = unsupplied
			
			if ColorPipelineMgr != undefined then (
				gammavalue = 1.0 / ColorPipelineMgr.DisplayGamma
				if ColorPipelineMgr.Mode != #unmanaged then colorSpaceVal = "sRGB"
			) else if IDisplayGamma != undefined then (
				gammavalue = 1.0 / IDisplayGamma.gamma
			)
			
			local
			bmp1  = bitmap w h color:col_1 gamma:gammavalue colorSpace:colorSpaceVal,
			bmp2  = bitmap w h color:col_2
			
			pastebitmap bmp2 bmp1 ( box2 0 0 (w - b * 2) (h - b * 2) ) [b, b] type:#paste
			bmp1
		),
		fn dividerImage setColor: =
		(
			local col_1 = if isKindOf setColor color then setColor else ((colorMan.getColor #shadow) * 255.0) as color
			local
			gammavalue = 1.0,
			colorSpaceVal = unsupplied

			if ColorPipelineMgr != undefined then (
				gammavalue = 1.0 / ColorPipelineMgr.DisplayGamma
				if ColorPipelineMgr.Mode != #unmanaged then colorSpaceVal = "sRGB"
			) else if IDisplayGamma != undefined then (
				gammavalue = 1.0 / IDisplayGamma.gamma
			)
			-- return 1x1 bitmap
			bitmap 1 1 color:col_1 gamma:gammavalue colorSpace:colorSpaceVal
		),
		fn sets_ui =
		(
			rollout roll_snap_sets ""
			(
				local owner = if owner != undefined then owner

				imgTag sep1 width:3 height:28 pos:[1,1] across:4
				dropdownlist lst_snp items:#() width:120 align:#left offset:[-40,0]
				checkbutton btn_cfg "" width:20 height:20 align:#right offset:[25,0] border:off \
					iconName:"DesignToolBox/ok" iconSize:[20,20]
				button btn_close "" width:20 height:20 align:#right offset:[10,0] border:off \
					iconName:"DesignToolBox/Delete" iconSize:[20,20]

				group "Stored Snap combos"
				(
					listbox lst_1 "" items:#()
					edittext txt_1 "" labelOnTop:true
					button btn_add "ADD CURRENT" across:2 height:30 align:#left
					button btn_rem "REMOVE" height:30 align:#right
				)
				group "Temp. Memory"
				(
					button btn_sav "Save current state" width:120
					button btn_rest "Restore State" width:120
				)
				button btn_o "SNAP SETTINGS" width:180 height:20 align:#center
				---------------------------------------------------------------------------------------
				local prev_pos = [10,10]
				local SDrag = false
				fn reload_sets = lst_snp.Items = owner.load_sets()
				local temp_state
				---------------------------------------------------------------------------------------
				on roll_snap_sets open do
				(
					sep1.bitmap = owner.dividerImage setColor:(color 177 88 27)
					reload_sets()
					lst_1.Items = owner.load_sets()
				)
				on roll_snap_sets close do ( updateToolbarButtons() )
				---------------------------------------------------------------------------------------
				on roll_snap_sets lbuttondown p do (sDrag = true; prev_pos = p )
				on roll_snap_sets mouseMove p do (if sDrag then (SetDialogPos roll_snap_sets (mouse.screenpos - prev_pos)))
				on roll_snap_sets lbuttonup p do sDrag = false
				on btn_close pressed do ( try (DestroyDialog roll_snap_sets) catch () )
				on btn_cfg changed state  do (
					if state then (roll_snap_sets.height = 360) else (roll_snap_sets.height = 30)
				)
				on lst_snp selected itm do
				(
					if (itm >= 1) AND (lst_snp.items != #() ) then (
						local curr_set = owner.load_setVal (lst_snp.items[itm])
						owner.set_active_state curr_set
					)
				)
				------------------------------------------------------------------------------------------
				on btn_o pressed do OSnap()
				on lst_1 doubleClicked itm do
				(
					local saved_state = owner.load_setVal (lst_1.items[itm])
					if saved_state != undefined then (
						local tmp = lst_1.items
						local curr_snp = owner.list_saved_snaps saved_state
						local rci = rolloutCreator "roll_Ssnaps" (tmp[itm])
						rci.begin()
						for i=1 to curr_snp.count do (
							rci.addControl "label" ("lbl_" + i as string) curr_snp[i] paramStr:"align:#left"
						)
						createDialog (rci.end()) modal:true
					)
				)
				on lst_1 selected itm do
				(
					txt_1.text = (lst_1.items[itm])
					local saved_state = owner.load_setVal (lst_1.items[itm])
					if saved_state != undefined then (owner.set_active_state saved_state)
				)
				on btn_add pressed do
				(
					if txt_1.text != "" then (
						local curr = owner.get_active_snaps()
						local id = txt_1.text
						local op = owner.save_sets id curr
						if op then (
							local tmp = lst_1.items
							append tmp id
							lst_1.items = tmp
							reload_sets()
						)
					) else (messageBox "Please type a Name")
				)
				on btn_rem pressed do
				(
					if (lst_1.selection) >= 1 then (
						local tmp = lst_1.items
						local curr = lst_1.selection
						local op = owner.rem_Set tmp[curr]
						if op then
						(
							deleteItem tmp (lst_1.selection)
							lst_1.items = tmp
						)
					)
				)
				on btn_sav pressed do
				(
					temp_state = owner.get_active_snaps()
				)
				on btn_rest pressed do
				(
					if temp_state != undefined then (owner.set_active_state temp_state)
				)

			)
			-- roll_snap_sets.owner = this
			roll_snap_sets
		),
		public
		roll_snap_sets,

		fn show_ui =
		(
			if roll_snap_sets == undefined then (
				this.roll_snap_sets = sets_ui()
				roll_snap_sets.owner = this
			)
			if NOT roll_snap_sets.open then (
				createDialog roll_snap_sets pos:[80,220] width:190 height:30 style:#() bitmap:(genBgnd 190 360 2)
			)
			roll_snap_sets
		),
		fn close_ui =
		(
			if roll_snap_sets != undefined then (
				try (DestroyDialog roll_snap_sets) catch ()
			)
			false
		)
	)
	comboSnap()
	--- DEBUG ---
-- 	t = comboSnap()
-- 	t.show_ui()
)