local dns = {}

dns.threadCode = [[
local send, receive = ...

local socket = require "socket"

while true do
	local host = receive:demand()
	if host == false then return end
	host = host:match("^(.-)%:%d+$") or host
	local ip, err = socket.dns.toip(host)
	print("ip", ip)
	if ip then
		send:push {ip = ip, info = err}
	else
		send:push {err = err}
	end
end]]

dns.new = function(self)

	local t = {}
	t.thread = love.thread.newThread(self.threadCode)
	t.csend = love.thread.newChannel()
	t.crecv = love.thread.newChannel()
	t.thread:start(t.crecv, t.csend)

	setmetatable(t, {__index = self})
	return t
end


dns.resolve = function(self, hostname)
	self.csend:push(hostname)

end


dns.stop = function(self)
	self.csend:push(false)

end


dns.resolved = function(self)
	local e = self.thread:getError()
	if e then return nil, e end
	local ip = self.crecv:pop()
	if not ip then return false end
	if ip.err then return nil, ip.err end
	return ip.ip, ip.info
end


setmetatable(dns, {__call = dns.new})


return dns