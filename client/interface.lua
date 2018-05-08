local interface = {}

local Gui = require "gui"

interface.spawn = function(self)
	self.spawned = true
	local game = require "game"
	local panels = {}
	self.panels = panels
	panels.brushes = Gui()
	local iw, ih = 56, 64
	local listWidth = iw * 3 + 4*4 -- elements, padding
	local listHeight = ih * 6.5 + 4*7 -- elements, padding

	self.brushList = panels.brushes:newList(1280 - listWidth - 8, 96, listWidth, listHeight, "grid", iw, ih)
	self.brushList.padding = 4
	local items = {}
	local active = false
	for i, v in pairs(brushes) do
		items[#items+1] = {img = v.img, text = v.name, active = v.active}
		active = active or v.active
	end
	self.brushList:insert(items)
	if not active then -- did no one update this shit?
		game:setBrush()
	end
	self.brushList:setCallback(function(x, y, n)
		game:setBrush(n)
	end)

	panels.settings = Gui()
	--panels.settings:newList(1280 - listWidth - 8, 96, listWidth, listHeight, "grid", iw, ih) --meant to be empty; background
	panels.settings:newSlider(1280 - listWidth, 104, 0, 255, 255, listWidth - 16, 8)
	self.panel = "brushes"

	self.gui = Gui()
	local i = 1
	for name, _ in pairs(panels) do
		self.gui:newButton(1280 - listWidth, 96 - 24*i, function() self.panel = name end, name)
		i = i + 1
	end
end

interface.show = function(self)
	if not self.spawned then
		self:spawn()
	end
	self.shown = true
end

interface.hide = function(self)
	self.shown = false
end

interface.draw = function(self)

	love.graphics.setColor(1/8, 1/8, 1/8, 6/8)
	love.graphics.rectangle("fill", -0.5, -0.5, 161, 721)
	love.graphics.setColor(1, 1, 1, 1)
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
	self.panels[self.panel]:draw()
end

interface.update = function(self, dt)
	self.gui:update(dt)
	self.panels[self.panel]:update(dt)
end

interface.mousepressed = function(self, x, y, b)
	self.gui:mousepressed(x, y, b)
	self.panels[self.panel]:mousepressed(x, y, b)
end

interface.wheelmoved = function(self, dx, dy)
	self.gui:wheelmoved(dx, dy)
	self.panels[self.panel]:wheelmoved(dx, dy)
end


return interface