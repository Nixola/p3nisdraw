local commands = {}

commands.lua = function(...)
	local f, e = loadstring(table.concat({...}, " "))
	if not f then print(e) return end
	local r, e = pcall(f)
	if not r then print(e) return end
end

return commands