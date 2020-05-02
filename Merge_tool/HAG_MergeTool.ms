/*
    Node Merge (attach) and Explode (Detach) tool.
    04-2020
    https://atelierbump.com

    INSTALL NOTES:
    - Copy .ms file to either 3dsmax scripts folder or user scripts folder
    - Copy .mcr file to either 3dsmax MacroScripts folder or usermacros folder
*/
(
    struct ExplodeMergeTools
    (
        private
        msg1 = "One or more nodes that where used as source for the merge are invalid. Please review the selected nodes.",
        msg2 = "Some nodes have been exluded from the operation. Please review the selected nodes.",

        fn GetPolymeshElems obj =
        (
            local oType
            if (isKindOf obj Editable_mesh) then
            (
                opType = meshop
            )
            else if (canConvertTo obj Editable_Poly) then
            (
                opType = polyop
                convertTo obj Editable_Poly
            )
            local elements = #()
            local num_faces = opType.getNumFaces obj
            local face_col = #{1..num_faces}
            do (
                local elem = opType.getElementsUsingFace obj face_col.numberSet
                face_col -= elem
                append elements elem
            ) while not face_col.isEmpty
            elements
        ),
        fn PolymeshEleDetach obj eles =
        (

            if (superClassOf obj == GeometryClass AND isKindOf eles array) then
            (
                local nodeNames =  #(obj.name)
                local storeNodes
                local oType
                if (isKindOf obj Editable_mesh) then
                (
                    opType = meshop
                )
                else if (canConvertTo obj Editable_Poly) then
                (
                    opType = polyop
                )
                local _detachFaces = opType.detachFaces
                for i=1 to eles.count-1 do (
                    local aname = (uniqueName "Elem_")
                    _detachFaces obj eles[i] name:aname delete:true asNode:true node:obj
                    append nodeNames aname
                )
                polyop.CollapseDeadStructs obj
                storeNodes = for i=1 to nodeNames.count collect (getNodeByName nodeNames[i])
                storeNodes
            )
        ),
        fn ShapeDetach shp =
        (
            local shapeClones
            local shapeCount = numSplines shp
            if shapeCount > 1 then
            (
                shapeClones = for i=1 to shapeCount-1 collect copy shp
                append shapeClones shp
            )
            undo off
            (
                if shapeClones.count == shapeCount then
                (
                    for i=1 to shapeCount do
                    (
                        local currShape = shapeClones[i]
                        for f=shapeCount to 1 by -1 where f != i do
                        (
                            deleteSpline currShape f
                        )
                        updateShape currShape
                    )
                )
            )
            shapeClones
        ),
        fn mergeShapes srcNodes &outNode &badNodes backup:true =
        (
            local opNodes
            local refNode
            local trashNodes = #()
            if backup then
            (
                maxops.clonenodes srcNodes cloneType:#copy actualNodeList:&oldNodes newNodes:&opNodes
            )
            else
            (
                opNodes = srcNodes
            )
            if (canConvertTo opNodes[1] SplineShape) then
            (
                refNode = opNodes[1]
                convertTo refNode SplineShape
            )
            else
            (
                badNodes = #(refNode)
                return false
            )
            with redraw off
            (
                for i = opNodes.count to 2 by -1 where (isValidNode opNodes[i]) do
                (
                    local currNode = opNodes[i]
                    if (canConvertTo currNode SplineShape) then
                    (
                        convertTo currNode SplineShape
                        addAndWeld refNode currNode -1
                    )
                    else
                    (
                        append trashNodes currNode
                    )
                )
            )
            outNode = refNode
            if trashNodes.count > 0 then badNodes = trashNodes
            true
        ),
        fn mergePolyMesh srcNodes &outNode &badNodes backup:true =
        (
            local opType
            local opNodes
            local refNode
            local trashNodes = #()

            if backup then
            (
                maxops.clonenodes srcNodes cloneType:#copy actualNodeList:&oldNode newNodes:&opNodes
            )
            else
            (
                opNodes = srcNodes
            )

            InstanceMgr.MakeObjectsUnique opNodes #individual
            refNode = opNodes[1]

            if (isKindOf refNode Editable_mesh) then
            (
                opType = meshop
            )
            else if (canConvertTo refNode Editable_Poly) then
            (
                opType = polyop
                convertTo refNode Editable_Poly
            ) else (
                badNodes = refNode
                return false
            )

            with redraw off
            (
                for i = srcNodes.count to 2 by -1 where (isValidNode srcNodes[i]) do
                (
                    local currNode = srcNodes[i]
                    if (canConvertTo currNode Editable_Poly) then (
                    )
                    else
                    (
                        append trashNodes currNode
                    )
                )
            )

            outNode = refNode
            if trashNodes.count > 0 then badNodes = trashNodes
            true
        ),
        fn explodePolyMesh srcNodes &outNode backup:true =
        (
            local opNodes
            local outNodes = #()
            if backup then
            (
                maxops.clonenodes srcNodes cloneType:#copy actualNodeList:&oldNode newNodes:&opNodes
            )
            else
            (
                opNodes = srcNodes
            )
            InstanceMgr.MakeObjectsUnique opNodes #individual

            with redraw off
            (
                for i=1 to opNodes.count do
                (
                    local currNode = opNodes[i]
                    local elems = GetPolymeshElems currNode
                    if elems.count > 1 then (
                        local detachedNodes = PolymeshEleDetach currNode elems
                            if detachedNodes.count > 0 then (
                            join outNodes detachedNodes
                            )
                    )
                )
            )
            outNode = outNodes
            true
        ),
        fn explodeShapes srcNodes &outNode backup:true =
        (
            local opNodes
            local refNode
            local trashNodes = #()
            local outNodes = #()
            if backup then
            (
                maxops.clonenodes srcNodes cloneType:#copy actualNodeList:&oldNode newNodes:&opNodes
            )
            else
            (
                opNodes = srcNodes
            )
            InstanceMgr.MakeObjectsUnique opNodes #individual

            with redraw off
            (
                for i=1 to opNodes.count do
                (
                    local currNode = opNodes[i]
                    if not isKindOf currNode SplineShape then convertTo currNode SplineShape
                    local resultNodes = ShapeDetach currNode
                    join outNodes resultNodes
                )
            )
            outNode = outNodes
            true
        ),
        public
        fn nodeMerge source backup:false transform: pivot: =
        (
            local
            GeometryNodes,
            ShapeNodes

            GeometryNodes =
            for i = 1 to source.count where (isValidNode source[i] AND (superClassOf source[i] == GeometryClass AND canConvertTo source[i] TriMeshGeometry))
            collect source[i]
            ShapeNodes =
            for i = 1 to source.count where (isValidNode source[i] AND superClassOf source[i] == Shape)
            collect source[i]

            undo "Merge Geometry Nodes" on
            (
                if GeometryNodes.count > 1 then (
                    try (
                        mergePolyMesh GeometryNodes &outGNode &trashGeom backup:backup
                    )
                    catch (
                        format "%\n" (getCurrentException())
                    )
                )
            )
            undo "Merge Shape Nodes" on
            (
                if ShapeNodes.count > 1 then (
                    try (
                        mergeShapes ShapeNodes &outSNode &trashShape backup:backup
                    )
                    catch (
                        format "%\n" (getCurrentException())
                    )
                )
            )
            clearSelection()

            if (trashGeom != undefined OR trashShape != undefined) then
            (
                if (outGNode != undefined OR outSNode != undefined) then
                (
                    messageBox msg1
                )
                else
                (
                    messageBox msg2
                )
                if trashGeom != undefined then select trashGeom
                if trashShape != undefined then selectmore trashShape
            )
            else
            (
                if outGNode != undefined then select outGNode
                if outSNode != undefined then selectmore outSNode
            )
            CompleteRedraw()
        ),
        fn nodeExplode source backup:false transform: pivot: =
        (
            local
            GeometryNodes,
            ShapeNodes,
            resultGeoNodes    = #(),
            resulltShapeNodes = #()

            GeometryNodes =
            for i = 1 to source.count where (isValidNode source[i] AND (superClassOf source[i] == GeometryClass AND canConvertTo source[i] TriMeshGeometry))
            collect source[i]
            ShapeNodes =
            for i = 1 to source.count where (isValidNode source[i] AND superClassOf source[i] == Shape)
            collect source[i]

            undo "Explode Geometry Nodes" on
            (
                if GeometryNodes.count > 0 then
                (
                    try (
                        explodePolyMesh GeometryNodes &resultGeoNodes backup:backup
                    )
                    catch (
                        format "%\n" (getCurrentException())
                    )
                )
            )

            undo "Explode Shape Nodes" on
            (
                if ShapeNodes.count > 0 then (
                    try (
                        explodeShapes ShapeNodes &resultShapeNodes backup:backup
                    )
                    catch (
                        format "%\n" (getCurrentException())
                    )
                )
            )

            if resultGeoNodes.count > 0 then
            (
                for i=1 to resultGeoNodes.count do (
                    local n = resultGeoNodes[i]
                    n.pivot = [n.center.x, n.center.y, n.min.z]
                )
                select resultGeoNodes
            ) else (
            )
            if resultShapeNodes.count > 0 then
            (
                for i=1 to resultShapeNodes.count do (
                    local n = resultShapeNodes[i]
                    n.pivot = [n.center.x, n.center.y, n.min.z]
                )
                selectmore resultShapeNodes
            ) else (
            )
            CompleteRedraw()
        )
    )
    -- export the struct
    ExplodeMergeTools()
)