/*
-------------------------------------------------------------------------------------------------------
HAG extra tools macros
MODIFY AT YOUR OWN RISK
HAG 2015
atelierbump@gmail.com
-------------------------------------------------------------------------------------------------------
*/
macroScript HAG_faceSel
	category:"HAG tools" 
	ButtonText:"Select same ID" 
	toolTip:"Select faces w/ same ID"
	icon: #("UVWUnwrapSelection",12)
	(
		fn selectMatID obj =
		(
			if obj !=undefined then (
				if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4)) then (
					local faceCount = polyop.getNumFaces obj
					local currFace= polyop.getFaceSelection obj
					local currFaceArr = currFace as Array
					if currFaceArr[1] != undefined then (
						local faceID = polyop.getFaceMatID obj currFaceArr[1]
						local tempFaces = #()
						tempFaces = for i=1 to faceCount where (polyop.getFaceMatID obj i == faceID) collect i
						polyop.setFaceSelection obj tempFaces
						redrawViews()
					)
				)
			)
		)
		On IsEnabled Return Filters.Is_EditPoly()
		On IsVisible Return Filters.Is_EditPoly()
		On execute do
		(
			local theObj = if selection[1] != undefined then selection[1] else undefined
			selectMatID theObj
		)
	)