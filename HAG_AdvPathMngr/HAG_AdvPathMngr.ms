(
	--	clearListener()
	rollout roll_mPath "Advanced External Files (User Paths) Manager" width:1000 --height:400
	(
		dotNetControl lst_mPath "ListView" height:300
		button btn_1 "Change / Resolve" width:150 align:#left across:4
		button btn_2 "Remove" width:150 offset:[-80,0] align:#left
		button btn_3 "Add" width:150 offset:[-160,0] align:#left
		button btn_4 "Show Only Invalids" align:#right
		imgTag sep1 width:(roll_mPath.width) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center offset:[0,10]
		button btn_7 "Remove ..." width:150 align:#left across:6
		checkbox chk_1 "Empty folders" checked:true width:80 align:#right 
		checkbox chk_2 "Not Images" width:80 align:#right
		checkbox chk_3 "Not Models" width:80 align:#right
		checkbox chk_4 "Other (specify):" align:#right
		editText txt_1 text:"#(\".ies\",\".svg\")" align:#left	
		imgTag sep2 width:(roll_mPath.width) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center offset:[0,10]
		button btn_5 "Done" width:150 height:30 offset:[320,0] align:#right across:2
		button btn_6 "Cancel" width:150 height:30 align:#right
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local only_invalid = false
		--
		local temp_paths = #()
		local add_paths = #()
		local remove_paths = #()
		----------------------------------------------------------------------------------------------------------------------------------------------------
		-- file extensions, add as needed
		local img_ext = #(".jpg",".jpeg",".png",".tif",".tiff",".tga",".bmp",".exr",".gif", ".hdr", ".hdri")
		local md_ext = #(".3ds",".max",".obj",".fbx",".iges",".dwg",".dxf",".rvt",".skp")
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local dotNetLstViewItemClass = dotNetClass "System.Windows.Forms.ListViewItem"
		local dotNetLstViewClass = dotNetClass "System.Windows.Forms.ListView"
		local dotNetColor = dotNetClass "System.Drawing.Color"
		local dotNetFont = dotNetClass "System.Drawing.Font"
		local font_underline = (dotNetClass "System.Drawing.FontStyle").Underline
		local font_bold = (dotNetClass "System.Drawing.FontStyle").Bold
		local font_strk = (dotNetClass "System.Drawing.FontStyle").Strikeout
		local font_reg = (dotNetClass "System.Drawing.FontStyle").Regular
		local folder_dialog = dotnetobject "FolderBrowserDialog"
		local dotNetDirectory = dotnetclass "System.IO.Directory"
		----------------------------------------------------------------------------------------------------------------------------------------------------
		-- Compare function used by bsearch:
		fn extComparator a b =
		(
			if a > (toLower b) then 1
			else if a < (toLower b) then -1
			else 0
		)
		fn invSort a b =
		(
			case of (
				(a > b):-1
				(a < b):1
				default:0
			)
		)
		fn ArrayComparator a b =
		(
			if a > b then 1
				else if a < b then -1
					else 0
		)
		fn GetAllSubDirs MyDirectory =
		(
			local
			temp = #(),
			s = 1,
			folders = getDirectories (MyDirectory + "/*"),
			t = folders.count
			while s < t do
			(
				for i = s to t do (temp = getDirectories (folders[i]+"*")
				for j = 1 to temp.count do folders[folders.count+1] = temp[j] )
				s = t
				t = folders.count
			)
			sort folders
			for i=1 to folders.count do (folders[i] = trimRight folders[i] "\\")
			folders
		)
		----------------------------------------------------------------------------------------------------------------------------------------------------
		fn lstV_addColumns lst itms autosize:false =
		(
			local HZ = (dotNetClass "HorizontalAlignment").Left
			local w = if not autosize then ( (lst.width/itms.count)-1 ) else -2
			for x in itms do ( lst.columns.add x w HZ )
		)
		fn lstV_addItem lst itmCol colorCol: font: = 
		(
			if (isKindOf itmCol Array) then (
				local dotNetFontStyle = if font != unsupplied then (dotNetObject dotNetFont (lst.Font) font)
				
				local itms = for l=1 to itmCol.count collect (
					local itm = dotNetObject dotNetLstViewItemClass itmCol[l]
					itm.tag = l
					if font != unsupplied then (itm.Font = dotNetFontStyle)
					if colorCol != unsupplied then ( if colorCol[l] != "" then itm.ForeColor = colorCol[l] )
					if (bit.get l 1) do (itm.BackColor = dotNetColor.LightGray)
					itm
				)
				
				lst.BeginUpdate()
					lst.Items.AddRange itms
					lst.AutoResizeColumns (dotNetClass "ColumnHeaderAutoResizeStyle").ColumnContent
					lst.AutoResizeColumns (dotNetClass "ColumnHeaderAutoResizeStyle").HeaderSize
				lst.EndUpdate()
			)
		)
		-- reaply style
		fn lst_restyle =
		(
			local list_items = lst_mPath.Items
			for f=0 to (list_items.count)-1 do (
				list_items.Item[f].BackColor = if (bit.get f 1) then dotNetColor.Transparent else dotNetColor.LightGray
			)
		)
		
		fn parse_items mP_list =
		(
			if mP_list != undefined then (
				local ColrList = #()
				ColrList[mP_list.count] = ""				
				local res_list = for i=1 to mP_list.count collect (
					local itm = #()
					itm[1] = pathConfig.stripPathToLeaf mP_list[i]
					itm[2] = mP_list[i]
					itm[3] = (getFiles (pathConfig.appendPath mP_list[i] "*.*")).count as string						
					if (dotNetDirectory.exists mP_list[i]) then (
						itm[4] = "OK"
						ColrList[i] = dotNetColor.seagreen
					) else (
						itm[4] = "MISSING"
						ColrList[i] = dotNetColor.Crimson
					)
					itm[5] = if (pathConfig.isAbsolutePath mP_list[i]) then "Absolute" else ( if (pathConfig.isUncPath mP_list[i]) then "UNC" else "-" )
					itm
				)
				#(res_list, ColrList)
			) else undefined
		)
		
		fn update_item the_item new_path =
		(
			local the_subitems = the_item.subitems
			the_item.text = pathConfig.stripPathToLeaf new_path
			the_subitems.item[1].text = new_path
			the_subitems.item[2].text = (getFiles (pathConfig.appendPath new_path "*.*")).count as string
			if (dotNetDirectory.exists new_path) then (
				the_subitems.item[3].text = "OK"
				the_item.ForeColor = dotNetColor.seagreen
			) else (
				the_subitems.item[3].text = "MISSING"
				the_item.ForeColor = dotNetColor.Crimson
			)
			the_subitems.item[4].text = if (pathConfig.isAbsolutePath new_path) then "Absolute" else ( if (pathConfig.isUncPath new_path) then "UNC" else "-" )
		)
		fn Init =
		(
			local u_paths = for i=1 to (mapPaths.count()) collect (mapPaths.get i)
			temp_paths = deepcopy u_paths
			local result_items = parse_items temp_paths
			if result_items != undefined then (
				lstV_addItem lst_mPath (result_items[1]) colorCol:(result_items[2])
			)
		)
		fn commit =
		(
			if queryBox "Commit changes ?" then (
				-- delete items
				progressStart "Deleting user paths"
				remove_paths = makeUniqueArray remove_paths
				local rem_count = remove_paths.count
				for r = rem_count to 1 by -1 do (
					progressUpdate ( (rem_count- r) * 100 / rem_count)
					local f_o = findItem temp_paths remove_paths[r]
-- 					local f_o = bsearch remove_paths[r] temp_paths ArrayComparator
-- 					if f_o != undefined then (
					if f_o != 0 then (
						mapPaths.delete f_o
-- 							print remove_paths[r]
					)
				)
				progressEnd()
				-- add items
				add_paths = makeUniqueArray add_paths
				local add_count = add_paths.count
				progressStart "Adding user paths"
					for i=1 to add_count do (
						progressUpdate ( i * 100 / add_count)
						local f_o = findItem temp_paths add_paths[i]
-- 						local f_o = bsearch add_paths[i] temp_paths ArrayComparator
-- 						if f_o == undefined then (
						if f_o == 0 then (
							mapPaths.add add_paths[i]
-- 							print add_paths[i]
						)
					)
				progressEnd()
			)
		)
		----------------------------------------------------------------------------------------------------------------------------------------------------
		-- Initialize
		on roll_mPath open do
		(
			local HZ = (dotNetClass "HorizontalAlignment").Left
			--------------------------------------------------------------------------------------------------------------------------------
			--Setup the forms view
			lst_mPath.view = (dotNetClass "system.windows.forms.view").details
			--Set so full width of listView is selected and not just first column.
			lst_mPath.FullRowSelect = true
			--Show lines between the items. 
			lst_mPath.GridLines = true			
			--Allow for multiple selections.
			lst_mPath.MultiSelect = true			
			-- Allow Label Edit
			lst_mPath.LabelEdit = True
			-- Allow Column order change
			lst_mPath.AllowColumnReorder = True
			-- Columns Header additonal options
			lst_mPath.HeaderStyle = lst_mPath.HeaderStyle.Nonclickable
			-- turn off the grid lines
			lst_mPath.gridLines = false
			-- When this ListView loses the focus, it will still show what's selected
			lst_mPath.HideSelection = false 
			-- make the border a flat solid color instead of the Windows 3D look
			lst_mPath.BorderStyle = lst_mPath.BorderStyle.FixedSingle 
			-- required in order to implement DotNet drag and drop functionality
			lst_mPath.allowDrop = true		
			--------------------------------------------------------------------------------------------------------------------------------
			-- Add Columns
			lstV_addColumns lst_mPath #("Folder name", "Full path", "Files", "Status", "Type") autosize:True
			-- Add Items
			Init()
			--	lst_mPath.clear()
		)
		-- close
		on roll_mPath close do ( lst_mPath.Dispose(); gc())
		---------------------------------------------------------------------------------------------------------------------------------------------------- Event handlers
		-- change items
		on btn_1 pressed do
		(
			local underline = dotNetObject dotNetFont (lst_mPath.Font) font_underline
			-- get items list
			local itms = lst_mPath.SelectedItems.Item
			local itms_count = lst_mPath.SelectedItems.count
			for i=0 to itms_count-1 do (
				local the_item = itms[i]
-- 				print the_item
				local res = folder_dialog.showDialog()
				local new_path = folder_dialog.SelectedPath
				if new_path != "" then (
					the_item.Font = underline
					local itm_path = the_item.Subitems.Item[1]
					local old_path = itm_path.text
					-- update listview
					update_item the_item new_path
					-- add old to remove list
					appendIfUnique remove_paths old_path
					-- add new to add list
					appendIfUnique add_paths new_path
				)
			)
		)
		-- Remove items		
		on btn_2 pressed do
		(
			local strikeout = dotNetObject dotNetFont (lst_mPath.Font) font_strk
			local regular = dotNetObject dotNetFont (lst_mPath.Font) font_reg
			local itms = lst_mPath.SelectedItems.Item
			local itms_count = lst_mPath.SelectedItems.count
			for i=0 to itms_count-1 do (
				local the_item = itms[i]
				local item_path = the_item.Subitems.Item[1].Text
				local f_d = findItem remove_paths item_path
				if f_d == 0 then (
					the_item.Font = strikeout
					appendIfUnique remove_paths item_path
				) else (
					the_item.Font = regular
					deleteItem remove_paths f_d
				)
			)
		)
		-- add items
		on btn_3 pressed do
		(
			local res = folder_dialog.showDialog()
			local the_path = folder_dialog.SelectedPath
			if the_path != "" then (
				local the_paths = #(the_path)
				if (queryBox "Add subfolders too?") then join the_paths (GetAllSubDirs the_path)
				local result_items = parse_items the_paths
				if result_items != undefined then (
					lstV_addItem lst_mPath (result_items[1]) colorCol:(result_items[2]) font:(font_Bold)
					-- add to temp results
					join add_paths the_paths
				)
			)
		)
		-- invalid paths filter
		on btn_4 pressed do
		(
			if (not only_invalid) then (
				only_invalid = not only_invalid
				local items_col = lst_mPath.Items
				lst_mPath.BeginUpdate()
				for i=(items_col.count)-1 to 0 by -1 do (
					local the_item = items_col.Item[i]
					local the_item_sub = the_item.Subitems.Item[3]
					local status = the_item_sub.text
					if status == "OK" then ( items_col.Remove(the_item) )
				)
				-- reapply style
				lst_mPath.EndUpdate()
			)
		)
		-- remove unwanted WIP
		on btn_7 pressed do
		(
			local strikeout = dotNetObject dotNetFont (lst_mPath.Font) font_strk
			-- collect filenames
			-- local proc_array = temp_paths + add_paths REPLACE TEMP PATHS
			local origin_paths = deepcopy temp_paths
			join origin_paths add_paths
			
			local filenames =
			for f=1 to origin_paths.count collect (
				local temp = getfiles (origin_paths[f] + "\\*.*")
				local ext = #()
				if temp.count != 0 then (
					ext = for i=1 to temp.count where (getFilenameType temp[i]) != ".db" collect (getFilenameType temp[i])
				)
				ext
			)
			local marked = #()
			-- empty folders
			if chk_1.checked then (
				local empty_folders = #()
				empty_folders =  for a=1 to filenames.count where filenames[a].count == 0 collect a
				join marked empty_folders
			)
			-- not images
			if chk_2.checked then (
				local not_images = #()
				not_images = for b=1 to filenames.count collect (
					local res = 0
					local cnt = 1
					do (
						bsearch img_ext[cnt] filenames[b] extComparator index:&res
						cnt += 1
					) while ((cnt < img_ext.count) and (res == 0))
					if res == 0 then b else continue
				)
				join marked not_images
			)
			-- not models
			if chk_3.checked then (
				local not_models = #()
				not_models = for c=1 to filenames.count collect (
					local res = 0
					local cnt = 1
					do (
						bsearch md_ext[cnt] filenames[c] extComparator index:&res
						cnt += 1
					) while ((cnt < md_ext.count) and (res == 0))
					if res == 0 then c else continue
				)		
				join marked not_models
			)
			-- other
			if chk_4.checked then (
				local ext = execute txt_1.text
				if isKindOf ext Array then (
					local other_files = #()
					other_files = for d=1 to filenames.count collect (
						local res = 0
						local cnt = 1
						do (
							bsearch ext[cnt] filenames[d] extComparator index:&res
							cnt += 1
						) while ((cnt < ext.count) and (res == 0))
						if res == 0 then d else continue
					)
					join marked other_files
				)
			)
			-- process list
			local temp_marked = makeUniqueArray marked
			local paths_list = for g=1 to temp_marked.count collect (
				local curr_index = temp_marked[g]
				origin_paths[curr_index]
			)
			-- find item in list, change item font
			for i=1 to paths_list.count do (
				local f_i = lst_mPath.FindItemWithText (paths_list[i])
				if f_i != undefined then f_i.Font = strikeout
			)
			-- add to deletion array
			join remove_paths paths_list
		)
		-- accept
		on btn_5 pressed do (commit(); DestroyDialog roll_mPath)
		on btn_6 pressed do (DestroyDialog roll_mPath)
	)
	CreateDialog roll_mPath
)