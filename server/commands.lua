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
	local ip = peers_by.obj[peer].ip
	print("Banned ip", ip)
	bans[ip] = true
	peer:reset()

end

commands.unban = function(ip)
	bans[ip] = nil
end

return commands