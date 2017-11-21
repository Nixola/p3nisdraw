local menu = {}

local gui = require "gui"()
local connect

local err  = gui:newLabel(32, 310, "", {255, 0, 0})

local nick = gui:newTextLine(32, 330, connect, "Nickname")
local addr = gui:newTextLine(32, 350, connect, "nixo.la:42069")

connect = function()
	local n = nick:getText()
	local a = addr:getText()

	local result, e = states.game:connect(n, a)
	if not result then
		err:setLabel(e)
	else
		state = states.game
	end
end

gui:newButton(32, 450, connect, "Connect!")


menu.update = function(self, dt)
	gui:update(dt)
end


menu.draw = function(self)
	gui:draw()
end


menu.mousepressed = function(self, x, y, b)
	gui:mousepressed(x, y, b)
end


menu.keypressed = function(self, k, kk)
	gui:keypressed(k, kk)
end


return menu