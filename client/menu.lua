local menu = {}
local DNS = require "dns"
local dns = DNS()

local gui = require "gui"()
local stop
local nick, addr, err, stopb

local connecting = {}

menu.helpString = [[
Hi! If you're reading this, you may be wondering how to use this wonderful piece of software.

First of all, connect to a server. Don't worry about choosing a fitting nickname, they're meaningless still. Once connected, you'll be able to draw on a shared canvas with whoever is connected to the same one! Use the mousewheel to change the size of your (opaque) brush, then hold and move to paint! Release when done. Holding right-click allows you to choose a colour!

Pressing enter you can even send text! If a message starts with / (forward slash) it will be parsed as a command and won't be sent. There's only one command right now, which is "star". It takes two arguments (radius and number of points) and it allows you to draw a regular star on the canvas, without having to patiently paint all the lines by yourself!

If you're on mobile sorry, but I'm too lazy to make a proper interface for you yet. You only get the ability to draw thin white lines.

I'm planning on expanding the UI (including, but not limited to, a mobile interface), so you're free to suggest me stuff to add/fix over at https://github.com/Nixola/p3nisdraw! (No clickable link because lazy.)

Enjoy!]]


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
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(gui.font[32])
	love.graphics.printf("Penisdraw III: Bigger than Unek's", 240, 16, 600, "left")
	local font = gui.font[12]
	love.graphics.setFont(font)
	love.graphics.printf(self.helpString, 240, 64, 600, "left")
	love.graphics.setColor(255, 255, 255, 192)
	local _, wrap = font:getWrap(self.helpString, 600)
	local height = font:getHeight() * #wrap
	love.graphics.line(230, 16, 230, 64 + height + 8)
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