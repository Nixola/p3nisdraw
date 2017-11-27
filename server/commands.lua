local commands = {}

commands.ban = function(ip)
	bans[ip] = true
end

commands.unban = function(ip)
	bans[ip] = nil
end

return commands