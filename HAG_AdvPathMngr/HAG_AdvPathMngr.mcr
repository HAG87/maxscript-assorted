/*
-------------------------------------------------------------------------------------------------------------------
Advanced UserPaths Manager v 1.0
HAG 2016
ATTRIBUTION / NON COMERCIAL / SHARE ALIKE
-------------------------------------------------------------------------------------------------------------------
*/
macroScript HAG_AdvPathMngr
	category:"HAG tools" 
	ButtonText:"APM" 
	toolTip:"Advanced External Files (User Paths) Manager"
	icon: #("UVWUnwrapOption",6)
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
		button btn_5 "Done" width:150 height:30 offset:[320,0] align:#right across:2
		button btn_6 "Cancel" width:150 height:30 align:#right
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local PathsCol = #()
		local only_invalid = false
		--
		local marked_to_delete = #()
		local marked_to_add = #()
		local marked_to_change = #()
		local marked_to_reorder = #()
		----------------------------------------------------------------------------------------------------------------------------------------------------
		local dotNetLstViewItemClass = dotNetClass "System.Windows.Forms.ListViewItem"
		local dotNetColor = dotNetClass "System.Drawing.Color"
		local dotNetFont = dotNetClass "System.Drawing.Font"
		local font_underline = (dotNetClass "System.Drawing.FontStyle").Underline
		local font_bold = (dotNetClass "System.Drawing.FontStyle").Bold
		local font_strk = (dotNetClass "System.Drawing.FontStyle").Strikeout
		local folder_dialog = dotnetobject "FolderBrowserDialog"
		local dotNetDirectory = dotnetclass "System.IO.Directory"

		local font_strikeout
		----------------------------------------------------------------------------------------------------------------------------------------------------
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
				lst.Items.AddRange itms
				lst.AutoResizeColumns (dotNetClass "ColumnHeaderAutoResizeStyle").ColumnContent
				lst.AutoResizeColumns (dotNetClass "ColumnHeaderAutoResizeStyle").HeaderSize
			)
		)
		----------------------------------------------------------------------------------------------------------------------------------------------------
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
			local mP_n = mapPaths.count()
			local mP_list = for i=1 to mP_n collect (mapPaths.get i)
			local result_items = parse_items mP_list
			if result_items != undefined then (
				lstV_addItem lst_mPath (result_items[1]) colorCol:(result_items[2])
			)
		)
		fn commit =
		(
			if queryBox "Commit changes ?" then (
				if marked_to_delete != #() then (for d in marked_to_delete do (mapPaths.delete d))
				if marked_to_change != #() then (
					for f in marked_to_delete do (mapPaths.delete f)
					for u in marked_to_change do (mapPaths.add u)
				)
				if marked_to_add != #() then (for a in marked_to_add do (mapPaths.add a))
				
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
		on roll_mPath close do
		(
			--  garbage collector...
			lst_mPath.Dispose()
			gc()
		)
		----------------------------------------------------------------------------------------------------------------------------------------------------
		-- Event handlers
		-- change items
		on btn_1 pressed do
		(
			local underline = dotNetObject dotNetFont (lst_mPath.Font) font_underline
			-- get items list
			local itms = lst_mPath.SelectedItems.Item
			local itms_count = lst_mPath.SelectedItems.count
			-- for each selected item...
			lst_mPath.BeginUpdate()
			for i=itms_count-1 to 0 by -1 do (
				----
				local the_item = itms[i]
				----
				local res = folder_dialog.showDialog()
				local new_path = folder_dialog.SelectedPath
				if new_path != "" then (
					the_item.Font = underline
					update_item the_item new_path
					------ mark for deletion and mark for add...
					append marked_to_delete the_item.Tag
					append marked_to_change new_path
				)
			)
			lst_mPath.EndUpdate()
		)
		-- Remove Items
		on btn_2 pressed do
		(
			local delete_mode = false
			local strikeout = dotNetObject dotNetFont (lst_mPath.Font) font_strk
			
			local itms = lst_mPath.SelectedItems.Item
			--local itms = lst_mPath.SelectedIndices.Item
			local itms_count = lst_mPath.SelectedItems.count
			-- begin update
			lst_mPath.BeginUpdate()
			case delete_mode of (
				true:
				(
					for i=itms_count-1 to 0 by -1 do (
						local the_item = itms[i]
						lst_mPath.Items.Remove(the_item)
						append marked_to_delete the_item.Tag
						/*
						For i = 0 To ListView1.SelectedItems.Count - 1   ' This is evaluated only ONCE :)
							MsgBox("Notice the updated count : " & ListView1.SelectedItems.Count.ToString)
							MsgBox("Deleting item : " & ListView1.SelectedItems(0).Text)
							ListView1.Items.RemoveAt(ListView1.SelectedItems(0).Index)
						Next
					--	*/
					)
					-- reapply items style
					local list_items = lst_mPath.Items
					for f=0 to (list_items.count)-1 do (
						list_items.Item[f].BackColor = if (bit.get f 1) then dotNetColor.Transparent else dotNetColor.LightGray
					)
				)
				false:
				(
					for i=itms_count-1 to 0 by -1 do (
						local the_item = itms[i]
						the_item.Font = strikeout
						append marked_to_delete the_item.Tag
					)
				)
			)
			-- end update
			lst_mPath.EndUpdate()
		)
		-- add items
		on btn_3 pressed do (
			local res = folder_dialog.showDialog()
			local the_path = folder_dialog.SelectedPath
			if the_path != "" then (
				-- add subfolders?
				local the_paths = #(the_path)
				if (queryBox "Add subfolders too?") then join the_paths (GetAllSubDirs the_path)
				local result_items = parse_items the_paths
				if result_items != undefined then (
					lstV_addItem lst_mPath (result_items[1]) colorCol:(result_items[2]) font:(font_Bold)
					-- mark for add
					join marked_to_add the_paths
				)
			)
		)

		on btn_4 pressed do (
			/*
			local col_class = dotNetClass "System.Windows.Data.CollectionViewSource"
			local col_obj = (dotNetObject col_class).GetDefaultView (lst_mPath.Items)
			*/
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
				lst_mPath.EndUpdate()
			)
		)
		-- accept
		on btn_5 pressed do (commit(); DestroyDialog roll_mPath)
		on btn_6 pressed do (DestroyDialog roll_mPath)
	)
		CreateDialog roll_mPath
)