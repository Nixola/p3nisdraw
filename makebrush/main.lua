printf = function(s, ...)
	print(s:format(...))
end

love.load = function(arg, args)
	if #args < 2 then
		printf("Usage: %s %s [--love11] <png file> [brush name]", args[-2], args[1])
		love.event.quit()
		return
	end

	for i = #args, 1, -1 do
		local v = args[i]
		if v:match("^%-%-") then
			var = v:match("^%-%-(%S+)")
			_G[var] = true
			print("Removing", v, i)
			table.remove(args, i)
		end
	end
	local filename = args[2]
	local brushname = args[3] or filename:gsub("%.png$", ""):gsub("brush", ""):gsub("_", " "):gsub("(%d+)", "[%1]"):match("^%s*(.-)%s*$")
	local brushfilename = brushname:lower():gsub(" ", "_"):gsub("[^a-zA-Z0-9_]", "") .. ".brush.lua"

	local f, e = io.open(filename, "r")
	if not f then
		printf("Error: could not open file %s (%s)", filename, e)
		love.event.quit()
	end

	local png = f:read "*a"
	f:close()

	local f, e = io.open(brushfilename, "w")
	f:write(("return {\n\tname = %q,\n\tpng64 = %q\n}"):format(brushname, love.data.encode("string", "base64", png)))
	f:close()

	love.event.quit()
end