	dstlbxMenu = menu_man.generate_menu "DesignToolBox" classid:0x6cc645b8
	if dstlbxMenu != undefined then (
		--------- refGuides
		menu_man.item_create_add dstlbxMenu "BUMP_refGuides_noUI_free_cont"  "BUMP refGuides" title:"Reference guide - free space"
		menu_man.item_create_add dstlbxMenu "BUMP_refGuides_noUI_ortho_cont" "BUMP refGuides" title:"Reference guide - orhtogonal"
		menu_man.item_create_add dstlbxMenu "BUMP_refGuides_noUI_polar_cont" "BUMP refGuides" title:"Reference guide - polar"
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "BUMP_refGuides_Li2"    "BUMP refGuides" title:"Display ref. guides units"
		menu_man.item_create_add dstlbxMenu "BUMP_refGuides_delete" "BUMP refGuides" title:"Delete all reference objects"
		menu_man.menu_separator dstlbxMenu
		---------
		local Rg_mnu = menu_man.item_submenu_create "refGuides tools"
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_prot_free"  "BUMP refGuides" title:"Reference protractor - free space"
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_prot_ortho" "BUMP refGuides" title:"Reference protractor - orthogonal"
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_prot_polar" "BUMP refGuides" title:"Reference protractor - polar"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_UI_free"  "BUMP refGuides" title:"Reference guide - free space - UI"
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_UI_ortho" "BUMP refGuides" title:"Reference guide - orthogonal - UI"
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_UI_polar" "BUMP refGuides" title:"Reference guide - polar - UI"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add  Rg_mnu "rG_ribbon_intPoints" "BUMP refGuides" title:"Enlable intersection points"
			menu_man.item_create_add Rg_mnu "rG_ribbon_Prot"      "BUMP refGuides" title:"Enable protractor creation"
			menu_man.item_create_add Rg_mnu "rG_ribbon_LkGuides"  "BUMP refGuides" title:"Lock reference objects"
			menu_man.item_create_add Rg_mnu "rG_ribbon_pGrid"     "BUMP refGuides" title:"Enable working grid from polar"
			menu_man.item_create_add Rg_mnu "rG_ribbon_IntMode"   "BUMP refGuides" title:"Intersection points - All vs Current"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add Rg_mnu "BUMP_refGuides_Li"  "BUMP refGuides" title:"Display units for selected guide"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add Rg_mnu "BUMP_HGScale"   "BUMP refGuides" title:"Display Home Grid units"
			menu_man.item_create_add Rg_mnu "BUMP_infotool"  "BUMP refGuides" title:"Spatial Info tool"
			menu_man.item_create_add Rg_mnu "BUMP_Zpos"      "BUMP refGuides" title:"Node Z position Info tool"
		menu_man.menu_add_submenu dstlbxMenu Rg_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Transform
		menu_man.item_create_add dstlbxMenu "BUMP_Lrotator"         "BUMP DesignToolbox" title:"Rotation - local reference"
		menu_man.item_create_add dstlbxMenu "BUMP_rotator"          "BUMP DesignToolbox" title:"Rotation - 3 axis mode"
		menu_man.item_create_add dstlbxMenu "BUMP_scale"            "BUMP DesignToolbox" title:"Reference scale"
		menu_man.item_create_add dstlbxMenu "BUMP_scale_distance"   "BUMP DesignToolbox" title:"Scale by dimension"
		menu_man.item_create_add dstlbxMenu "BUMP_offset"           "BUMP DesignToolbox" title:"Adv. Position Offset"
		menu_man.menu_separator dstlbxMenu
		---------
		local Tr_mnu = menu_man.item_submenu_create "Transform tools"
			menu_man.item_create_add Tr_mnu "BUMP_scale_xform"          "BUMP DesignToolbox" title:"Reference scale - xForm mod."
			menu_man.item_create_add Tr_mnu "BUMP_moveAround"           "BUMP DesignToolbox" title:"Move around and clone"
			menu_man.item_create_add Tr_mnu "BUMP_rndTrs"               "BUMP tools" title:"Random transform"
		menu_man.menu_add_submenu dstlbxMenu Tr_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Measure
		menu_man.item_create_add dstlbxMenu "BUMP_Qmeasure"         "BUMP DesignToolbox" title:"Measure units"
		menu_man.item_create_add dstlbxMenu "BUMP_Qmeasure_mult"    "BUMP DesignToolbox" title:"Chain measure"
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "BUMP_Divider"          "BUMP DesignToolbox" title:"Distance divider"
		menu_man.menu_separator dstlbxMenu
		---------
		local Ms_mnu = menu_man.item_submenu_create "Measure tools"
			menu_man.item_create_add Ms_mnu "BUMP_Qangle"           "BUMP DesignToolbox" title:"Angle measure"
			menu_man.item_create_add Ms_mnu "BUMP_Qarea"            "BUMP DesignToolbox" title:"2D Area measure"
			menu_man.item_create_add Ms_mnu "BUMP_Qvolume"          "BUMP DesignToolbox" title:"Cubic volume"
			menu_man.menu_separator Ms_mnu
			menu_man.item_create_add Ms_mnu "BUMP_clonebtwn"        "BUMP DesignToolbox" title:"Clone between"
			menu_man.item_create_add Ms_mnu "BUMP_Divider_imput"    "BUMP DesignToolbox" title:"Distance divider - imput"
		menu_man.menu_add_submenu dstlbxMenu Ms_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "BUMP_distListener"     "BUMP DesignToolbox" title:"Measure listener"
		menu_man.menu_separator dstlbxMenu
		--------- Eyedropper
		menu_man.item_create_add dstlbxMenu "BUMP_replicator" "BUMP DesignToolbox" title:"Replicator"
		menu_man.item_create_add dstlbxMenu "BUMP_edrpAll"    "BUMP DesignToolbox" title:"Eyedropper"
		menu_man.item_create_add dstlbxMenu "BUMP_edrp_flt"   "BUMP DesignToolbox" title:"Eyedropper filters"
		menu_man.menu_separator dstlbxMenu
		---------
		local Rep_mnu = menu_man.item_submenu_create "Replicators"
			menu_man.item_create_add Rep_mnu "BUMP_edrpTr"     "BUMP DesignToolbox" title:"Eyedropper - Transform"
			menu_man.item_create_add Rep_mnu "BUMP_edrpMt"     "BUMP DesignToolbox" title:"Eyedropper - Material"
			menu_man.item_create_add Rep_mnu "BUMP_edrpMd"     "BUMP DesignToolbox" title:"Eyedropper - Modifiers"
			menu_man.item_create_add Rep_mnu "BUMP_edrpUV"     "BUMP DesignToolbox" title:"Eyedropper - UVW data or modifiers"
			menu_man.item_create_add Rep_mnu "BUMP_edrpVis"    "BUMP DesignToolbox" title:"Eyedropper - Visual properties"
			menu_man.menu_separator Rep_mnu
			menu_man.item_create_add Rep_mnu "BUMP_rep_mt"     "BUMP DesignToolbox" title:"Replicator - multi target"
			menu_man.item_create_add Rep_mnu "BUMP_rep_grp"    "BUMP DesignToolbox" title:"Replicator - group replace mode"
			menu_man.item_create_add Rep_mnu "BUMP_rep_tm"     "BUMP DesignToolbox" title:"Replicate transform"
			menu_man.item_create_add Rep_mnu "BUMP_rep_inst"   "BUMP DesignToolbox" title:"Propagate instances"
			menu_man.item_create_add Rep_mnu "BUMP_edrp_mt"    "BUMP DesignToolbox" title:"Eyedropper - multi target"
		menu_man.menu_add_submenu dstlbxMenu Rep_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Tools
		menu_man.item_create_add dstlbxMenu "BUMP_PARR" "BUMP DesignToolbox" title:"Patern array"
		menu_man.item_create_add dstlbxMenu "BUMP_IARR" "BUMP DesignToolbox" title:"3D Array"
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "BUMP_unhider"    "BUMP DesignToolbox" title:"Unhide by selection"
		menu_man.item_create_add dstlbxMenu "BUMP_unfrozer"   "BUMP DesignToolbox" title:"Unfreeze by selection"
		menu_man.item_create_add dstlbxMenu "BUMP_refIsolate" "BUMP DesignToolbox" title:"Local coords. Isolation"
		menu_man.menu_separator dstlbxMenu
		--------- Pivot
		local Pivot_mnu = menu_man.item_submenu_create "Pivot tools"
			menu_man.item_create_add Pivot_mnu "BUMP_QPVT"      "BUMP DesignToolbox" title:"Quick pivot UI"
			menu_man.menu_separator Pivot_mnu
			-- menu_man.item_create_add Pivot_mnu "BUMP_QPVT_pnt"  "BUMP DesignToolbox" title:"Pivot to point"
			menu_man.item_create_add Pivot_mnu "BUMP_QPVT_btn"  "BUMP DesignToolbox" title:"Pivot to bottom"
			menu_man.item_create_add Pivot_mnu "BUMP_QPVT_3p"   "BUMP DesignToolbox" title:"Pivot from 3 points"
			menu_man.item_create_add Pivot_mnu "BUMP_QPVT_3pWP" "BUMP DesignToolbox" title:"Working pivot from 3 points"
			menu_man.item_create_add Pivot_mnu "BUMP_QPVT_sf"   "BUMP DesignToolbox" title:"Pivot from selected faces"
		menu_man.menu_add_submenu dstlbxMenu Pivot_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Objects
		menu_man.item_create_add dstlbxMenu "BUMP_PN"     "BUMP DesignToolbox" title:"Paneling tool"
		menu_man.item_create_add dstlbxMenu "BUMP_MMap"   "BUMP DesignToolbox" title:"UVW map tool"
		---------
		local Util_mnu = menu_man.item_submenu_create "Utilities"
			menu_man.item_create_add Util_mnu "BUMP_PNDT"     "BUMP DesignToolbox" title:"Add details tool"
			menu_man.item_create_add Util_mnu "BUMP_mapTools" "BUMP DesignToolbox" title:"UVW gizmo tools"
			menu_man.item_create_add Util_mnu "BUMP_snapSets" "BUMP tools" title:"Save snap states"
			menu_man.item_create_add Util_mnu "BUMP_cclp"     "BUMP tools" title:"Color clipboard"
			menu_man.item_create_add Util_mnu "BUMP_rndTrs"   "BUMP tools" title:"Random Transformations"
		menu_man.menu_add_submenu dstlbxMenu Util_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		---------
		local Lks_mnu = menu_man.item_submenu_create "Transform locks"
			menu_man.item_create_add Lks_mnu "BUMP_Locks_all"   "BUMP DesignToolbox" title:"Lock All"
			menu_man.item_create_add Lks_mnu "BUMP_Locks_pos"   "BUMP DesignToolbox" title:"Lock position"
			menu_man.item_create_add Lks_mnu "BUMP_Locks_rot"   "BUMP DesignToolbox" title:"Lock rotation"
			menu_man.item_create_add Lks_mnu "BUMP_Locks_scale" "BUMP DesignToolbox" title:"Lock scale"
		menu_man.menu_add_submenu dstlbxMenu Lks_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Layers
		local Layers_mnu = menu_man.item_submenu_create "Layer tools"
			menu_man.item_create_add Layers_mnu "BUMP_layIso"   "BUMP DesignToolbox" title:"Isolate layer"
			menu_man.menu_separator Layers_mnu
			menu_man.item_create_add Layers_mnu "BUMP_layProp1" "BUMP DesignToolbox" title:"Layer lock"
			menu_man.item_create_add Layers_mnu "BUMP_layProp2" "BUMP DesignToolbox" title:"layer ON/OFF"
			menu_man.item_create_add Layers_mnu "BUMP_layProp3" "BUMP DesignToolbox" title:"Layer box mode"
			menu_man.item_create_add Layers_mnu "BUMP_layProp4" "BUMP DesignToolbox" title:"Layer backface cull"
		menu_man.menu_add_submenu dstlbxMenu Layers_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		----------
		local cfg_mnu = menu_man.item_submenu_create "Configuration"
			menu_man.item_create_add cfg_mnu "BUMP_cfg"              "BUMP DesignToolbox" title:"DesignToolBox settings"
			menu_man.item_create_add cfg_mnu "BUMP_refGuides_config" "BUMP refGuides" title:"refGuides settings"
		menu_man.menu_add_submenu dstlbxMenu cfg_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		---------
		local help_mnu = menu_man.item_submenu_create "Help"
			menu_man.item_create_add help_mnu "DTLBX_ACT" "BUMP DesignToolbox"
			menu_man.item_create_add help_mnu "DTLBX_DOCS" "BUMP DesignToolbox"
			menu_man.item_create_add help_mnu "DTLBX_ABOUT" "BUMP DesignToolbox"
		menu_man.menu_add_submenu dstlbxMenu help_mnu
		---------
		--	*/

		/*
		local flt_mnu = menuMan.createMenu "UI Floaters"
		create_add flt_mnu "BUMP_rG_fltUI"         "BUMP refGuides" title:"refGuides floater"
		create_add flt_mnu "BUMP_dS_fltUI"         "BUMP DesignToolbox" title:"DesignToolBox floater"
		add_mnu dstlbxMenu ( menuMan.createSubMenuItem "UI Floaters" flt_mnu)
		*/
		-------------------------------------
		-- redraw the menu bar with the new item
		menuMan.updateMenuBar()
	)
