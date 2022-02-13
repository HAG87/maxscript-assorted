/*
VIEWPORT COMPOSITION GUIDES
2020
*/
macroscript HAG_vpComp
	category:         "HAG tools"
	buttontext:       "viewport Composition guides"
	tooltip:          "viewport Composition guides"
(
	rollout compGuide "Composition guides"
	(
		group "Grid presets"
		(
			checkbutton p1 "2 x 2" width:65 height:40 across:2
			checkbutton p2 "3 x 3" width:65 height:40
		)
		group "Position Guides"
		(
			button place1 "Horizontal" width:65 height:40 across:2
			button place2 "Vertical" width:65 height:40
			button place3 "Cross" width:65 height:40 across:2
			button place4 "From Pt" width:65 height:40 \
				toolTip: "Position multiple aligned lines from a common base point. Useful to draw perspective lines from a vanishing point"
		)
		colorPicker c1 "Guides Color" height:20 fieldwidth:30 align:#right default:yellow
		------------------------------
		-- store values
		local
		Guide_Lines, drawingLines,
		Grid_Lines, drawingGirds,
		Store_Point, Track_point,
		guideLine
		------------------------------
		/* VIEWPORT INFORMATION FUNCTIONS */
		-- viewport data
		fn getViewportSafeFrameSize UIScaling:true =
		(
			local viewSize_x = gw.getWinSizeX applyUIScaling:UIScaling
			local viewSize_y = gw.getWinSizeY applyUIScaling:UIScaling

			local viewAspect =  viewSize_x as float / viewSize_y
			local renderAspect =  renderWidth as float / renderHeight

			local x, y, w, h
			if (viewAspect > renderAspect) then
			(
				h = viewSize_y
				w = (h * renderAspect) as integer
				y = 0
				x = (viewSize_x - w) / 2
			)
			else
			(
				w = viewSize_x
				h = (w / renderAspect) as integer
				x = 0
				y = (viewSize_y - h) / 2
			)
			return box2 x y w h
		)
		-- viewport diagonal size
		fn getViewPortDiagonalSize UIScaling:true =
		(
			(length [gw.getWinSizeX applyUIScaling:UIScaling, gw.getWinSizeY applyUIScaling:UIScaling]) as integer
		)
		------------------------------
		/* UTILITY FUNCTIONS */
		-- get axes from mouse position
		fn tracker p2 ref axis:#x =
		(
			local res
			if axis == #x then (
				res = #(
					#( [p2.x, 0, 0], [p2.x, ref.y, 0] ),
					#()
				)
			) else if axis == #y then (
				res = #(
					#(),
					#( [0, p2.y, 0], [ref.x , p2.y, 0] )
				)
			) else (
				res = #(
					#( [p2.x, 0, 0], [p2.x, ref.y, 0] ),
					#( [0, p2.y, 0], [ref.x , p2.y, 0] )
				)
			)
			res
		)
		-- construct grid
		fn viewPortGrid h v UIScaling:true =
		(
			local
			Hdiv, Vdiv,
			resH, resV,
			dx, dy,
			fx, fy
			--local vpSize =
			if displaySafeFrames then (
				local vpSize = getViewportSafeFrameSize UIScaling:UIScaling
				--	Hdiv = floor ((vpSize.h + vpSize.y) / h as float)
				--	Vdiv = floor ((vpSize.w + vpSize.x) / v as float)
				dx = vpSize.w
				dy = vpSize.h
				fx = vpSize.x
				fy = vpSize.y
			) else (
				-- Hdiv = floor (gw.getWinSizeX applyUIScaling:UIScaling / h as float)
				-- Vdiv = floor (gw.getWinSizeY applyUIScaling:UIScaling / v as float)
				dx = gw.getWinSizeX applyUIScaling:UIScaling
				dy = gw.getWinSizeY applyUIScaling:UIScaling
				fx = 0
				fy = 0
			)
			Hdiv = floor ( dy / h )
			Vdiv = floor ( dx / v )
			
			resH = for ih=1 to (h - 1) collect (
				#(
					-- mapScreenToView [0, Hdiv * ih] 1 applyUIScaling:UIScaling,
					-- mapScreenToView [dx, Hdiv * ih] 1 applyUIScaling:UIScaling
					[0, Hdiv * ih, 0] + [fx, fy, 0],
					[dx, Hdiv * ih, 0] + [fx, fy, 0]
				)
			)
			resV = for iv=1 to (v - 1) collect (
				#(
					-- mapScreenToView [Vdiv * iv, 0] 1 applyUIScaling:UIScaling,
					-- mapScreenToView [Vdiv * iv, dy] 1 applyUIScaling:UIScaling
					[Vdiv * iv, 0, 0] + [fx, fy, 0],
					[Vdiv * iv, dy, 0] + [fx, fy, 0]
				)
			)
			join resH resV
		)
		------------------------------
		/* MOUSE TRACK FUNCTIONS */
		fn TraceMouse msg ir obj faceNum shift ctrl alt args =
		(
			--	mouse.posUnscaled
			Track_point = tracker mouse.pos Store_Point axis:args
			redrawViews()
			
			case msg of
			(
				#mouseAbort: undefined
				#freeMove:   #continue
				#mouseMove:  #continue
				#mousePoint: mouse.pos
				-- #mousePoint: mouse.posUnscaled
				default: msg
			)
		)
		------------------------------
		/* GRAPHIC FUNCTIONS */
		fn GW_hline col RGBColor:yellow =
		(
			if (isKindOf col Array) AND col.count > 0 then (
				gw.setTransform (Matrix3 1)
				gw.setColor #line RGBColor
				
				for i in col do gw.hPolyline i false
				
				gw.enlargeUpdateRect #whole
				gw.updateScreen()
			)
		)
		fn GW_wline col RGBColor:yellow =
		(
			if (isKindOf col Array) AND col.count > 0 then (
				gw.setTransform (Matrix3 1)
				gw.setColor #line RGBColor
				
				for i in col do gw.wPolyline i false
				
				gw.enlargeUpdateRect #whole
				gw.updateScreen()
			)
		)
		-- gw callbacks
		fn GW_tracker       = GW_wline Track_point RGBColor:c1.color
		fn GW_GridCallback  = GW_hline Grid_Lines  RGBColor:c1.color
		fn GW_LinesCallback = GW_wline Guide_Lines RGBColor:c1.color
		fn GW_GuideCallback = GW_wline guideLine   RGBColor:c1.color
		------------------------------
		-- utility functions
		fn placeGuide axis:#x =
		(
			local mPoint
			local res
			-- save resources: store the wp size
			Store_Point = [gw.getWinSizeX applyUIScaling:UIScaling, gw.getWinSizeY applyUIScaling:UIScaling]
			-- register line track gw
			unregisterRedrawViewsCallback GW_tracker
			registerRedrawViewsCallback GW_tracker
			-- track line
			if ( mPoint = mouseTrack snap:#3d trackCallback:#(TraceMouse, axis)) != undefined then
			(
				-- just return the point
				res = Track_point
			)
			-- unregister the tracker
			unregisterRedrawViewsCallback GW_tracker
			res
		)
		fn drawGrids state h v =
		(
			if state then (
				try (
					Grid_Lines = viewPortGrid h v
					unregisterRedrawViewsCallback GW_GridCallback
					registerRedrawViewsCallback GW_GridCallback
					redrawViews()
				)
				catch (
					unregisterRedrawViewsCallback GW_GridCallback
					format (getCurrentException())
				)
			) else (
				unregisterRedrawViewsCallback GW_GridCallback
				redrawViews()
			)
		)
		fn drawLines theGuide =
		(
			if not drawingLines then (
				drawingLines = true
				unregisterRedrawViewsCallback GW_LinesCallback
				registerRedrawViewsCallback GW_LinesCallback
			)
			local res
			try (
				if (res = theGuide) != undefined then (
					-- add to lines collection
					join Guide_Lines res
					redrawViews()
				)
			) catch (
				-- unregister gw
				unregisterRedrawViewsCallback GW_LinesCallback
				format (getCurrentException())
			)
		)
		fn drawRays =
		(
			-- implemented as a mouseTool
			tool raysTool
			(
				-- base point
				local bp
				local vpDiagSize = getViewPortDiagonalSize()
				-- line function
				fn compline p1 p2 ext:1000 =
				(
					local v = (normalize (p2 - p1)) * ext
					#(-v + p1, v + p1)
				)
				-- events
				on start do (
					registerRedrawViewsCallback GW_GuideCallback
				)
				on stop do (
					unRegisterRedrawViewsCallback GW_GuideCallback
					guideLine = #()
				)
				-- click event
				on mousePoint clickno do (
				   if clickno == 1 then (
					   bp = [viewPoint.x, viewPoint.y, 0]
				   ) else if clickno != 2 then (
					   -- add guide to display collection
					   if guideLine[1] != undefined then drawLines guideLine
				   )				   
				)
				-- mouse track event
				on mouseMove clickno do (
					if bp != undefined then (
						guideLine = #(compline bp [viewPoint.x, viewPoint.y, 0] ext:vpDiagSize)
					)
					redrawViews()
			   )
			   -- on mouseAbort ckickno do (...)
			)
		   -- start the tool
		   startTool raysTool
		)
		------------------------------
		-- open event
		on compGuide open do
		(
			-- initialize values
			Guide_Lines  = #()
			Grid_Lines  = #()
			drawingLines = false
			
			Store_Point = [0, 0, 0]
			Track_point = [0, 0, 0]
			
			guideLine = #()
		)
		-- close event
		on compGuide close do
		(
			unregisterRedrawViewsCallback GW_tracker
			unregisterRedrawViewsCallback GW_GridCallback
			unregisterRedrawViewsCallback GW_LinesCallback
			unregisterRedrawViewsCallback GW_GuideCallback
			redrawViews()
		)
		------------------------------
		-- draw 2x2 grid
		on p1 changed state do (drawGrids state 2 2; if p2.checked then p2.checked = false)
		-- draw 3x3 grid
		on p2 changed state do (drawGrids state 3 3; if p1.checked then p1.checked = false)
		------------------------------
		-- draw horiz lines
		on place1 pressed do drawLines (placeGuide axis:#y)
		-- draw vert lines
		on place2 pressed do drawLines (placeGuide axis:#x)
		-- draw cross lines
		on place3 pressed do drawLines (placeGuide axis:#xy)
		-- draw free position guide
		on place4 pressed do drawRays()
	)

	on isChecked do if compGuide != undefined then compGuide.open else false

	on execute do (
		try (
			if not compGuide.open then CreateDialog compGuide
		) catch (
			DestroyDialog compGuide
			CreateDialog compGuide
		)
	)
)