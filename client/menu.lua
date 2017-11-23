local menu = {}

local gui = require "gui"()
local nick, addr, err

local dnsResolver = love.thread.newThread [[
local channel = ...

local socket = require "socket"

while true do
	local host = channel:demand()
	host = host:match("^(.-)%:%d+$") or host
	local ip, err = socket.dns.toip(host)
	if ip then
		channel:push {ip = ip, info = err}
	else
		channel:push {err = err}
	end
end]]
local dnsChannel = love.thread.newChannel()
local connecting = {}

dnsResolver:start(dnsChannel)

local connect = function()
	local n = nick:getText()
	local a = addr:getText()

	local host, port = a:match("^(.-)%:(%d+)$")
	if not host then
		err:setLabel "Malformed URL"
	else
		port = port or 42069
	end

	dnsChannel:push(host)

	connecting = {resolving = host, nick = n, port = port}

end

local timer = 0

err  = gui:newLabel(32, 290, "", {255, 0, 0})
nick = gui:newTextLine(32, 310, connect, "Nickname", 178)
addr = gui:newTextLine(32, 340, connect, config.address and (config.address:match("%:%d+$") and config.address or (config.address .. ":42069")) or "nixo.la:42069", 178)


gui:newButton(148, 370, connect, "Connect!")


menu.update = function(self, dt)
	if connecting.resolving then
		local ip = dnsChannel:pop()
		if ip then
			local e
			connecting.resolving = nil
			connecting.ip = ip
			connecting.host, e = states.game:connect(connecting.nick, connecting.ip, connecting.port)
			if not connecting.host then
				connecting.ip = nil
				err:setLabel(e)
			end
		end
	end

	if connecting.ip then
		if states.game:update(dt) then
			connecting.ip = nil
			connecting.port = nil
			state = states.game
		end
	end

	local e = dnsResolver:getError()
	if e then
		err:setLabel("The resolver died: " .. e)
		connecting = {}
	end

	gui:update(dt)
end


menu.draw = function(self)
	if connecting.resolving then
		love.graphics.print("Resolving...")
	elseif connecting.ip then
		love.graphics.print("Connecting...")
	end
	gui:draw()
end


menu.mousepressed = function(self, x, y, b)
	gui:mousepressed(x, y, b)
end


menu.keypressed = function(self, k, kk)
	gui:keypressed(k, kk)
end


menu.textinput = function(self, char)
	gui:textinput(char)
end

return menu