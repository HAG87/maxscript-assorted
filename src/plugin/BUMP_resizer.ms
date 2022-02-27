plugin simpleMod resizer
name:"Resize"
classID:#(683325,456281)
version:1.0
(
	fn getNode = (refs.dependentnodes this)[1]
	fn getLimits obj =
	(
		local _min = getModContextBBoxMin obj this
		local _max = getModContextBBoxMax obj this
		dim = _max - _min
		dim
	)
	parameters main rollout:params
	(
		x_amount type:#worldunits ui:SpinX default:100
		y_amount type:#worldunits ui:SpinY default:100
		z_amount type:#worldunits ui:SpinZ default:100
		proportion type:#point3 default:[1.0,1.0,1.0]
		newDims type:#point3 default:[100.0,100.0,100.0]
		isProportioned type:#boolean ui:Chk1 default:false
		lk_x type:#boolean ui:clk_x default:true
		lk_y type:#boolean ui:clk_y default:true
		lk_z type:#boolean ui:clk_z default:true
		
		on x_amount set val do (if not loading then newDims.x = val)
		on y_amount set val do (if not loading then newDims.y = val)
		on z_amount set val do (if not loading then newDims.z = val)
	)
	on attachedToNode nd do (
		if nd != undefined then (
-- 			proportion = getLimits nd
-- 			newDims = proportion
		)
	)
	on clone nd do (
	)
	rollout params "Resize Parameters"
	(
		spinner SpinX "X : " type:#worldunits range:[-10000000.0,10000000.0,100.0]
		spinner SpinY "Y : " type:#worldunits range:[-10000000.0,10000000.0,100.0]
		spinner SpinZ "Z : " type:#worldunits range:[-10000000.0,10000000.0,100.0]
		Checkbox Chk1 "Keep proportions"
		group "Link proportions"
		(
			Checkbox clk_x "	X" align:#left across:3
			Checkbox clk_y "	Y" align:#left
			Checkbox clk_z "	Z" align:#left
		)
		on SpinX changed val do (
			if isProportioned then (
				proportion = getLimits (getNode())
				local delta = (proportion.x / val)
				if lk_y and lk_x then y_amount = proportion.y / delta
				if lk_z and lk_x then z_amount = proportion.z / delta					
			) 
		)
		on SpinY changed val do (
			if isProportioned then (
				proportion = getLimits (getNode())
				local delta = (proportion.y / val)
				if lk_x and lk_y then x_amount = proportion.x / delta
				if lk_z and lk_y then z_amount = proportion.z / delta
			) 
		)
		on SpinZ changed val do (
			if isProportioned then (
				proportion = getLimits (getNode())
				local delta = (proportion.z / val)
				if lk_x and lk_z then x_amount = proportion.x / delta
				if lk_y and lk_z then y_amount = proportion.y / delta
			) 
		)		
	)
	rollout help "About" rolledUp:true
	(
		label lbl_1 "Node Resize modifier"
		hyperLink lnk_1 "Atelier Bump" color:(color 200 150 0) address:"https:/atelierbump.com" align:#center
	)
	on map i p do
	(
		if extent.x != 0.0d0 then p.x = p.x / extent.x * newDims.x
		if extent.y != 0.0d0 then p.y = p.y / extent.y * newDims.y
		if extent.z != 0.0d0 then p.z = p.z / extent.z * newDims.z
		p
	)
)