/* Resize modifier
Version date: 2024.12.01

The functionality is organized so that point scaling operations are performed once. The interface is disconnected from parameter changes.
Features added to the interface:
* Entering dimensions based on scaling. That is, on a scaled object, we set the actual size in global units.
* Convert to Xform - to store information about them from one of the users
* Convert to Transform - removes the modifier and transforms the transformations of the object. At the same time, if there are modifiers above, then their modifier context will be changed to save the modification result.

Emerging issues:
When Converting To Transform, when executing commands line by line in Listener, the result corresponds to the original one.  But when executed in a script, the result is different. It is not yet possible to find out what the reason is.
---RU---
Функционал организован так, чтобы операции масштабирования точек выполнялись единожды. Интерфейс отвязан от изменения параметров.
В интерфейс добавлены возможности:
* Ввод размеров с учётом масштабирования. То есть на масштабированном объекте мы задаём реальный размер в глобальных единицах.
* Convert to Xform - для хранения информации о них у кого-либо из пользователей
* Convert to Transform - удаляет модификатор и преобразует трансформации объекта. При этом если есть модификаторы, стоящие выше, то их контекст модификатора будет изменён для сохранения результата модифицирования.

Возникающие проблемы:
При Convert To Transform в при выполнении построчно команд в Listener результат соответствует исходному.  Но при выполнении в скрипте результат отличается. Пока не получается выяснить в чём причина.
*/

