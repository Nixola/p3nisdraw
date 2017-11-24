local menu = {}
local DNS = require "dns"
local dns = DNS()

local gui = require "gui"()
local stop
local nick, addr, err, stopb

local connecting = {}


local connect = function()
	if connecting.resolving or connecting.ip then return end
	local n = nick:getText()
	local a = addr:getText()

	local host, port = a:match("^(.-)%:(%d+)$")
	if not host then
		err:setLabel "Malformed URL"
		return
	else
		port = port or 42069
	end

	dns:resolve(host)

	connecting = {resolving = host, nick = n, port = port}

	stopb = gui:newButton(32, 390, stop, "Stop")

end


stop = function()
	dns:stop()
	dns = DNS()
	connecting = {}
	stopb:delete()
end


local timer = 0

err  = gui:newLabel(32, 290, "", {255, 0, 0})
nick = gui:newTextLine(32, 310, connect, "Nickname", 178)
addr = gui:newTextLine(32, 340, connect, config.address and (config.address:match("%:%d+$") and config.address or (config.address .. ":42069")) or "nixo.la:42069", 178)



gui:newButton(148, 370, connect, "Connect!")


menu.update = function(self, dt)
	timer = timer + dt
	if connecting.resolving then
		local ip, e = dns:resolved()
		if ip then
			local e
			connecting.resolving = nil
			connecting.host, e = states.game:connect(connecting.nick, ip, connecting.port)
			if not connecting.host then
				err:setLabel(e)
				stopb:delete()
			else
				connecting.ip = ip
			end
		end
	end


	if connecting.ip then
		if states.game:update(dt) then
			connecting.ip = nil
			connecting.port = nil
			stopb:delete()
			state = states.game
		end
	end

	gui:update(dt)
end


menu.draw = function(self)
	if connecting.resolving then
		love.graphics.setColor(192, 192, 0)
		love.graphics.printf("Resolving...", 32, 400, 178, "center")
	elseif connecting.ip then
		love.graphics.setColor(0, 192, 0)
		love.graphics.printf("Connecting...", 32, 400, 178, "center")
	end
	if connecting.resolving or connecting.ip then
		for i = -0.5, 0.5, 0.2 do
			local a = (math.cos((timer +i) % math.pi) + 1) * math.pi
			local x, y = 32 * math.sin(a) + 116, 32 * math.cos(a) + 456
			love.graphics.circle("fill", x, y, 3, 9)
		end
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