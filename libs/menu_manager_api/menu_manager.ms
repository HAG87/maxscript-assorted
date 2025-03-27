/*
-------------------------------------------------------------------------------------------------------------
    http://help.autodesk.com/view/3DSMAX/2018/ENU/?guid=__files_GUID_258F6015_6B45_4A87_A7F5_BB091A2AE065_htm

    MENU STRUCTURE
    ---------------
    mainMenubar
            -Menu-registered
            - Item-action
            - Item-action
            - Item-submenu
                - Item-action
                - Item-submenu
                    - Item-action
                    - ...
                - ...
            - ...
-------------------------------------------------------------------------------------------------------------
*/
(
    struct menuMan_api
    (
	/*
        - if <register_menu_context> is sucessfull... you can register a new menu in that context
        - if fails, either the context can't be registered or has already been defined
        - The context is unique for each menu
        - Use (genClassID())[1] to genereate a classID
        */
        fn register_menu_context classid: =
        (
            local res = false
            try (
                res = menuMan.registerMenuContext classid
            ) catch (
                format "%\n" (getCurrentException())
                return false
            )
            res
        ),
		--	Menu needs to be created to be able to add items to it
        fn menu_create_main title =
        (
            local mainMenuBar = menuMan.getMainMenuBar()
            local m = menuMan.createMenu title
            --	menu needs to be registered as submenu of the mainMenuBar
            local subMenuItem = menuMan.createSubMenuItem title m
            local subMenuIndex = mainMenuBar.numItems() - 1
            mainMenuBar.addItem subMenuItem subMenuIndex
            menuMan.updateMenuBar()
            m
        ),
        fn item_submenu_create title =
        (
            if title != "" then menuMan.createMenu title
        ),
        fn item_action_create ms_name ms_cat title: =
        (
            local item = menuMan.createActionItem ms_name ms_cat
            if title != unsupplied and title != "" then (
                item.setTitle title
                item.setUseCustomTitle true
            )
            item
        ),
		--	Items can be either an <Action Item> or a <Submenu Item>
        fn menu_add_item menu item =
        (
            menu.addItem item (-1)
            item
        ),
		fn menu_add_submenu menu submenu title: =
		(
			local the_title = if title == unsupplied then submenu.getTitle() else title
			this.menu_add_item menu (menuMan.createSubMenuItem the_title submenu)
		),
        fn item_create_add menu ms_name ms_cat title: =
        (
            local item = this.item_action_create ms_name ms_cat title:title
            this.menu_add_item menu item
            item
        ),
        fn menu_separator menu =
        (
            menu.addItem (menuMan.createSeparatorItem()) (-1)
        ),
        fn menu_find_in_bar title =
        (
            local mainMenuBar = menuMan.getMainMenuBar()
            local counter = mainMenuBar.numItems()
            local mnu_in_bar = false
            do (
                local item = mainMenuBar.getItem counter
                local t = item.getTitle()
                if t == title then (
                    mnu_in_bar = true
                    counter = 0
                ) else counter -= 1
            ) while (counter > 1)
            mnu_in_bar
        ),
        fn menu_register menu title =
        (
            --	check if exist in the MainMenu, if not, add it
            local menu_in_bar = this.menu_find_in_bar title
            if not mnu_in_bar then (
                local subMenuItem = menuMan.createSubMenuItem title menu
                --	compute the index of the next-to-last menu item in the main menu bar
                local subMenuIndex = mainMenuBar.numItems() - 1
                --	Add the sub-menu just at the second to last slot
                mainMenuBar.addItem subMenuItem subMenuIndex
                menuMan.updateMenuBar()
            )
            mnu_in_bar
        ),
        fn menu_reset title =
        (
           local the_menu = menuMan.findMenu title
           if the_menu != undefined then (
               local menu_itemcount = the_menu.numItems();
               if menu_itemcount > 0 then (
                   --	Remove menu items
                    for i = menu_itemcount to 1 by -1 do (
                        local item = the_menu.getItem i
                        --	if is a submenu... unimplemented
                        --	local submenu = item.getSubMenu()
                        the_menu.removeItem item
                    )
				menuMan.updateMenuBar()
               )
           )
        ),
		fn menu_remove title =
		(
			local res = false
			local the_menu = menuMan.findMenu title
			if the_menu != undefined then
			(
               local menu_itemcount = the_menu.numItems();
               if menu_itemcount > 0 then (
                   --	Remove menu items
                    for i = menu_itemcount to 1 by -1 do (
                        local item = the_menu.getItem i
                        --	if is a submenu... unimplemented
                        --	local submenu = item.getSubMenu()
                        the_menu.removeItem item
                    )
					--	unregister the menu
					--	This method allows you to remove a menu form the mananger. Returns false if the menu was not registered, true if successfully unregistered.
					--	<Interface>menu: Points to the menu to unregister.
					--	<boolean>menuMan.unRegisterMenu <Interface>menu 
					res = menuMan.unRegisterMenu the_menu
					menuMan.updateMenuBar()
               )
			)
			res
		),
        fn generate_menu title classid: =
        (
            local try_to_register = this.register_menu_context classid:classid
            local the_menu
            if try_to_register then (
                --	if context successful...
                the_menu = this.menu_create_main title
            ) else (
                --	context can exist but the menu can be deleted so...
                --	Check if menu exists
                the_menu = menuMan.findMenu title
                if (the_menu != undefined) then (
                    --	reset the menu or remove the menu					
                    --	this.menu_reset title
					this.menu_remove title
					--	register menu again
					this.register_menu_context classid:classid
					the_menu = this.menu_create_main title
                ) else (
                    the_menu = this.menu_create_main title
                )
            )
			menuMan.updateMenuBar()
            the_menu
        )
    )
    -- END STRUCT --
    menuMan_api()	
)