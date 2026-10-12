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
			local pathsCol = #()
			local invalidCount = 0
			try (
				while not eof stream do (
					local the_path = readDelimitedString stream ";\n"
					the_path = substituteString the_path "\r" ""
					the_path = substituteString the_path "\"" ""
					the_path = substituteString the_path "'" ""
					the_path = trimLeft (trimRight the_path)
					if the_path != "" then (
						local is_legal = pathConfig.isLegalPath the_path
						if not is_legal do (
							local resolved_path = pathConfig.resolvePathSymbols the_path
							is_legal = pathConfig.isLegalPath resolved_path
						)
						if is_legal then (
							appendIfUnique pathsCol the_path
						) else invalidCount += 1
					)
				)
				if invalidCount > 0 do messageBox ("Skipped " + (invalidCount as string) + " invalid fPath(s).")
			) catch (
				messageBox ("Unable to parse the paths. " + (getCurrentException() as string))
				pathsCol = #()
			)
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

	rollout roll_mPath "Advanced External Files (User Paths) Manager" width:1000 autoLayoutOnResize:true --height:400
	(
		dotNetControl lst_mPath "ListView" height:300
		button btn_3 "Add ..." width:80  align:#left across:5
		button btn_8 "Paste ..."  width:80  align:#left offset:[-100,0]
		button btn_2 "Remove" width:80  align:#left offset:[-200,0]
		button btn_open "Explore selected" width:90 align:#left offset:[-300,0]
		checkbutton btn_4 "Show Only Invalids" align:#right
		checkBox chk_sb "Sub-Directories search filter: " align:#left checked:true across:2
		editText txt_filter "" Text:"#(\"map*\",\"texture*\")" width:790 align:#left offset:[-305,0]
		imgTag sep1 width:(roll_mPath.width) height:1 align:#center offset:[0,5]
		button btn_7 "Clean ..." width:150 align:#left across:7
		checkbox chk_1 "Empty folders" checked:true width:80 align:#right
		checkbox chk_dupes "Duplicates" checked:true width:80 align:#right
		checkbox chk_2 "Not Images" width:80 align:#right
		checkbox chk_3 "Not Models" width:80 align:#right
		checkbox chk_4 "Other (specify):" align:#right
		editText txt_1 text:"#(\".ies\",\".svg\")" align:#left
		imgTag sep2 width:(roll_mPath.width) height:1 align:#center offset:[0,5]

		button btn_5 "Done" width:150 height:30 align:#right	across:2	offset:[370,0]
		button btn_6 "Cancel" width:100 height:30 align:#right
		-----------------------------------------------------------------------
		local only_invalid = false
		--
		local
			TEMP_PATHS   = #(),
			ADD_PATHS    = #(),
			REMOVE_PATHS = #()
		--
		local temp_listItemsCol
		local file_count_cache = dotNetObject "System.Collections.Hashtable"
		-----------------------------------------------------------------------
		-- file extensions, add as needed
		local
			img_ext = #(".jpg",".jpeg",".png",".tif",".tiff",".tga",".bmp",".exr",".gif", ".hdr", ".hdri"),
			md_ext = #(".3ds",".max",".obj",".fbx",".iges",".dwg",".dxf",".rvt",".skp")
		-----------------------------------------------------------------------
		local
			alignLeft              = (dotNetClass "HorizontalAlignment").Left,
			resizeToContent        = (dotNetClass "ColumnHeaderAutoResizeStyle").ColumnContent,
			dotNetLstViewItemClass = dotNetClass "System.Windows.Forms.ListViewItem",
			dotNetLstViewClass     = dotNetClass "System.Windows.Forms.ListView",
			dotNetColor            = dotNetClass "System.Drawing.Color",
			dotNetFont             = dotNetClass "System.Drawing.Font",
			resizeToHeader         = (dotNetClass "ColumnHeaderAutoResizeStyle").HeaderSize,
			font_underline         = (dotNetClass "System.Drawing.FontStyle").Underline,
			font_bold              = (dotNetClass "System.Drawing.FontStyle").Bold,
			font_strk              = (dotNetClass "System.Drawing.FontStyle").Strikeout,
			font_reg               = (dotNetClass "System.Drawing.FontStyle").Regular,
			folder_dialog          = dotnetobject "FolderBrowserDialog",
			dotNetDirectory        = dotnetclass "System.IO.Directory",
			DirectorySearch        = (dotNetClass"System.IO.SearchOption").AllDirectories,
			dotNetSort             = dotNetClass "System.Windows.Forms.SortOrder"
		-----------------------------------------------------------------------
		local
			validPathColor   = dotNetColor.seagreen,
			invalidPathColor = dotNetColor.Crimson,
			removedPathColor = dotNetColor.Goldenrod
		--	local dotNetContextMenuClass = dotNetClass "System.Windows.Forms.ContextMenu"
		-----------------------------------------------------------------------
		fn invSort a b =
		(
			case of (
				(a > b):-1
				(a < b):1
				default:0
			)
		)
		fn pathKey fPath =
		(
			local key = toLower (substituteString fPath "/" "\\")
			while (key.count > 1) AND ((substring key key.count 1) == "\\") AND not (key.count == 3 AND (substring key 2 2) == ":\\") do (
				key = substring key 1 (key.count - 1)
			)
			key
		)
		fn makePathLookup paths =
		(
			local lookup = dotNetObject "System.Collections.Hashtable"
			for fPath in paths do (
				local key = pathKey fPath
				if not (lookup.ContainsKey key) do lookup.Add key true
			)
			lookup
		)
		fn pathIsKnown lookup fPath =
		(
			lookup.ContainsKey (pathKey fPath)
		)
		fn rememberPath lookup fPath =
		(
			local key = pathKey fPath
			if not (lookup.ContainsKey key) do lookup.Add key true
		)
		fn findPathIndex paths fPath =
		(
			local index = 0
			local key = pathKey fPath
			for i=1 to paths.count while index == 0 do (
				if pathKey paths[i] == key do index = i
			)
			index
		)
		fn pathFileCount fPath =
		(
			local key = pathKey fPath
			if file_count_cache.ContainsKey key then return file_count_cache.Item[key]
			if not (dotNetDirectory.exists fPath) then return "0"
			local count = (getFiles (pathConfig.appendPath fPath "*.*")).count as string
			file_count_cache.Add key count
			count
		)
		fn readStringArray text =
		(
			local parsed = undefined
			try (
				local stream = text as StringStream
				seek stream 0
				parsed = readValue stream
			) catch (
				return undefined
			)
			if not (isKindOf parsed Array) then return undefined
			local valid = true
			for value in parsed do (
				if not (isKindOf value String) then
					valid = false
				else if value == "" then
					valid = false
			)
			if not valid then return undefined
			parsed
		)
		fn extensionsMatch extensions allowed =
		(
			local found = false
			for extension in extensions while not found do (
				for candidate in allowed while not found do (
					if extension == (toLower candidate) do found = true
				)
			)
			found
		)
		-- Retrieve subdirectorries
		fn GetAllSubDirs MyDirectory _filter:#("map*","texture*") =
		(
			local curr_folder = dotNetDirectory.GetDirectories MyDirectory "*" DirectorySearch
			if _filter == unsupplied then return curr_folder
			local filtered = #()
			for folder in curr_folder do (
				local folder_name = (dotNetObject "System.IO.DirectoryInfo" folder).Name
				local matches = false
				for pattern in _filter do (
					if matchPattern folder_name pattern ignoreCase:true do matches = true
				)
				if matches do append filtered folder
			)
			filtered
		)
		-- image separators
		fn dividerImage setColor: =
		(
			local col_1 = if isKindOf setColor color then setColor else ((colorMan.getColor #shadow) * 255.0) as color
			local
			gammavalue = 1.0,
			colorSpaceVal = unsupplied

			if ColorPipelineMgr != undefined then (
				gammavalue = 1.0 / ColorPipelineMgr.DisplayGamma
				if ColorPipelineMgr.Mode != #unmanaged then colorSpaceVal = "sRGB"
			) else if IDisplayGamma != undefined then (
				gammavalue = 1.0 / IDisplayGamma.gamma
			)
			-- return 1x1 bitmap
			bitmap 1 1 color:col_1 gamma:gammavalue colorSpace:colorSpaceVal
		)
		-----------------------------------------------------------------------
		-- Re-apply style
		fn lst_restyle =
		(
			local colorA = dotNetColor.Transparent
			local colorB = dotNetColor.seashell
			
			local list_items = lst_mPath.Items
			for f=0 to (list_items.count) - 1 do (
				list_items.Item[f].BackColor = if (bit.get f 1) then colorA else colorB
			)
		)
		-- Add columns to listView
		fn lstV_addColumns lst itms autosize:false =
		(
			local w = if not autosize then ( (lst.width/itms.count)-1 ) else -2
			for x in itms do ( lst.columns.add x w alignLeft )
		)
		-- Add items to listView
		fn lstV_addItem lst itmCol =
		(
			if itmCol == undefined or itmCol.count == 0 then return false
			lst.BeginUpdate()
			try (
				lst.Items.AddRange itmCol
				lst.AutoResizeColumns resizeToContent
				lst.AutoResizeColumns resizeToHeader
				lst_restyle()
			) catch (
				lst.EndUpdate()
				messageBox ("Unable to update the fPath list. " + (getCurrentException() as string))
				return false
			)
			lst.EndUpdate()
			true
		)
		-- Process paths into ListView items
		fn parse_items mP_list font: listView:lst_mPath =
		(
			local res_list = #()

			if mP_list != undefined then (
				local currpath, subitems, exists
				res_list =
				for i=1 to mP_list.count collect (
					currpath = mP_list[i]
					exists = dotNetDirectory.exists currpath
					
					subitems = #()
					-- folder name
					subitems[1] = pathConfig.stripPathToLeaf currpath
					-- full path
					subitems[2] = currpath
					-- file count
					subitems[3] = pathFileCount currpath
					-- status
					subitems[4] = if exists then "OK" else "MISSING"
					-- path type
					subitems[5] = if (pathConfig.isAbsolutePath currpath) then "Absolute" else if (pathConfig.isUncPath currpath) then "UNC" else "-"
					-- Initialize Item
					local item = dotNetObject dotNetLstViewItemClass subitems
					item.tag = currpath
					item.ForeColor = if exists then validPathColor else invalidPathColor

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
			-- folder name
			the_item.text = pathConfig.stripPathToLeaf new_path
			the_item.tag = new_path
			-- Note: Here we are updating the item, not creating a new one, so the indices are for the subitems in the existing ListView item
			-- full path
			the_subitems.item[1].text = new_path
			-- file count
			the_subitems.item[2].text = pathFileCount new_path
			-- path type
			local path_exists = dotNetDirectory.exists new_path
			the_subitems.item[4].text = if (pathConfig.isAbsolutePath new_path) then "Absolute" else if (pathConfig.isUncPath new_path) then "UNC" else "-"
			-- status
			the_subitems.item[3].text =
			if path_exists then (
				the_item.ForeColor = validPathColor
				"OK"
			) else (
				the_item.ForeColor = invalidPathColor
				"MISSING"
			)
			
		)
		-- Initialize Collection
		fn Init =
		(
			-- Collect user paths
			TEMP_PATHS = for i=1 to (mapPaths.count()) collect (mapPaths.get i)
			-- Process paths into ListView items
			lstV_addItem lst_mPath (parse_items TEMP_PATHS)
		)
		fn refreshList =
		(
			TEMP_PATHS = for i=1 to (mapPaths.count()) collect (mapPaths.get i)
			ADD_PATHS = #()
			REMOVE_PATHS = #()
			lst_mPath.Items.Clear()
			local items = parse_items TEMP_PATHS
			if btn_4.state then (
				temp_listItemsCol = #()
				local invalid_items = #()
				for item in items do (
					if item.SubItems.Item[3].Text == "OK" then
						append temp_listItemsCol item
					else
						append invalid_items item
				)
				lstV_addItem lst_mPath invalid_items
			) else (
				lstV_addItem lst_mPath items
			)
		)
		-----------------------------------------------------------------------------------------------
		-- Commit changes to Paths
		fn commit =
		(
			local result = true
			if not (queryBox "Commit changes ?. This could take a while to process.") then return false
			
			TEMP_PATHS = for i=1 to (mapPaths.count()) collect (mapPaths.get i)
			local remove_lookup = makePathLookup REMOVE_PATHS
			local add_lookup = makePathLookup #()
			local unique_additions = #()
			for fPath in ADD_PATHS do (
				if not (pathIsKnown remove_lookup fPath) and not (pathIsKnown add_lookup fPath) do (
					append unique_additions fPath
					rememberPath add_lookup fPath
				)
			)
			ADD_PATHS = unique_additions
			
			-- delete entry
			format "Removing paths from External files list...\n"
			try (
				-- collect the indexes to be removed
				local rem_idx = for p in REMOVE_PATHS collect findPathIndex TEMP_PATHS p
				-- descending sort
				qsort rem_idx invSort
				-- remove the paths
				for i in rem_idx where i != 0 do (
					mapPaths.delete i
					format "->	%\n" TEMP_PATHS[i]
				)			
			) catch (
				messageBox "Unable to remove some paths."
				format "%\n" (getCurrentException())
				result = false
			)
			
			if result then (
				format "Adding paths to External files list...\n"
				try (
					local existing_lookup = makePathLookup TEMP_PATHS
					for p in ADD_PATHS where not (pathIsKnown existing_lookup p) do (
						mapPaths.add p
						rememberPath existing_lookup p
						format "->	%\n" p
					)
				) catch (
					messageBox "Unable to add some paths."
					format "%\n" (getCurrentException())
					result = false
				)
			)
			if result do refreshList()
			result
		)
		-----------------------------------------------------------------------------------------------
		-- open explorer
		fn openDir =
		(
			local itms = lst_mPath.SelectedItems.Item
			print (itms[0].Subitems.Item[1].text)
			ShellLaunch (itms[0].Subitems.Item[1].text) ""
		)
		-- Add to list
		fn path_adder paths =
		(
			local the_paths = deepcopy paths
			if (queryBox "Add subfolders too?") then (
				local the_filter = unsupplied
				if chk_sb.state then (
					the_filter = readStringArray txt_filter.text
					if the_filter == undefined then (
						messageBox "The subdirectory filter must be an array of quoted strings."
						return false
					)
				)
				for the_path in paths do (
					try (
						join the_paths (GetAllSubDirs the_path _filter:the_filter)
					) catch (
						messageBox ("Unable to scan subdirectories. " + (getCurrentException() as string))
						return false
					)
				)
			)
			local known_paths = makePathLookup (TEMP_PATHS + ADD_PATHS)
			local new_paths = #()
			for fPath in the_paths where not (pathIsKnown known_paths fPath) do (
				append new_paths fPath
				rememberPath known_paths fPath
			)
			join ADD_PATHS new_paths
			if new_paths.count > 0 do (
				local new_items = parse_items new_paths font:font_Bold
				if btn_4.state then (
					local visible_items = #()
					for item in new_items do (
						if item.SubItems.Item[3].Text == "OK" then
							append temp_listItemsCol item
						else
							append visible_items item
					)
					lstV_addItem lst_mPath visible_items
				) else (
					lstV_addItem lst_mPath new_items
				)
			)
			silentValue
		)
		fn resize x y =
		(
			lst_mPath.width = x 
			lst_mPath.height = y - 150
			
			btn_3.pos = [btn_3.pos.x, y - 140]
			btn_8.pos = [btn_8.pos.x, y - 140]
			btn_2.pos = [btn_2.pos.x, y - 140]
			btn_4.pos = [btn_4.pos.x, y - 140]
			btn_open.pos = [btn_open.pos.x, y - 140]
			
			chk_sb.pos = [chk_sb.pos.x, y - 115]
			txt_filter.pos = [txt_filter.pos.x, y - 115]
			
			sep1.pos = [sep1.pos.x, y - 83]
			btn_7.pos = [btn_7.pos.x, y - 77]
			chk_1.pos = [chk_1.pos.x, y - 77]
			chk_dupes.pos = [chk_dupes.pos.x, y - 77]
			chk_2.pos = [chk_2.pos.x, y - 77]
			chk_3.pos = [chk_3.pos.x, y - 77]
			chk_4.pos = [chk_4.pos.x, y - 77]
			txt_1.pos = [txt_1.pos.x, y - 77]
			
			sep2.pos = [sep2.pos.x, y - 41]
			
			btn_5.pos = [btn_5.pos.x, y - 35]
			btn_6.pos = [btn_6.pos.x, y - 35]
		)
		-----------------------------------------------------------------------
		-- Initialize
		on roll_mPath open do
		(
			sep1.bitmap = dividerImage()
			sep2.bitmap = dividerImage()
			-----------------------------------------------------------------------
			local HZ = (dotNetClass "HorizontalAlignment").Left
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
			-----------------------------------------------------------------------
			-- Add Columns
			lstV_addColumns lst_mPath #("Folder name", "Full fPath", "Files", "Status", "Type") autosize:True
			-- Add Items
			Init()
			--	lst_mPath.Items.Clear()
		)
		-- close
		on roll_mPath close do ( lst_mPath.Dispose(); gc())
		on roll_mPath resized size do
		(
			resize (size.x as integer) (size.y as integer)			
		)
		----------------------------------------------------------------------- Event handlers
		-- Change entry
		on lst_mPath MouseDoubleClick sender args do
		(
			local hitTest = (lst_mPath.HitTest args.X args.Y).Item

			if hitTest != undefined do
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
						appendIfUnique REMOVE_PATHS (the_item.Subitems.Item[1].text)
						-- add new to add list
						appendIfUnique ADD_PATHS new_path
						-- update listview
						the_item.Font = underline
						update_item the_item new_path
					)
				)
			)
		)
		-- Remove entry
		on btn_2 pressed do
		(
			local
			strikeout = dotNetObject dotNetFont (lst_mPath.Font) font_strk,
			regular = dotNetObject dotNetFont (lst_mPath.Font) font_reg,
			itms = lst_mPath.SelectedItems.Item,
			itms_count = lst_mPath.SelectedItems.count
			
			for i=0 to itms_count-1 do
			(
				local
					the_item = itms[i],
					item_path = the_item.Subitems.Item[1].Text,
					f_d = findItem REMOVE_PATHS item_path
				
				if f_d == 0 then
				(
					the_item.Font = strikeout
					the_item.ForeColor = removedPathColor
					appendIfUnique REMOVE_PATHS item_path
				)
			)
		)
		-- paste paths string
		on btn_8 pressed do
		(
			local roll = roll_PathEdit
			createDialog roll modal:true
			local response = roll.stored_values
			-- commit the paths
			if isKindOf response Array do path_adder response
		)
		-- add entry
		on btn_3 pressed do
		(
			folder_dialog.showDialog()
			local the_path = folder_dialog.SelectedPath
			if the_path != "" do path_adder #(the_path)
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
			local custom_extensions = #()
			local valid_custom_extensions = true
			if chk_4.checked then (
				custom_extensions = readStringArray txt_1.text
				if custom_extensions == undefined or custom_extensions.count == 0 then
					valid_custom_extensions = false
			)
			if not valid_custom_extensions then (
				messageBox "Custom extensions must be a non-empty array of quoted strings."
			) else (
				try (
					local strikeout = dotNetObject dotNetFont (lst_mPath.Font) font_strk
					local origin_paths = deepcopy TEMP_PATHS
					join origin_paths ADD_PATHS
					local filenames = for fPath in origin_paths collect (
						local extensions = #()
						if dotNetDirectory.exists fPath then (
							local files = getFiles (pathConfig.appendPath fPath "*.*")
							extensions = for file in files where (toLower (getFilenameType file)) != ".db" collect (toLower (getFilenameType file))
							extensions = makeUniqueArray extensions
						)
						extensions
					)
					local marked = #()
					if chk_1.checked do (
						join marked (for i=1 to filenames.count where filenames[i].count == 0 collect i)
					)
					local keep_extensions = #()
					if chk_2.checked do join keep_extensions img_ext
					if chk_3.checked do join keep_extensions md_ext
					if chk_4.checked do join keep_extensions custom_extensions
					if keep_extensions.count > 0 do (
						join marked (for i=1 to filenames.count where not (extensionsMatch filenames[i] keep_extensions) collect i)
					)
					local paths_lookup = makePathLookup #()
					local paths_list = #()
					for index in makeUniqueArray marked do (
						local fPath = origin_paths[index]
						if not (pathIsKnown paths_lookup fPath) do (
							append paths_list fPath
							rememberPath paths_lookup fPath
						)
					)
					if chk_dupes.checked then (
						local seen_paths = makePathLookup #()
						for fPath in origin_paths do (
							if pathIsKnown seen_paths fPath then (
								if not (pathIsKnown paths_lookup fPath) do (
									append paths_list fPath
									rememberPath paths_lookup fPath
								)
							) else (
								rememberPath seen_paths fPath
							)
						)
					)
					local items_by_path = dotNetObject "System.Collections.Hashtable"
					for i=0 to lst_mPath.Items.Count-1 do (
						local item = lst_mPath.Items.Item[i]
						local key = pathKey (item.Tag as string)
						if not (items_by_path.ContainsKey key) do items_by_path.Add key item
					)
					local remove_lookup = makePathLookup REMOVE_PATHS
					for fPath in paths_list do (
						local key = pathKey fPath
						if items_by_path.ContainsKey key then (
							local item = items_by_path.Item[key]
							item.Font = strikeout
							item.ForeColor = removedPathColor
						)
						if not (pathIsKnown remove_lookup fPath) do (
							append REMOVE_PATHS fPath
							rememberPath remove_lookup fPath
						)
					)
				) catch (
					messageBox ("Unable to clean the fPath list. " + (getCurrentException() as string))
				)
			)
		)
		-- accept
		on btn_5 pressed do
		(
			if (commit()) do DestroyDialog roll_mPath
		)
		--close
		on btn_6 pressed do (DestroyDialog roll_mPath)
		-- explore selected
		on btn_open pressed do (openDir())
	)
	CreateDialog roll_mPath lockWidth:true style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)
)