plugin simpleMod resizer
name:"Resize"
classID:#(683325,456281)
version:1.1
(
	local is_cloned = false
	
	fn getNode = (refs.dependentnodes this)[1]
	
	fn getCountModInstances = (refs.dependentnodes this).count
	
	fn getLimits obj = ( -- return node size before modifier
		if obj != undefined then (
			obj.max -- #BUGFIX on attachedToNode get size
			local _min = getModContextBBoxMin obj this
			local _max = getModContextBBoxMax obj this
			if _min != undefined then dim = (max - min)
		)
		return dim
	)
	
	parameters main rollout:params (
		newSize type:#point3
		lk_x type:#boolean ui:clk_x default:true
		lk_y type:#boolean ui:clk_y default:true
		lk_z type:#boolean ui:clk_z default:true
		--ignore_scale type:#boolean -- ui:cignore_scale default:true
	)

	rollout params "Resize Parameters"
	(
		group "Size" (
			spinner spinX "X : " type:#worldunits range:[0, 1e9, 100] scale:1
			spinner spinY "Y : " type:#worldunits range:[0, 1e9, 100] scale:1
			spinner spinZ "Z : " type:#worldunits range:[0, 1e9, 100] scale:1
		)
		group "Internal Scale" (
			spinner spinX_scale "X : " type:#float range:[0, 1e6, 1]
			spinner spinY_scale "Y : " type:#float range:[0, 1e6, 1]
			spinner spinZ_scale "Z : " type:#float range:[0, 1e6, 1]
		)
		group "Keep proportions" (
			Checkbox clk_x "X" align:#left across:3
			Checkbox clk_y "Y" align:#left
			Checkbox clk_z "Z" align:#left
		)
		group "Tools" (
			Checkbox cignore_scale "Ignore node scale" align:#center tootip:"Set the actual size, even if the object is scaled"
			button btnUpdateStackSize "Update stack size"
		)
		group "Convert to" (
			button btnConvertXform "XForm" across:2
			button btnConvertTransform "Transform"
		)
		
		fn getBigestSizeDim obj = (
			case of (
				(obj.x > obj.y and obj.x > obj.z): return 1
				(obj.y > obj.x and obj.y > obj.z): return 2
				(obj.z > obj.x and obj.z > obj.y): return 3
			)
		)

		fn updateSize = (
			-- Sets size parameter
			if cignore_scale.checked then objScale = (getNode()).scale else objScale = [1,1,1]
			x = spinX.value / objScale.x
			y = spinY.value / objScale.y
			z = spinZ.value / objScale.z
			if newSize != [x, y, z] then newSize = [x, y, z]
		)
		
		fn update_Proportioned dimNo:undefined = (
			if (lk_x and lk_y) or (lk_x and lk_z) or (lk_y and lk_z) or (lk_x and lk_y and lk_z) then (
				if dimNo == undefined then dimNo = getBigestSizeDim (extent)
				local roloutSize = [spinX.value, spinY.value, spinZ.value]
				local newScale = (roloutSize[dimNo] / extent[dimNo])
				case dimNo of (
					1: (if lk_y and lk_x then (spinY.value = extent.y * newScale; spinY_scale.value = newScale * 100)
						if lk_z and lk_x then (spinZ.value = extent.z * newScale; spinZ_scale.value = newScale * 100))
					2: (if lk_x and lk_y then (spinX.value = extent.x * newScale; spinX_scale.value = newScale * 100)
						if lk_z and lk_y then (spinZ.value = extent.z * newScale; spinZ_scale.value = newScale * 100))
					3: (if lk_x and lk_z then (spinX.value = extent.x * newScale; spinX_scale.value = newScale * 100)
						if lk_y and lk_z then (spinY.value = extent.y * newScale; spinY_scale.value = newScale * 100))
				)
			)
			updateSize()
		)
		
		on clk_x changed state do if state then update_Proportioned()
		on clk_y changed state do if state then update_Proportioned()
		on clk_z changed state do if state then update_Proportioned()
		
		on spinX changed val do (
			spinX_scale.value = val / extent.x * 100
			update_Proportioned dimNo:1
		)
		on spinY changed val do (
			spinY_scale.value = val / extent.y * 100
			update_Proportioned dimNo:2
		)
		on spinZ changed val do (
			spinZ_scale.value = val / extent.z * 100
			update_Proportioned dimNo:3
		)
		
		on spinX_scale changed val do (
			spinX.value = extent.x * val / 100
			update_Proportioned dimNo:1
		)
		on spinY_scale changed val do (
			spinY.value = extent.y * val / 100
			update_Proportioned dimNo:2
		)
		on spinZ_scale changed val do (
			spinZ.value = extent.z * val / 100
			update_Proportioned dimNo:3
		)
		
		fn loadParams = ( 
			local nd = getNode()
			local old_size = getLimits nd
			if cignore_scale.checked then objScale = nd.scale else objScale = [1,1,1]
			spinX.value = newSize.x * objScale.x
			spinY.value = newSize.y * objScale.y
			spinZ.value = newSize.z * objScale.z
			spinX_scale.value = newSize.x / old_size.x * objScale.x * 100
			spinY_scale.value = newSize.y / old_size.y * objScale.y * 100
			spinZ_scale.value = newSize.z / old_size.z * objScale.z * 100
			update_Proportioned()
		)
		on cignore_scale changed val do (
			loadParams()
		)
		on params open do (
			loadParams()
		)

		on btnConvertXForm pressed do (
			undo on (
				local sel = selection as array
				local _scale = [spinX_scale.value, spinY_scale.value, spinZ_scale.value] / 100
				work_objs = for nd in selection where (findItem (refs.dependentnodes this) nd > 0) collect nd
				for nd in work_objs do (
					local bbox = getModContextBBox nd this
					-- add modifier xform
					i = modPanel.getModifierIndex nd this
					xf = xform()
					xf.name = "XForm Resize"
					addmodifier nd xf before:(i-1)
					-- apply transform
					tm = getModContextTM nd this
					setModContextTM nd xf tm
					setModContextBBox nd xf bbox
					xf.Gizmo.position = this.Gizmo.position
					xf.Center = -xf.Gizmo.position -- this.center
					xf.Gizmo.scale = _scale
					if cignore_scale.checked then (
						nd.scale = [1, 1, 1]
						xf.Gizmo.scale /= nd.scale
					)
					-- remove modifier resizer
					modpanel.setCurrentObject xf
					deleteModifier nd (i+1)
				)
				select sel
				completeRedraw()
			)
		)
		on btnConvertTransform pressed do (
			undo on (
				sel = selection as array
				rollout_scale = [spinX_scale.value, spinY_scale.value, spinZ_scale.value] / 100
				for nd in selection where (findItem (refs.dependentnodes this) nd > 0) do (
					if cignore_scale.checked then (
						nd.scale = [1, 1, 1]
						cur_nd_scale = rollout_scale / nd.scale
					) else cur_nd_scale = rollout_scale
					i = modPanel.getModifierIndex nd this
					-- apply transform
					tmMod = getModContextTM nd this
					tmObj = nd.transform
					nd.scale = cur_nd_scale * tmObj.scale
					nd.pos = tmObj.pos - tmMod.pos + tmMod.pos * cur_nd_scale 
					deleteModifier nd i
					for n in 1 to i do ( -- transform modifiers context
						md = nd.modifiers[n]
						if hasProperty md "Gizmo" then (
							if hasProperty md "center" then mdCenter = md.center
							--md.gizmo.transform = md.gizmo.transform * (scaleMatrix cur_nd_scale)
							md.gizmo.pos = md.gizmo.pos / cur_nd_scale
							mdbbox = getModContextBBox nd md
							setModContextTM nd md ((inverse (tmObj * (inverse nd.transform))) * (scaleMatrix (1/cur_nd_scale)))						
							setModContextBBox nd md (box3 (mdbbox.min / cur_nd_scale) (mdbbox.max / cur_nd_scale))
							if hasProperty md "center" then md.center = mdCenter / cur_nd_scale
						)
					)
					/*-- reset xform insert before modifier 
					if i>1 then ( 
						stackModsOn = for k in 1 to i-1 collect nd.modifiers[k].enabled
						ResetXForm nd
						xf = nd.modifiers[1]
						xf.name = "XForm Resize"
						deleteModifier nd 1
						addmodifier nd xf before:i
						for k in 1 to stackModsOn.count do nd.modifiers[k].enabled = stackModsOn[k]
					)*/
				)
				select sel
				completeRedraw()
			)
		)
	)
	
	rollout help "About" rolledUp:true (
		label lbl_1 "Node Resize modifier"
		hyperLink lnk_1 "Atelier Bump" color:(color 200 150 0) address:"https://atelierbump.com" align:#center
		hyperLink lnk_2 "PancovEA @Github" color:(color 200 150 0) address:"https://github.com/Pankovea" align:#center
	)
	
	on attachedToNode nd do (
		if getCountModInstances() > 1 then this.params.cignore_scale.enabled = false -- #FIXME disabling not works
		if nd != undefined and not is_cloned then (
			newSize = getLimits nd
		)
	)
	
	on clone orig do (
		is_cloned = true
	)
	
	on map i p do (
		if extent.x != 0.0d0 then p.x = p.x / extent.x * newSize.x
		if extent.y != 0.0d0 then p.y = p.y / extent.y * newSize.y
		if extent.z != 0.0d0 then p.z = p.z / extent.z * newSize.z
		p
	)
)