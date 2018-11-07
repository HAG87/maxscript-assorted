macroScript HAG_RndSel
			category:         "HAG tools"
			ButtonText:       "Random Select"
			silentErrors:     true
			tooltip:"Select radom nodes"
(
	fn rndItemsPercent c p =
	(
		local itms_count = floor (c * p) as integer
		local res = #()
		for i = 1 to itms_count do (
			local r = random 1 c
			if ((findItem res r) != 0) then
			(
				do (
					r = random 1 c
				) while ((findItem res d) != 0)
			)
			append res r
		)
		sort res
		res
	)
	fn rndItemsSubstr c p =
	(
		local itms_count = c - ( ceil (c * p) as integer )
		format "%\n" itms_count

		local res = #()
		
		if ( itms_count > 0) then (
			for i = 1 to itms_count do (
				local r = random 1 c
				if ((findItem res r) != 0) then
				(
					do (
						r = random 1 c
					) while ((findItem res d) != 0)
				)
				append res r
			)
		)
		
		
		sort res
		res
	)
	fn rndItemsStep c s =
	(
		local res
		if s < (c/2) then (
			local bits = #{1..c}
			for i = 1 to bits.count by s where ((random 0 1) == 1) do bits[i] = false
			res = bits as Array
			sort res
		) else (
			res = #()
		)
		res
	)
	rollout roll_rndSel "Random selection"
	(
		group "Mode"
		(
			radioButtons rd_1 labels:#("Percent","Step", "Substract")
		)
		group "Values"
		(
			spinner spn_1 "Percent" range:[1,100,50] type:#integer fieldWidth:(roll_rndSel.width/2) align:#right
			spinner spn_2 "Step" range:[1,1000,1] type:#integer fieldWidth:(roll_rndSel.width/2) align:#right enabled:false
			spinner spn_3 "Subst. %" range:[0,99,50] type:#integer fieldWidth:(roll_rndSel.width/2) align:#right enabled:false
		)
		group "Deselect Pattern"
		(
			spinner spn_4 "Step" range:[1,100,1] type:#integer fieldWidth:(roll_rndSel.width/2) align:#right
			spinner spn_5 "Qty." range:[1,1000,1] type:#integer fieldWidth:(roll_rndSel.width/2) align:#right
		)
		button btn_1 "Select Random" height:30 width:(roll_rndSel.width - 25)
		button btn_2 "Re-Select" height:30 width:(roll_rndSel.width - 25)
		--	button btn_2 "Done" height:30 width:(roll_rndSel.width - 25)
		-----------------------------------------
		local mode = 1,
		sel, sel_count
		-----------------------------------------
		fn rndSel s c x mode:1  =
		(
			local rnd, res
			rnd = case mode of
			(
				1: ( rndItemsPercent c (x * 0.01) )
				2: ( rndItemsStep c x )
				3: ( rndItemsSubstr c (x * 0.01) )
			)
			if rnd.count > 0 then (
				res = for i = 1 to rnd.count where (isValidNode s[rnd[i]]) collect s[rnd[i]]
			) else (
				res = for i = 1 to s.count where (isValidNode s[i]) collect s[i]
			)
			res
		)
		fn test_sel =
		(
			sel = getCurrentSelection()
			if sel.count != 0 then 
				sel_count = sel.count
			else
				messageBox "Select some nodes!"
			OK
		)
		-----------------------------------------
		on roll_rndSel open do (
			max create mode
			test_sel()
		)
		on rd_1 changed state do
		(
			mode = state
			case state of (
				1: (
					spn_1.enabled = true
					spn_2.enabled = false
					spn_3.enabled = false
				)
				2: (
					spn_1.enabled = false
					spn_2.enabled = true
					spn_3.enabled = false
				)
				3: (
					spn_1.enabled = false
					spn_2.enabled = false
					spn_3.enabled = true
				)
			)
		)
		on spn_1 changed val do
		(
			if sel.count == 0 then test_sel()
			 else
			select (rndSel sel sel_count val mode:1)
		)
		on spn_2 changed val do
		(
			if sel.count == 0 then test_sel()
			else
			select (rndSel sel sel_count val mode:2)
		)
		on spn_3 changed val do
		(
			if sel.count == 0 then test_sel()
			else
			select (rndSel sel sel_count val mode:3)
		)
		fn selPattern sel c st qn =
		(
			local res = #()
			local delta = st + qn
			if delta < c then (
				for i=1 to (c - delta) by delta do (
					local tmp = for f = 1 to st collect sel[i+f]
					join res tmp
				)
			)
			res
		)
		on spn_4 changed val do
		(
			if sel.count == 0 then test_sel()
			else
				select (selPattern sel sel_count val spn_5.value)
		)
		on spn_5 changed val do
		(
			if sel.count == 0 then test_sel()
			else
				select (selPattern sel sel_count spn_4.value val)
		)
		on btn_1 pressed do
		(
			if sel.count == 0 then test_sel()
			else
			(
				case mode of (
					1: ( select (rndSel sel sel_count spn_1.value mode:1) )
					2: ( select (rndSel sel sel_count spn_2.value mode:2) )
					3: ( select (rndSel sel sel_count spn_3.value mode:3) )
				)
			)
		)
		on btn_2 pressed do (
			--	DestroyDialog roll_rndSel
			test_sel()

		)
		
	)
	CreateDialog roll_rndSel	
)
macroScript HAG_RndIDSet
			category:         "HAG tools"
			ButtonText:       "Random ID Set"
			silentErrors:     true
			tooltip:"Set random IDs"
(
	fn randMatID obj min:1 max:5 =
	(
		if obj !=undefined then (
			if ((isKindOf obj Editable_Poly) and (subObjectLevel == 4)) then (
				local faceCount = polyop.getNumFaces obj
				local currFace= polyop.getFaceSelection obj				
				local currFaceArr = currFace as Array				
				if currFaceArr[1] != undefined then (					
					for i in currFaceArr do polyop.setFaceMatID obj i (abs (floor (random min max)))
					redrawViews()
				)
			)
		)
	)
	on execute do try (randMatID $) catch ()
)