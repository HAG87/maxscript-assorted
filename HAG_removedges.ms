macroScript removeEdges
	category:"HAG"
	toolTip:"REMOVE POLY EDGES"
(
	macros.run "Editable Polygon Object" "EPoly_Convert_Sel_To_Vertex"
	macros.run "Modifier Stack" "SubObject_2"
	$.EditablePoly.Remove ()
	macros.run "Modifier Stack" "SubObject_1"
	$.EditablePoly.Remove ()
)
