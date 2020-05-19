(

	rollout roll_PathEdit "Add Paths" width:500 height:300
	(
		local owner = if owner != undefined then owner
		local stored_values
		label lbl1 "Enter a list of paths separated by semicolons (;) or New Lines (\n). Paths can be quoted"
		edittext txt1 height:230
		button btn1 "Commit"  width:150 height:30
		fn stringparser str =
		(
			local stream = str as StringStream
			seek stream 0
			--readValue stream ignoreStringEscapes:true
			local pathsCol = #()
			try (
				while not eof stream do (
					local the_path = readDelimitedString stream ";\n"
					-- print the_path
					-- sanitize the strings
					-- deal with \"\" and "\n"s
					--if matchPattern the_path pattern:"\""
					if pathConfig.isLegalPath the_path then (
						append pathsCol the_path
					) else (
						the_path = substituteString the_path "\"" ""
						the_path = substituteString the_path "'" ""
						-- just in case
						the_path = substituteString the_path "\n" ""
						-- attemp to validate the path
						local resolved_path = pathConfig.resolvePathSymbols the_path
						if pathConfig.isLegalPath resolved_path then (
							append pathsCol the_path
						)
					)
				)
				-- ensure unique paths
				pathsCol = makeUniqueArray pathsCol
			) catch (messageBox "Invalid entries!")
			-- return the paths
			pathsCol
		)
		on btn1 pressed do (
			-- commit paths
			local paths = stringparser txt1.text
			if paths.count > 0 then stored_values = paths
			-- exit dialog
			DestroyDialog roll_pathEdit
		)
	)

	rollout roll_mPath "Advanced External Files (User Paths) Manager" width:1000 --height:400
	(
		dotNetControl lst_mPath "ListView" height:300
		button btn_1 "Change / Resolve" width:150 align:#left across:5
		button btn_3 "Brownse..." width:150  align:#left
		button btn_8 "Paste..."  width:150  align:#left
		button btn_2 "Remove" width:150  align:#left
		checkbutton btn_4 "Show Only Invalids" align:#right

		checkBox chk_sb "Sub-Directories search filter" align:#left checked:true across:2
		editText txt_filter "Pattern: " Text:"#(\"map*\",\"texture*\")" align:#right

		imgTag sep1 width:(roll_mPath.width) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center offset:[0,10]
		button btn_7 "Remove ..." width:150 align:#left across:7
		checkbox chk_1 "Empty folders" checked:true width:80 align:#right
		checkbox chk_dupes "Duplicates" checked:true width:80 align:#right
		checkbox chk_2 "Not Images" width:80 align:#right
		checkbox chk_3 "Not Models" width:80 align:#right
		checkbox chk_4 "Other (specify):" align:#right
		editText txt_1 text:"#(\".ies\",\".svg\")" align:#left
		imgTag sep2 width:(roll_mPath.width) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center offset:[0,10]
		button btn_open "Explore selected" height:30 align:#left across:3
		button btn_5 "Done" width:150 height:30 align:#right	offset:[160,0]
		button btn_6 "Cancel" width:150 height:30 align:#right
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local only_invalid = false
		--
		local temp_paths   = #()
		local add_paths    = #()
		local remove_paths = #()
		--
		local temp_listItemsCol
		----------------------------------------------------------------------------------------------------------------------------------------------------
		-- file extensions, add as needed
		local img_ext = #(".jpg",".jpeg",".png",".tif",".tiff",".tga",".bmp",".exr",".gif", ".hdr", ".hdri")
		local md_ext = #(".3ds",".max",".obj",".fbx",".iges",".dwg",".dxf",".rvt",".skp")
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local dotNetLstViewItemClass = dotNetClass "System.Windows.Forms.ListViewItem"
		local dotNetLstViewClass     = dotNetClass "System.Windows.Forms.ListView"
		local dotNetColor            = dotNetClass "System.Drawing.Color"
		local dotNetFont             = dotNetClass "System.Drawing.Font"
		local font_underline         = (dotNetClass "System.Drawing.FontStyle").Underline
		local font_bold              = (dotNetClass "System.Drawing.FontStyle").Bold
		local font_strk              = (dotNetClass "System.Drawing.FontStyle").Strikeout
		local font_reg               = (dotNetClass "System.Drawing.FontStyle").Regular
		local folder_dialog          = dotnetobject "FolderBrowserDialog"
		local dotNetDirectory        = dotnetclass "System.IO.Directory"
		local DirectorySearch        = (dotNetClass"System.IO.SearchOption").AllDirectories
		local dotNetSort             = dotNetClass "System.Windows.Forms.SortOrder"
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local validPathColor = dotNetColor.seagreen
		local invalidPathColor = dotNetColor.Crimson
		local removedPathColor = dotNetColor.Goldenrod
		--	local dotNetContextMenuClass = dotNetClass "System.Windows.Forms.ContextMenu"
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
		-- Retrieve subdirectorries
		fn GetAllSubDirs MyDirectory _filter:#("map*","texture*") =
		(
			local curr_folder =
				if _filter != unsupplied then (
					local temp = #()
					for i in _filter do ( join temp (dotNetDirectory.GetDirectories MyDirectory i DirectorySearch) )
					temp
				) else ( dotNetDirectory.GetDirectories MyDirectory "*" DirectorySearch )
			curr_folder
			/*
			local
			temp = #(),
			s = 1,
			folders = getDirectories (MyDirectory + "/*"),
			t = folders.count
			while s < t do
			(
				for i = s to t do (
					temp = getDirectories (folders[i]+"*")
					-- apply filter
					for j = 1 to temp.count do folders[folders.count+1] = temp[j]
				)
				s = t
				t = folders.count
			)
			sort folders
			for i=1 to folders.count do (folders[i] = trimRight folders[i] "\\")
			folders
			---	*/
		)
		----------------------------------------------------------------------------------------------------------------------------------------------------
		-- Re-apply style
		fn lst_restyle =
		(
			local list_items = lst_mPath.Items
			for f=0 to (list_items.count)-1 do (
				list_items.Item[f].BackColor = if (bit.get f 1) then dotNetColor.Transparent else dotNetColor.LightGray
			)
		)
		-- Add columns to listView
		fn lstV_addColumns lst itms autosize:false =
		(
			local HZ = (dotNetClass "HorizontalAlignment").Left
			local w = if not autosize then ( (lst.width/itms.count)-1 ) else -2
			for x in itms do ( lst.columns.add x w HZ )
		)
		-- Add items to listView
		fn lstV_addItem lst itmCol =
		(
			lst.BeginUpdate()
				lst.Items.AddRange itmCol
				lst.AutoResizeColumns (dotNetClass "ColumnHeaderAutoResizeStyle").ColumnContent
				lst.AutoResizeColumns (dotNetClass "ColumnHeaderAutoResizeStyle").HeaderSize
			lst_restyle()
			lst.EndUpdate()
		)

		-- Process paths into ListView items
		fn parse_items mP_list font: listView:lst_mPath =
		(
			local res_list = #()
			if mP_list != undefined then (
				local ForeColor
				local currpath
				local subitems
				local res_list =
				for i=1 to mP_list.count collect (
					currpath = mP_list[i]
					subitems = #()
					subitems[5] = if (pathConfig.isAbsolutePath currpath) then "Absolute" else if (pathConfig.isUncPath currpath) then "UNC" else "-"
					subitems[1] = pathConfig.stripPathToLeaf currpath
					subitems[2] = currpath
					subitems[3] = (getFiles (pathConfig.appendPath currpath "*.*")).count as string
					subitems[4] = if (dotNetDirectory.exists currpath) then (ForeColor = validPathColor; "OK") else (ForeColor = invalidPathColor;"MISSING")
					-- Initialize Item
					local item = dotNetObject dotNetLstViewItemClass subitems
					item.tag = currpath
					item.ForeColor = ForeColor
					item.BackColor = if (bit.get i 1) then dotNetColor.Transparent else dotNetColor.LightGray
					if font != unsupplied then item.Font = (dotNetObject dotNetFont (listView.Font) font)
					item
				)
			)
			res_list
		)
		-- Update listView Item
		fn update_item the_item new_path =
		(
			local the_subitems = the_item.subitems
			the_item.text = pathConfig.stripPathToLeaf new_path
			the_subitems.item[1].text = new_path
			the_subitems.item[2].text = (getFiles (pathConfig.appendPath new_path "*.*")).count as string
			the_subitems.item[3].text =
			if (dotNetDirectory.exists new_path) then (
				the_item.ForeColor = validpathColor
				"OK"
			) else (
				the_item.ForeColor = invalidPathColor
				"MISSING"
			)
			the_subitems.item[4].text = if (pathConfig.isAbsolutePath new_path) then "Absolute" else if (pathConfig.isUncPath new_path) then "UNC" else "-"
		)
		-- Initialize Collection
		fn Init =
		(
			-- Collect user paths
			temp_paths = for i=1 to (mapPaths.count()) collect (mapPaths.get i)
			-- Process paths into ListView items
			lstV_addItem lst_mPath (parse_items temp_paths)
		)
		-- Commit changes to Paths
		fn commit =
		(
			if not (queryBox "Commit changes ?. This could take a while to process.") then return false
			-- remove any dupes
			remove_paths = makeUniqueArray remove_paths
			add_paths = makeUniqueArray add_paths
			-- remove possible delete entry from add entry..
			add_paths = for i=1 to add_paths.count where (findItem remove_paths add_paths[i] == 0) collect add_paths[i]
			-- delete entry
			format "Remobing paths from External files list:\n"
			try (
				for r=1 to remove_paths.count do (
					local f_o = findItem temp_paths remove_paths[r]
					if f_o != 0 then mapPaths.delete f_o
					format "Removed: \n" remove_paths[r]
				)
			) catch (messageBox "Unable to remove some paths.")
			-- add entry
			format "Adding paths to External files list:\n"
			try (
				--	progressStart "Adding user paths"
				for i=1 to add_paths.count do (
					format "adding: %\n" add_paths[i]
					-- do not add duplicated entries
					local f_o = findItem temp_paths add_paths[i]					
					if f_o == 0 then mapPaths.add add_paths[i]
				)
			) catch (messageBox "unable to add some paths")
		)
		-- open explorer
		fn openDir =
		(
			local itms = lst_mPath.SelectedItems.Item
			DOSCommand ("explorer " + "\"" + (itms[0].Subitems.Item[1].text) + "\"")
		)
		-- Add to list
		fn path_adder paths =
		(
			local the_paths = deepcopy paths
			local the_filter = if chk_sb.state then (execute txt_filter.text) else unsupplied
			local subdirs = queryBox "Add subfolders too?"

			for the_path in paths do (
				if subdirs then (
					join the_paths (
						GetAllSubDirs the_path _filter:the_filter
					)
				)
			)
			-- add to temp results
			join add_paths the_paths
			-- add to list
			lstV_addItem lst_mPath (parse_items the_paths font:font_Bold)
			OK
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
			-- Items Sort
			lst_mPath.Sorting = dotNetSort.Ascending
			--------------------------------------------------------------------------------------------------------------------------------
			-- Add Columns
			lstV_addColumns lst_mPath #("Folder name", "Full path", "Files", "Status", "Type") autosize:True
			-- Add Items
			Init()
			--	lst_mPath.Items.Clear()
		)
		-- close
		on roll_mPath close do ( lst_mPath.Dispose(); gc())
		---------------------------------------------------------------------------------------------------------------------------------------------------- Event handlers
		-- Change entry
		on btn_1 pressed do
		(
			local underline = dotNetObject dotNetFont (lst_mPath.Font) font_underline
			-- get items list
			local itms = lst_mPath.SelectedItems.Item
			local itms_count = lst_mPath.SelectedItems.count
			for i=0 to itms_count-1 do (
				local the_item = itms[i]
				folder_dialog.showDialog()
				local new_path = folder_dialog.SelectedPath
				if new_path != "" then (
					-- add old to remove list
					appendIfUnique remove_paths (the_item.Subitems.Item[1].text)
					-- add new to add list
					appendIfUnique add_paths new_path
					-- update listview
					the_item.Font = underline
					update_item the_item new_path
				)
			)
		)
		-- Remove entry
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

				local save_color = the_item.ForeColor
				local save_Font = the_item.Font
				if f_d == 0 then (
					the_item.Font = strikeout
					the_item.ForeColor = removedPathColor
					appendIfUnique remove_paths item_path
				) else (
					the_item.Font = save_Font
					the_item.ForeColor = save_color
					deleteItem remove_paths f_d
				)
			)
		)
		-- paste paths string
		on btn_8 pressed do (
			local roll = roll_PathEdit
			createDialog roll modal:true
			local response = roll.stored_values
			-- print response
			if isKindOf response Array then (
				-- commit the paths
				path_adder response
			)
		)
		-- add entry
		on btn_3 pressed do
		(
			local res = folder_dialog.showDialog()
			local the_path = folder_dialog.SelectedPath

			if the_path != "" then path_adder #(the_path)
		)
		-- invalid paths filter
		on btn_4 changed state do
		(
			if state then (
				items_col = lst_mPath.Items
				temp_listItemsCol = for i= 0 to (items_col.count)-1 where (items_col.Item[i].Subitems.Item[3].text == "OK") collect items_col.Item[i]
				local temp_items =
				for i = (items_col.count)-1 to 0 by -1 where (items_col.Item[i].Subitems.Item[3].text != "OK") collect (items_col.Item[i].Clone())
				lst_mPath.Items.Clear()
				lstV_addItem lst_mPath temp_items
			) else (
				lstV_addItem lst_mPath temp_listItemsCol
				lst_mPath.Sort()
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
			-- search for files in folders
			local filenames =
			for f=1 to origin_paths.count collect (
				local temp = getfiles (origin_paths[f] + "\\*.*")
				local ext = #()
				if temp.count != 0 then (
					ext = for i=1 to temp.count where (getFilenameType temp[i]) != ".db" collect (getFilenameType temp[i])
				)
				ext
			)
			-- marked will contain indexes
			local marked = #()
			-- dupes will contain paths
			local dupes =  #()
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
			-- duplicates
			if chk_dupes.checked then (
				local suspects = deepCopy origin_paths
				sort suspects
				-- format "suspects: %\n" suspects
				dupes = for i=1 to (suspects.count - 1) where (suspects[i] == suspects[i+1]) collect suspects[i]
			)
			-- process list
			-- get paths using collected indexes
			local str = dotnetclass "system.string"

			local temp_marked = makeUniqueArray marked
			local paths_list = for g=1 to temp_marked.count collect origin_paths[temp_marked[g]]
			-- add dupes
			join paths_list dupes
			-- find item in list, change item font
			for i=1 to paths_list.count do (
				local f_i = lst_mPath.FindItemWithText (dotNet.ValueToDotNetObject paths_list[i] str) true 0 false

				if f_i != undefined then (
					-- format "% || %\n" paths_list[i] f_i.Tag
					f_i.Font = strikeout
					f_i.ForeColor = removedPathColor
				)
			)
			-- add to deletion array
			join remove_paths paths_list
		)
		-- accept
		on btn_5 pressed do (commit(); DestroyDialog roll_mPath)
		on btn_6 pressed do (DestroyDialog roll_mPath)
		on btn_open pressed do (openDir())
	)
	CreateDialog roll_mPath
)