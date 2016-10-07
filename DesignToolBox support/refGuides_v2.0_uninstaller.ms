(
	clearListener()
	-- USERFILES
	local mcr = getFiles @"$usermacros\HAG_refG*.mcr"
	local mse = getFiles @"$userscripts\refGuides\*.mse"
	local ms = getFiles @"$userscripts\refGuides\*.ms"
	local res = getFiles @"$userscripts\refGuides\*.res"
	local dll = getFiles @"$userscripts\refGuides\*.dll"
	local ui = getFiles @"$usericons\guideline_*.bmp"
	
	local delfiles = #(mcr,mse,ms,res,dll,ui)
	
	for i in delfiles do (
		if i != #() then (
			for f in i do (deleteFile f)
		)
	)
	messagebox "DONE!"
	
)