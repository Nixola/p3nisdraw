local interface = {}


interface.spawn = function(self)
	self.gui = require "gui"()
	local listWidth = 32*4 + 2*5 -- four elements, five padding bits
	local listHeight = 48 * 8.5 + 2*9 -- 8½ elements, nine padding bits

	self.brushList = self.gui:newList(1280 - listWidth - 8, 96, listWidth, listHeight, "grid", 32, 48)
end

interface.show = function(self)
	if not self.gui then
		self:spawn()
	end
	self.shown = true
end

interface.hide = function(self)
	self.shown = false
end

interface.draw = function(self)

	love.graphics.setColor(32, 32, 32, 192)
	love.graphics.rectangle("fill", -0.5, -0.5, 161, 721)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(self.gui.font[12])

	love.graphics.print(string.format("%dms, %d KB/%d KB", states.game.server:round_trip_time(), math.floor(states.game.host:total_sent_data()/1024), math.floor(states.game.host:total_received_data()/1024)), 0, 0)

	local y = 0
	for id, peer in pairs(peers_by.id) do
		if peer.nick ~= "" then
			love.graphics.setColor(cacheRGB[id])
			love.graphics.print(peer.nick, 16, 96 + 16*y)
			love.graphics.print(peer.latency, 128, 96+16*y)
			y = y + 1
		end
	end
	self.gui:draw()
end


return interface