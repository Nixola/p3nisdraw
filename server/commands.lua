local commands = {}

commands.ban = function(ip)
	bans[ip] = true
	if peers_by.nick[ip] then
		peers_by.nick[ip]reset()
	end
	if peers_by.ip[ip] then
		peers_by.ip[ip]:reset()
	end
end

commands.unban = function(ip)
	bans[ip] = nil
end

return commands