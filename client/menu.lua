local menu = {}

local gui = require "gui"()
local nick, addr, err

local connect = function()
	local n = nick:getText()
	local a = addr:getText()

	local result, e = states.game:connect(n, a)
	if not result then
		err:setLabel(e)
	else
		state = states.game
	end
end

err  = gui:newLabel(32, 290, "", {255, 0, 0})
nick = gui:newTextLine(32, 310, function() connect() end, "Nickname", 178)
addr = gui:newTextLine(32, 340, function() connect() end, "nixo.la:42069", 178)



gui:newButton(148, 370, connect, "Connect!")


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


menu.textinput = function(self, char)
	gui:textinput(char)
end

return menu