(
	/* SELECT ALL NODES INSIDE A OPEN CONTAINER*/
	fn cont_content c =
	(
		if isKindOf c Container then (
			local nd
			c.GetContentNodes true &nd
			selectMore nd
		)
	)
	/* LIST NODE PROPERTIES */
	fn props_lister obj =
	(
		ClearListener()
		p_names = getPropNames obj
		p_str = for i in p_names collect (i as string)
		for i in p_str do (format "%\n" i)
	)
	/* add new layer and set options */
	fn addLay obj layerName:"layer_test_" =
	(
		if not(LayerManager.getLayerFromName layerName) then
		(
			local refLay = LayerManager.newLayerFromName layerName
			refLay.showFrozenInGray=false
			refLay.renderable =false
			refLay.lock=true
			try (refLay.addNode obj) catch ()
		)
	)
	/* MATRIX FROM 3 POINTS */
	fn getMatrix p1 p2 p3 = (
		v1 = normalize (p2 - p1)
		v3 = normalize (cross v1 (normalize (p3 - p1)))
		v2 = normalize (cross v3 v1)
		return matrix3 v1 v2 v3 p1
	)
	/* RESET ROTATION */
	fn resetAxisRot obj axis:x = (
		local objTM = obj.transform
		local objTR = obj.position
		local objRot = objTM.rotationpart
		local deg = objRot as EulerAngles
		case axis of (
			x: deg.x = 0
			y: deg.y = 0
			z: deg.z = 0
		)
		local rm = (deg as Quat) as Matrix3
		local newTM = rm
		newTM.row4 = objTR
		obj.transform = newTM
	)
	/* set Onj ID relative to camera distance */
	fn setObjID =
	(
		local cam = getActiveCamera()
		if cam != undefined then (
			local bbx = box2 [0,0] [gw.getWinSizeX(),gw.getWinSizeY()]
			local objsel = boxPickNode bbx
			local campos = cam.pos
			fn compareFN v1 v2 ref: =
			(
				local a = distance ref v1.pos
				local b = distance ref v2.pos
				local d = a - b
				case of
				(
					(d < 0.): -1
					(d > 0.): 1
					default: 0
				)
			)
			qsort objsel compareFN ref:campos
			for i=1 to objsel.count do (
				objsel[i].gbufferChannel = i
			)

		)
	)
	/* SELECT ALL NODES WHITOUT MATERIAL*/
	fn sel_nomat =
	(
		local sel = getCurrentSelection()
		local nomat = for i in sel where (i.material == undefined and not (isgrouphead i)) collect i
		select nomat
	)
	/* FIX VRAY NEXT GLOSSINESS UNLOCK */
	fn vrayFixGlossLock = for m in (getclassinstances vraymtl) do m.reflection_lockGlossiness = true
)