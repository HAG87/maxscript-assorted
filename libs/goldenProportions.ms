struct goldenProportions
(
    private
    fn phivalue = phi = (1 + sqrt 5) / 2.0,
    rects,
    public
    phi = phivalue(),	
    private		
    -- PhiRectangles bounds: the golden ratio rectangle
    fn goldenRectangleBounds viewSize margin_vertical:0.0 margin_horizontal:0.0 =
    (
        -- the rectangle
        local rec = boxmodel()
        -- rectangle size
        if (viewSize.w > viewSize.h) then
        (
            -- horizontal rectangle
            rec.orient = 0
            
            if (viewSize.w / viewSize.h as float) > phi then
            (
                rec.h = viewSize.h
                rec.w = viewSize.h * phi
            ) else (
                rec.w = viewSize.w
                rec.h = viewSize.w / phi
            )
        ) else (
            -- vertical rectangle
            rec.orient = 1
            
            if (viewSize.h / viewSize.w as float) > phi then
            (
                rec.w = viewSize.w
                rec.h = viewSize.w * phi
            ) else (
                rec.h = viewSize.h
                rec.w = viewSize.h / phi
            )
        )		
        -- margins
        rec.h += margin_vertical
        rec.w += margin_horizontal		
        -- center the Rectangle
        rec.x = (viewSize.x + (viewSize.w - rec.w) / 2.0) as integer
        rec.y = (viewSize.y + (viewSize.h - rec.h) / 2.0) as integer		
        -- other values
        rec.refPoint = [rec.x, rec.y, 0]
        rec.basepoint = rec.refPoint		
        -- the rectangle object
        rec
    ),
    -- PhiRectangles iterator.
    fn PhiRectangles &rects limit:1.0 =
    (
        -- draw the rectangle here ?
        -- last value
        local last = rects[rects.count]
        -- proceed until the rectangle is 1x1px in size...
        if (last.w > limit) OR (last.h > limit) then (
            local curr = deepCopy last

            case last.orient of (
                0:
                (
                    curr.refpoint = [last.x, last.y + last.h, 0]					
                    curr.x += last.h
                    curr.w -= last.h					
                    curr.basePoint = [curr.x, curr.y + curr.h,0]					
                    curr.orient = 1
                )
                1:
                (
                    curr.refpoint = [last.x, last.y, 0]					
                    curr.y += last.w
                    curr.h -= last.w					
                    curr.basePoint = [curr.x, curr.y,0]					
                    curr.orient = 2
                )
                2:
                (
                    curr.refpoint = [last.x + last.w, last.y, 0]					
                    curr.w -= last.h					
                    curr.basePoint = [curr.x + curr.w, curr.y,0]					
                    curr.orient = 3
                )
                3:
                (	
                    curr.refpoint = [last.x + last.w, last.y + last.h, 0]					
                    curr.h -= last.w					
                    curr.basePoint = [curr.x+last.w, curr.y+curr.h,0]					
                    curr.orient = 0
                )
            )
            -- add to collection
            append rects curr
            -- ITERATE
            PhiRectangles &rects limit:limit
        )
    ),
    -- interpolate arc points
    fn arcGen bp radius start:0 end:360 res:1 =
    (
        for i=start to end by res collect [(cos i), (sin i), 0.0] * radius + bp
    ),
    public
    -- generate the golden rectangles collection
    fn goldenRectangles sizebox margin_vertical:0.0 margin_horizontal:0.0 =
    (
        if classOf sizebox == Box2 then (
            -- start
            local rects = #( goldenRectangleBounds sizebox margin_vertical:margin_vertical margin_horizontal:margin_horizontal )
            -- iterate
            PhiRectangles &rects
            -- return
            rects
        ) else undefined
    ),
    -- draw rectilinear spiral
    fn sqSpiral golden_rects =
    (
        for r=2 to golden_rects.count collect golden_rects[r].refPoint
    ),
    -- draw quasi-spiral conformed by arcs
    fn arcSpiral golden_rects res:1 =
    (
        local res = #()		
        for r=2 to golden_rects.count do (		
            local radius = distance golden_rects[r].basePoint golden_rects[r].refPoint			
            local arcpoints =
            case golden_rects[r].orient of (
                0:( arcGen (golden_rects[r].basePoint) radius start:90 end:180 )
                1:( arcGen (golden_rects[r].basePoint) radius start:180 end:270 )
                2:( arcGen (golden_rects[r].basePoint) radius start:270 end:360 )
                3:( arcGen (golden_rects[r].basePoint) radius start:0 end:90 )
            )
            join res arcpoints
        )
        res
    )
)