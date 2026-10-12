(
	-- One record per path. state: #unchanged | #added | #removed | #replaced
	-- origPath is the path as stored in mapPaths (undefined for newly added paths)
	struct PathEntry (id, path, origPath, state = #unchanged, leaf = "", exists = false, fileCount = "0", kind = "-")

	-- Holds all path data and pending changes. It has no UI dependency.
	-- Entries are never deleted, so entry.id is its index in "entries".
	struct PathModel
	(
		entries = #(),
		index = dotNetObject "System.Collections.Hashtable",     -- pathKey -> entry id
		fileCache = dotNetObject "System.Collections.Hashtable", -- pathKey -> file count
		filterInvalid = false,
		skippedCount = 0, -- illegal paths skipped by the last parsePaths

		fn pathKey fPath =
		(
			local key = toLower (substituteString fPath "/" "\\")
			while (key.count > 1) AND ((substring key key.count 1) == "\\") AND not (key.count == 3 AND (substring key 2 2) == ":\\") do (
				key = substring key 1 (key.count - 1)
			)
			key
		),
		fn dirExists fPath = ((dotNetClass "System.IO.Directory").exists fPath),
		fn countFiles fPath =
		(
			local key = pathKey fPath
			if fileCache.ContainsKey key then return fileCache.Item[key]
			if not (dirExists fPath) then return "0"
			local count = (getFiles (pathConfig.appendPath fPath "*.*")).count as string
			fileCache.Add key count
			count
		),
		fn extensionsMatch extensions allowed =
		(
			local found = false
			for extension in extensions while not found do (
				for candidate in allowed while not found do (
					if extension == (toLower candidate) do found = true
				)
			)
			found
		),
		-- id of the entry owning the path, 0 if unknown
		fn findByPath fPath =
		(
			local key = pathKey fPath
			if index.ContainsKey key then index.Item[key] else 0
		),
		fn refreshMeta entry =
		(
			entry.leaf = pathConfig.stripPathToLeaf entry.path
			entry.exists = dirExists entry.path
			entry.fileCount = countFiles entry.path
			entry.kind = if (pathConfig.isAbsolutePath entry.path) then "Absolute" else if (pathConfig.isUncPath entry.path) then "UNC" else "-"
		),
		fn makeEntry fPath orig state =
		(
			local entry = PathEntry id:(entries.count + 1) path:fPath origPath:orig state:state
			refreshMeta entry
			append entries entry
			local key = pathKey fPath
			if not (index.ContainsKey key) do index.Add key entry.id
			entry
		),
		fn reset =
		(
			entries = #()
			index.Clear()
			fileCache.Clear()
		),
		-- parse a text with paths separated by ; or new lines, returns the legal paths
		fn parsePaths str =
		(
			local stream = str as StringStream
			seek stream 0
			local pathsCol = #()
			skippedCount = 0
			while not eof stream do (
				local the_path = readDelimitedString stream ";\n"
				the_path = substituteString the_path "\r" ""
				the_path = substituteString the_path "\"" ""
				the_path = substituteString the_path "'" ""
				the_path = trimLeft (trimRight the_path)
				if the_path != "" then (
					local is_legal = pathConfig.isLegalPath the_path
					if not is_legal do is_legal = pathConfig.isLegalPath (pathConfig.resolvePathSymbols the_path)
					if is_legal then appendIfUnique pathsCol the_path else skippedCount += 1
				)
			)
			pathsCol
		),
		-- subdirectories of the given paths, optionally limited to names matching the patterns
		fn expandSubDirs paths patterns:unsupplied =
		(
			local dirClass = dotNetClass "System.IO.Directory"
			local searchAll = (dotNetClass "System.IO.SearchOption").AllDirectories
			local result = #()
			for p in paths do (
				for folder in (dirClass.GetDirectories p "*" searchAll) do (
					if patterns == unsupplied then append result folder
					else (
						local folder_name = (dotNetObject "System.IO.DirectoryInfo" folder).Name
						for pattern in patterns while (findItem result folder) == 0 do (
							if matchPattern folder_name pattern:pattern ignoreCase:true do append result folder
						)
					)
				)
			)
			result
		),
		-- read the current user paths from the scene
		fn load =
		(
			reset()
			for i=1 to mapPaths.count() do (
				local p = mapPaths.get i
				makeEntry p p #unchanged
			)
		),
		-- add new paths, returns the created entries
		fn addPaths paths =
		(
			local created = #()
			for p in paths where (findByPath p) == 0 do append created (makeEntry p undefined #added)
			created
		),
		fn markRemoved ids =
		(
			for id in ids do entries[id].state = #removed
		),
		-- change the path of an entry, returns false if nothing changed
		fn replacePath id newPath =
		(
			local entry = entries[id]
			local oldKey = pathKey entry.path
			local newKey = pathKey newPath
			if newKey == oldKey or (findByPath newPath) != 0 then return false
			if index.ContainsKey oldKey and index.Item[oldKey] == id do index.Remove oldKey
			index.Add newKey id
			entry.path = newPath
			refreshMeta ent
			entry.state = if ent.origPath == undefined then #added
				else if (pathKey ent.origPath) == newKey then #unchanged
				else #replaced
			true
		),
		fn visibleEntries =
		(
			for i in entries where ((not filterInvalid) or (not i.exists)) collect i
		),
		-- entry ids to be cleaned
		fn computeClean emptyFolders dupes keepExts =
		(
			local marked = #()
			local seen = dotNetObject "System.Collections.Hashtable"
			for entry in entries where entry.state != #removed do (
				local mark = false
				if emptyFolders or keepExts.count > 0 do (
					local exts = #()
					if entry.exists do (
						local files = getFiles (pathConfig.appendPath entry.path "*.*")
						exts = for file in files where (toLower (getFilenameType file)) != ".db" collect (toLower (getFilenameType file))
						exts = makeUniqueArray exts
					)
					if emptyFolders and exts.count == 0 do mark = true
					if keepExts.count > 0 and not (extensionsMatch exts keepExts) do mark = true
				)
				if dupes do (
					local key = pathKey entry.path
					if seen.ContainsKey key then mark = true else seen.Add key true
				)
				if mark do append marked entry.id
			)
			marked
		),
		fn pendingRemovals =
		(
			for i in entries where i.origPath != undefined and (i.state == #removed or i.state == #replaced) collect i.origPath
		),
		fn pendingAdditions =
		(
			for i in entries where i.state == #added or i.state == #replaced collect i.path
		),
		fn hasChanges =
		(
			(pendingRemovals()).count > 0 or (pendingAdditions()).count > 0
		),
		-- apply pending removals to the scene paths
		fn removeFromMapPaths =
		(
			local current = for i=1 to mapPaths.count() collect (pathKey (mapPaths.get i))
			local rem_idx = #()
			for p in pendingRemovals() do (
				local key = pathKey p
				local found = 0
				for i=1 to current.count while found == 0 do (
					if current[i] == key and (findItem rem_idx i) == 0 do found = i
				)
				if found != 0 do append rem_idx found
			)
			sort rem_idx
			for k=rem_idx.count to 1 by -1 do (
				format "->	%\n" (mapPaths.get rem_idx[k])
				mapPaths.delete rem_idx[k]
			)
		),
		-- apply pending additions to the scene paths
		fn addToMapPaths =
		(
			local existing = dotNetObject "System.Collections.Hashtable"
			for i=1 to mapPaths.count() do (
				local key = pathKey (mapPaths.get i)
				if not (existing.ContainsKey key) do existing.Add key true
			)
			for p in pendingAdditions() do (
				local key = pathKey p
				if not (existing.ContainsKey key) do (
					mapPaths.add p
					existing.Add key true
					format "->	%\n" p
				)
			)
		)
	)

	rollout roll_PathEdit  "Add Paths" width:500 height:300
	(
		local owner = if owner != undefined then owner
		local stored_values
		label lbl1 "Enter a list of paths separated by semicolons (;) or New Lines (\n). Paths can be quoted"
		edittext txt1 height:230
		button btn1 "Commit"  width:150 height:30
		on btn1 pressed do (
			-- commit paths
			local parser = PathModel()
			local paths = #()
			try (
				paths = parser.parsePaths txt1.text
				if parser.skippedCount > 0 do messageBox ("Skipped " + (parser.skippedCount as string) + " invalid fPath(s).")
			) catch (
				messageBox ("Unable to parse the paths. " + (getCurrentException() as string))
			)
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
		-- data model: the single source of truth, the listView only renders it
		local model
		-----------------------------------------------------------------------
		-- file extensions, add as needed
		local
			img_ext = #(".jpg",".jpeg",".png",".tif",".tiff",".tga",".bmp",".exr",".gif", ".hdr", ".hdri"),
			md_ext  = #(".3ds",".max",".obj",".fbx",".iges",".dwg",".dxf",".rvt",".skp")
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
			dotNetSort             = dotNetClass "System.Windows.Forms.SortOrder"
		-----------------------------------------------------------------------
		--	local dotNetContextMenuClass = dotNetClass "System.Windows.Forms.ContextMenu"
		-----------------------------------------------------------------------
		local
			validPathColor   = dotNetColor.Black,	--Seagreen,
			invalidPathColor = dotNetColor.Crimson,
			removedPathColor = dotNetColor.Goldenrod
		-----------------------------------------------------------------------
		-- UI text -> array of non-empty strings, undefined if invalid
		fn parseFilter text =
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
			for value in parsed do (
				if not (isKindOf value String) or value == "" then return undefined
			)
			parsed
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
			for f=0 to (list_items.count) - 1 do
			(
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
		-- Build a ListView item from a model entry
		fn entryToItem entry fonts =
		(
			local status = if entry.exists then "OK" else "MISSING"
			local item = dotNetObject dotNetLstViewItemClass #(entry.leaf, entry.path, entry.fileCount, status, entry.kind)
			item.tag = entry.id as string
			item.ForeColor = if entry.state == #removed then removedPathColor else if entry.exists then validPathColor else invalidPathColor
			case entry.state of (
				#removed:  item.Font = fonts[1]
				#replaced: item.Font = fonts[2]
				#added:    item.Font = fonts[3]
			)
			item
		)
		-- Ids of the selected entries
		fn selectedIds =
		(
			local ids = #()
			local selected = lst_mPath.SelectedItems
			for i=0 to selected.count-1 do append ids ((selected.Item[i].Tag as string) as integer)
			ids
		)
		-- Render the model into the listView
		fn renderAll keepIds:#() =
		(
			local fonts = for style in #(font_strk, font_underline, font_bold) collect (dotNetObject dotNetFont (lst_mPath.Font) style)
			local items = for entry in (model.visibleEntries()) collect (entryToItem entry fonts)
			-- remember the scroll position (first visible row)
			local topItem = lst_mPath.TopItem
			local topId = if topItem != undefined then ((topItem.Tag as string) as integer) else 0
			local topIndex = if topItem != undefined then topItem.Index else 0
			local newTop = undefined
			-- one redraw suspension around clear, fill and reselect
			lst_mPath.BeginUpdate()
			try (
				lst_mPath.Items.Clear()
				lstV_addItem lst_mPath items
				local count = lst_mPath.Items.Count
				for i=0 to count-1 do (
					local item = lst_mPath.Items.Item[i]
					local id = (item.Tag as string) as integer
					if keepIds.count > 0 and (findItem keepIds id) != 0 do item.Selected = true
					if id == topId do newTop = item
				)
				-- fall back to the same row position when the top entry is gone
				if newTop == undefined and count > 0 do newTop = lst_mPath.Items.Item[amin topIndex (count-1)]
				if newTop != undefined do lst_mPath.TopItem = newTop
			) catch (
				format "%\n" (getCurrentException())
			)
			lst_mPath.EndUpdate()
		)
		-- Reload the model from the scene and render it
		fn refreshList =
		(
			model.load()
			renderAll()
		)
		fn Init = ( refreshList() )
		-----------------------------------------------------------------------------------------------
		-- Commit changes to Paths
		fn commit =
		(
			local result = true
			if not (queryBox "Commit changes ?. This could take a while to process.") then return false

			format "Removing paths from External files list...\n"
			try (
				model.removeFromMapPaths()
			) catch (
				messageBox "Unable to remove some paths."
				format "%\n" (getCurrentException())
				result = false
			)

			if result then (
				format "Adding paths to External files list...\n"
				try (
					model.addToMapPaths()
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
			local ids = selectedIds()
			if ids.count > 0 do ShellLaunch (model.entries[ids[1]].path) ""
		)
		-- Add to list
		fn path_adder paths =
		(
			local the_paths = deepcopy paths
			if (queryBox "Add subfolders too?") then (
				local the_filter = unsupplied
				if chk_sb.state then (
					the_filter = parseFilter txt_filter.text
					if the_filter == undefined then (
						messageBox "The subdirectory filter must be an array of quoted strings."
						return false
					)
				)
				try (
					join the_paths (model.expandSubDirs paths patterns:the_filter)
				) catch (
					messageBox ("Unable to scan subdirectories. " + (getCurrentException() as string))
					return false
				)
			)
			if (model.addPaths the_paths).count > 0 do renderAll()
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
			model = PathModel()
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
			-- double buffering (protected property) to avoid flicker
			try (
				local flags = dotNet.combineEnums (dotNetClass "System.Reflection.BindingFlags").NonPublic (dotNetClass "System.Reflection.BindingFlags").Instance
				local prop = (lst_mPath.GetType()).GetProperty "DoubleBuffered" flags
				prop.SetValue lst_mPath true #()
			) catch ()
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
				local ids = selectedIds()
				local changed = false
				for id in ids do (
					folder_dialog.showDialog()
					local new_path = folder_dialog.SelectedPath
					if new_path != "" and (model.replacePath id new_path) do changed = true
				)
				if changed do renderAll keepIds:ids
			)
		)
		-- Remove entry
		on btn_2 pressed do
		(
			local ids = selectedIds()
			model.markRemoved ids
			renderAll keepIds:ids
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
			model.filterInvalid = state
			renderAll()
		)
		-- remove unwanted WIP
		on btn_7 pressed do
		(
			local custom_extensions = #()
			local valid_custom_extensions = true
			
			if chk_4.checked then (
				custom_extensions = parseFilter txt_1.text
				if custom_extensions == undefined or custom_extensions.count == 0 then
					valid_custom_extensions = false
			)
			if not valid_custom_extensions then (
				messageBox "Custom extensions must be a non-empty array of quoted strings."
			) else (
				try (
					local keep_extensions = #()
					if chk_2.checked do join keep_extensions img_ext
					if chk_3.checked do join keep_extensions md_ext
					if chk_4.checked do join keep_extensions custom_extensions
					model.markRemoved (model.computeClean chk_1.checked chk_dupes.checked keep_extensions)
					renderAll()
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