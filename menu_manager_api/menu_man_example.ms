	dstlbxMenu = menu_man.generate_menu "DesignToolBox" classid:0x6cc645b8
	if dstlbxMenu != undefined then (
		--------- refGuides
		menu_man.item_create_add dstlbxMenu "HAG_refGuides_noUI_free_cont"  "HAG refGuides" title:"Reference guide - free space"
		menu_man.item_create_add dstlbxMenu "HAG_refGuides_noUI_ortho_cont" "HAG refGuides" title:"Reference guide - orhtogonal"
		menu_man.item_create_add dstlbxMenu "HAG_refGuides_noUI_polar_cont" "HAG refGuides" title:"Reference guide - polar"
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "HAG_refGuides_Li2"    "HAG refGuides" title:"Display ref. guides units"
		menu_man.item_create_add dstlbxMenu "HAG_refGuides_delete" "HAG refGuides" title:"Delete all reference objects"
		menu_man.menu_separator dstlbxMenu
		---------
		local Rg_mnu = menu_man.item_submenu_create "refGuides tools"
			menu_man.item_create_add Rg_mnu "HAG_refGuides_prot_free"  "HAG refGuides" title:"Reference protractor - free space"
			menu_man.item_create_add Rg_mnu "HAG_refGuides_prot_ortho" "HAG refGuides" title:"Reference protractor - orthogonal"
			menu_man.item_create_add Rg_mnu "HAG_refGuides_prot_polar" "HAG refGuides" title:"Reference protractor - polar"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add Rg_mnu "HAG_refGuides_UI_free"  "HAG refGuides" title:"Reference guide - free space - UI"
			menu_man.item_create_add Rg_mnu "HAG_refGuides_UI_ortho" "HAG refGuides" title:"Reference guide - orthogonal - UI"
			menu_man.item_create_add Rg_mnu "HAG_refGuides_UI_polar" "HAG refGuides" title:"Reference guide - polar - UI"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add  Rg_mnu "rG_ribbon_intPoints" "HAG refGuides" title:"Enlable intersection points"
			menu_man.item_create_add Rg_mnu "rG_ribbon_Prot"      "HAG refGuides" title:"Enable protractor creation"
			menu_man.item_create_add Rg_mnu "rG_ribbon_LkGuides"  "HAG refGuides" title:"Lock reference objects"
			menu_man.item_create_add Rg_mnu "rG_ribbon_pGrid"     "HAG refGuides" title:"Enable working grid from polar"
			menu_man.item_create_add Rg_mnu "rG_ribbon_IntMode"   "HAG refGuides" title:"Intersection points - All vs Current"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add Rg_mnu "HAG_refGuides_Li"  "HAG refGuides" title:"Display units for selected guide"
			menu_man.menu_separator Rg_mnu
			menu_man.item_create_add Rg_mnu "HAG_HGScale"   "HAG refGuides" title:"Display Home Grid units"
			menu_man.item_create_add Rg_mnu "HAG_infotool"  "HAG refGuides" title:"Spatial Info tool"
			menu_man.item_create_add Rg_mnu "HAG_Zpos"      "HAG refGuides" title:"Node Z position Info tool"
		menu_man.menu_add_submenu dstlbxMenu Rg_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Transform
		menu_man.item_create_add dstlbxMenu "HAG_Lrotator"         "HAG DesignToolbox" title:"Rotation - local reference"
		menu_man.item_create_add dstlbxMenu "HAG_rotator"          "HAG DesignToolbox" title:"Rotation - 3 axis mode"
		menu_man.item_create_add dstlbxMenu "HAG_scale"            "HAG DesignToolbox" title:"Reference scale"
		menu_man.item_create_add dstlbxMenu "HAG_scale_distance"   "HAG DesignToolbox" title:"Scale by dimension"
		menu_man.item_create_add dstlbxMenu "HAG_offset"           "HAG DesignToolbox" title:"Adv. Position Offset"
		menu_man.menu_separator dstlbxMenu
		---------
		local Tr_mnu = menu_man.item_submenu_create "Transform tools"
			menu_man.item_create_add Tr_mnu "HAG_scale_xform"          "HAG DesignToolbox" title:"Reference scale - xForm mod."
			menu_man.item_create_add Tr_mnu "HAG_moveAround"           "HAG DesignToolbox" title:"Move around and clone"
			menu_man.item_create_add Tr_mnu "HAG_rndTrs"               "HAG tools" title:"Random transform"
		menu_man.menu_add_submenu dstlbxMenu Tr_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Measure
		menu_man.item_create_add dstlbxMenu "HAG_Qmeasure"         "HAG DesignToolbox" title:"Measure units"
		menu_man.item_create_add dstlbxMenu "HAG_Qmeasure_mult"    "HAG DesignToolbox" title:"Chain measure"
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "HAG_Divider"          "HAG DesignToolbox" title:"Distance divider"
		menu_man.menu_separator dstlbxMenu
		---------
		local Ms_mnu = menu_man.item_submenu_create "Measure tools"
			menu_man.item_create_add Ms_mnu "HAG_Qangle"           "HAG DesignToolbox" title:"Angle measure"
			menu_man.item_create_add Ms_mnu "HAG_Qarea"            "HAG DesignToolbox" title:"2D Area measure"
			menu_man.item_create_add Ms_mnu "HAG_Qvolume"          "HAG DesignToolbox" title:"Cubic volume"
			menu_man.menu_separator Ms_mnu
			menu_man.item_create_add Ms_mnu "HAG_clonebtwn"        "HAG DesignToolbox" title:"Clone between"
			menu_man.item_create_add Ms_mnu "HAG_Divider_imput"    "HAG DesignToolbox" title:"Distance divider - imput"
		menu_man.menu_add_submenu dstlbxMenu Ms_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "HAG_distListener"     "HAG DesignToolbox" title:"Measure listener"
		menu_man.menu_separator dstlbxMenu
		--------- Eyedropper
		menu_man.item_create_add dstlbxMenu "HAG_replicator" "HAG DesignToolbox" title:"Replicator"
		menu_man.item_create_add dstlbxMenu "HAG_edrpAll"    "HAG DesignToolbox" title:"Eyedropper"
		menu_man.item_create_add dstlbxMenu "HAG_edrp_flt"   "HAG DesignToolbox" title:"Eyedropper filters"
		menu_man.menu_separator dstlbxMenu
		---------
		local Rep_mnu = menu_man.item_submenu_create "Replicators"
			menu_man.item_create_add Rep_mnu "HAG_edrpTr"     "HAG DesignToolbox" title:"Eyedropper - Transform"
			menu_man.item_create_add Rep_mnu "HAG_edrpMt"     "HAG DesignToolbox" title:"Eyedropper - Material"
			menu_man.item_create_add Rep_mnu "HAG_edrpMd"     "HAG DesignToolbox" title:"Eyedropper - Modifiers"
			menu_man.item_create_add Rep_mnu "HAG_edrpUV"     "HAG DesignToolbox" title:"Eyedropper - UVW data or modifiers"
			menu_man.item_create_add Rep_mnu "HAG_edrpVis"    "HAG DesignToolbox" title:"Eyedropper - Visual properties"
			menu_man.menu_separator Rep_mnu
			menu_man.item_create_add Rep_mnu "HAG_rep_mt"     "HAG DesignToolbox" title:"Replicator - multi target"
			menu_man.item_create_add Rep_mnu "HAG_rep_grp"    "HAG DesignToolbox" title:"Replicator - group replace mode"
			menu_man.item_create_add Rep_mnu "HAG_rep_tm"     "HAG DesignToolbox" title:"Replicate transform"
			menu_man.item_create_add Rep_mnu "HAG_rep_inst"   "HAG DesignToolbox" title:"Propagate instances"
			menu_man.item_create_add Rep_mnu "HAG_edrp_mt"    "HAG DesignToolbox" title:"Eyedropper - multi target"
		menu_man.menu_add_submenu dstlbxMenu Rep_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Tools
		menu_man.item_create_add dstlbxMenu "HAG_PARR" "HAG DesignToolbox" title:"Patern array"
		menu_man.item_create_add dstlbxMenu "HAG_IARR" "HAG DesignToolbox" title:"3D Array"
		menu_man.menu_separator dstlbxMenu
		menu_man.item_create_add dstlbxMenu "HAG_unhider"    "HAG DesignToolbox" title:"Unhide by selection"
		menu_man.item_create_add dstlbxMenu "HAG_unfrozer"   "HAG DesignToolbox" title:"Unfreeze by selection"
		menu_man.item_create_add dstlbxMenu "HAG_refIsolate" "HAG DesignToolbox" title:"Local coords. Isolation"
		menu_man.menu_separator dstlbxMenu
		--------- Pivot
		local Pivot_mnu = menu_man.item_submenu_create "Pivot tools"
			menu_man.item_create_add Pivot_mnu "HAG_QPVT"      "HAG DesignToolbox" title:"Quick pivot UI"
			menu_man.menu_separator Pivot_mnu
			-- menu_man.item_create_add Pivot_mnu "HAG_QPVT_pnt"  "HAG DesignToolbox" title:"Pivot to point"
			menu_man.item_create_add Pivot_mnu "HAG_QPVT_btn"  "HAG DesignToolbox" title:"Pivot to bottom"
			menu_man.item_create_add Pivot_mnu "HAG_QPVT_3p"   "HAG DesignToolbox" title:"Pivot from 3 points"
			menu_man.item_create_add Pivot_mnu "HAG_QPVT_3pWP" "HAG DesignToolbox" title:"Working pivot from 3 points"
			menu_man.item_create_add Pivot_mnu "HAG_QPVT_sf"   "HAG DesignToolbox" title:"Pivot from selected faces"
		menu_man.menu_add_submenu dstlbxMenu Pivot_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Objects
		menu_man.item_create_add dstlbxMenu "HAG_PN"     "HAG DesignToolbox" title:"Paneling tool"
		menu_man.item_create_add dstlbxMenu "HAG_MMap"   "HAG DesignToolbox" title:"UVW map tool"
		---------
		local Util_mnu = menu_man.item_submenu_create "Utilities"
			menu_man.item_create_add Util_mnu "HAG_PNDT"     "HAG DesignToolbox" title:"Add details tool"
			menu_man.item_create_add Util_mnu "HAG_mapTools" "HAG DesignToolbox" title:"UVW gizmo tools"
			menu_man.item_create_add Util_mnu "HAG_snapSets" "HAG tools" title:"Save snap states"
			menu_man.item_create_add Util_mnu "HAG_cclp"     "HAG tools" title:"Color clipboard"
			menu_man.item_create_add Util_mnu "HAG_rndTrs"   "HAG tools" title:"Random Transformations"
		menu_man.menu_add_submenu dstlbxMenu Util_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		---------
		local Lks_mnu = menu_man.item_submenu_create "Transform locks"
			menu_man.item_create_add Lks_mnu "HAG_Locks_all"   "HAG DesignToolbox" title:"Lock All"
			menu_man.item_create_add Lks_mnu "HAG_Locks_pos"   "HAG DesignToolbox" title:"Lock position"
			menu_man.item_create_add Lks_mnu "HAG_Locks_rot"   "HAG DesignToolbox" title:"Lock rotation"
			menu_man.item_create_add Lks_mnu "HAG_Locks_scale" "HAG DesignToolbox" title:"Lock scale"
		menu_man.menu_add_submenu dstlbxMenu Lks_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		--------- Layers
		local Layers_mnu = menu_man.item_submenu_create "Layer tools"
			menu_man.item_create_add Layers_mnu "HAG_layIso"   "HAG DesignToolbox" title:"Isolate layer"
			menu_man.menu_separator Layers_mnu
			menu_man.item_create_add Layers_mnu "HAG_layProp1" "HAG DesignToolbox" title:"Layer lock"
			menu_man.item_create_add Layers_mnu "HAG_layProp2" "HAG DesignToolbox" title:"layer ON/OFF"
			menu_man.item_create_add Layers_mnu "HAG_layProp3" "HAG DesignToolbox" title:"Layer box mode"
			menu_man.item_create_add Layers_mnu "HAG_layProp4" "HAG DesignToolbox" title:"Layer backface cull"
		menu_man.menu_add_submenu dstlbxMenu Layers_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		----------
		local cfg_mnu = menu_man.item_submenu_create "Configuration"
			menu_man.item_create_add cfg_mnu "HAG_cfg"              "HAG DesignToolbox" title:"DesignToolBox settings"
			menu_man.item_create_add cfg_mnu "HAG_refGuides_config" "HAG refGuides" title:"refGuides settings"
		menu_man.menu_add_submenu dstlbxMenu cfg_mnu
		---------
		menu_man.menu_separator dstlbxMenu
		---------
		local help_mnu = menu_man.item_submenu_create "Help"
			menu_man.item_create_add help_mnu "DTLBX_ACT" "HAG DesignToolbox"
			menu_man.item_create_add help_mnu "DTLBX_DOCS" "HAG DesignToolbox"
			menu_man.item_create_add help_mnu "DTLBX_ABOUT" "HAG DesignToolbox"
		menu_man.menu_add_submenu dstlbxMenu help_mnu
		---------
		--	*/

		/*
		local flt_mnu = menuMan.createMenu "UI Floaters"
		create_add flt_mnu "HAG_rG_fltUI"         "HAG refGuides" title:"refGuides floater"
		create_add flt_mnu "HAG_dS_fltUI"         "HAG DesignToolbox" title:"DesignToolBox floater"
		add_mnu dstlbxMenu ( menuMan.createSubMenuItem "UI Floaters" flt_mnu)
		*/
		-------------------------------------
		-- redraw the menu bar with the new item
		menuMan.updateMenuBar()
	)
