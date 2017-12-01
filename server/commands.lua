local commands = {}

commands.ban = function(by, ip)
	if by and not ip then 
		ip, by = by, "ip" 
		print("Unspecified ban criteria, defaulting to ip")
	end
	--bans[ip] = true
	if by and not peers_by[by] then
		print("Error in ban:", by, "is invalid criteria")
		return
	end
	local peer = peers_by[by][ip]

	local ip = peer.ip
	print("Banned ip", ip)
	bans[ip] = true
	peer.obj:reset()

end

commands.unban = function(ip)
	bans[ip] = nil
end

commands.lua = function(...)
	local str = table.concat({...}, " ")
	local f, e = loadstring(str)
	if not f then print("Error loading:", e) return end
	local r, e = pcall(f)
	if not r then print("Error executing:", e) return end
	print(e)
end

return commands