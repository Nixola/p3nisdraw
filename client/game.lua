local game = {}

local gui = require "gui"()

local CP = require "colorPicker"
local smooth = require "smooth"
local smoothness = 3

local nextID = 0
local lineID = 0
local textID = 0
local tempLine

local events = require "events"
local commands = require "commands"

local colorPicker

local textbox

local dbg

local size, r, g, b, a = 3, 1, 1, 1, 1

local randomRGB = love.math.newRandomGenerator()
local cacheRGB = setmetatable({}, {__index = function(self, k) randomRGB:setSeed(tonumber(k)); self[k] = {randomRGB:random(256)-1, randomRGB:random(256)-1, randomRGB:random(256)-1}; return self[k]; end})

game.connect = function(self, nick, address, port)

	self.host = enet.host_create()
	local result, r1 = pcall(self.host.connect, self.host, address .. ":" .. port)
	if not result then
		return nil, r1
	end
	self.server = r1
	self.connectPending = nick
	return self.host
end


game.drawLine = function(self, line, dbg)

  local c = line.color
  local r, g, b, a = unpack(c)
  r = r * 255
  g = g * 255
  b = b * 255
  a = (a or 1) * 255
  local t = line
  love.graphics.setColor(r,g,b,a)
  love.graphics.setLineWidth(line.size)
  love.graphics.circle("fill", line[1], line[2], line.size / 2, line.size)
  if #line >= 4 then
    t = smooth(line, line.smoothness)
    love.graphics.circle("fill", line[#line-1], line[#line], line.size / 2, line.size)
    love.graphics.line(t)
  end
  if dbg then
    local minX, minY, maxX, maxY = 1280, 720, 0, 0
    for i = 1, #t/2 do
      local x, y = t[i*2-1], t[i*2]
      minX = (x < minX) and x or minX
      minY = (y < minY) and y or minY
      maxX = (x > maxX) and x or maxX
      maxY = (y > maxY) and y or maxY
    end
    love.graphics.setColor(cacheRGB[line.peerID])
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", minX - line.size - 0.5, minY - line.size - 0.5, maxX - minX + line.size*2, maxY - minY + line.size*2)
    love.graphics.setFont(gui.font[10])
    local nick = peers_by.id[line.peerID].nick
    if nick == "" then
    	nick = "ID:" .. line.peerID
    end
    love.graphics.print(nick, math.floor(minX - line.size), math.floor(minY - line.size))
  end

end


game.drawText = function(self, text)

  local r, g, b, a = unpack(text.color)
  r = r * 255
  g = g * 255
  b = b * 255
  a = (a or 1) * 255
  love.graphics.setColor(r, g, b, a)
  love.graphics.setFont(gui.font[text.size])
  love.graphics.print(text.text, text[1], text[2])
end


game.update = function(self, dt)
  dbg = love.keyboard.isDown("tab")
  while true do
    local event = self.host:service(0)
    if self.connectPending and self.server:state() == "connected" then
    	print("Attempting connection")
    	self.server:send(binser.s{type = "connect", nick = self.connectPending})
    	self.connectPending = false
    end

    if event and event.type == "receive" then

      local t = binser.d(event.data)[1]
      print("Received event of type", t.type)
      events[t.type](t)
      if t.type == "start" then
        return true
      end

    else
      break
    end

  end

  if colorPicker then
    colorPicker:update()
  end
  if textbox then
  	gui:update(dt)
  	textbox:update(dt)
  end
  if tempLine and tempLine.update then
  	tempLine:update(dt, size, r, g, b, a)
  end
end


game.draw = function(self, snap)
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(canvas)
  love.graphics.setLineStyle("smooth")

  local mx, my = love.mouse.getPosition()

  table.sort(buffer, function(a, b) return (a.order or math.huge) < (b.order or math.huge) end)

  for i, line in ipairs(buffer) do
    if line.text then
      self:drawText(line, dbg)
    else
      self:drawLine(line, dbg)
    end

  end

  if snap then return end

  for i, v in pairs(tempLines) do
    local len = #v / 2
    if len >= 3 then
      local c = v.color
      local r, g, b, a = unpack(c)
      love.graphics.setColor(r * 255, g * 255, b * 255, a * 64)
      love.graphics.setLineWidth(size)
      love.graphics.line(v)
    end
  end

  if colorPicker then
    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle("fill", -1, -1, 1281, 721)
    love.graphics.setColor(255, 255, 255)
    colorPicker:draw()
    love.graphics.setColor(colorPicker.sc[1] * 255, colorPicker.sc[2] * 255, colorPicker.sc[3] * 255, a * 192)
    love.graphics.circle("fill", mx, my, size / 2 + 1, size)
  else
    love.graphics.setColor(r * 255, g * 255, b * 255, a * 192)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", mx, my, size / 2 + 1, size)
  end

  if textbox then
  	textbox:draw()
  end
end


game.keypressed = function(self, key, scan)
  if scan == "z" and love.keyboard.isDown("ctrl", "lctrl", "rctrl") then
    self.server:send(binser.s{type = "delete", lineID = nextID-1})
    nextID = nextID - 1
  elseif scan == "f12" then
  	snap()
  	local imgd = snapshot:newImageData()
  	local r = imgd:encode("png", os.time() .. ".png")
  elseif scan == "up" or scan == "down" then
  	smoothness = math.max(0, smoothness + (scan == "up" and 1 or -1))
  	print("Smoothness is now", smoothness)
  end

  if scan == "return" and not textbox then
  	textbox = gui:newTextLine(0, 0 - 6, nil, '', 1280, 720, 0, {center = {0,0,0,0}, border={0,0,0,0}, text={r*255,g*255,b*255,a*255}})
    local mx, my = love.mouse.getPosition()
    textID = nextID
    nextID = nextID + 1
    local t = {type = "create", lineID = textID, x = mx + 8, y = my - 8, size = size, color = {r, g, b, a}, text = ""}
    self.server:send(binser.s(t))

  	textbox.update = function(self, dt)
      self.size = size
      self.color.text[1], self.color.text[2], self.color.text[3], self.color.text[4] = r * 255, g * 255, b * 255, a * 255/4
  		self.x, self.y = love.mouse.getPosition()
      self.x = math.floor(self.x + 8)
      self.y = math.floor(self.y - self.font[self.size]:getHeight()/2)
      local t = {type = "update", lineID = textID, x = self.x, y = self.y, size = self.size, color = {r, g, b, a}, text = self.text}
      if self.text:match("^/") then return end
      states.game.server:send(binser.s(t))
  	end

    textbox:setEnterFunc(function(self)
      if self.text:match("^/") then
        local parts = self.text:split(" ")
        local cmd = parts[1]:match("^/(.-)$")
        table.remove(parts, 1)
        local i = 1
        while i < #parts do
          local p = parts[i]
          p = p:gsub("%\\(.)", "%1")
          if p:match("\\$") and parts[i+1] then
            parts[i] = p .. parts[i+1]
            table.remove(parts, i+1)
          else
            parts[i] = p
            i = i + 1
          end
        end
        local t = {type = "finish", lineID = textID, text = ""}
        local t2 = {type = "delete", lineID = textID}
        states.game.server:send(binser.s(t))
        states.game.server:send(binser.s(t2))
        if commands[cmd] then
        	local res = commands[cmd](unpack(parts))
        	if not tempLine and res then
        		lineID = nextID
        		tempLine = res
        		tempLine.lineID = lineID
        		tempLine.color = {r, g, b, a}
        		nextID = nextID + 1
        		tempLines[lineID] = tempLine
        	end
        end
      else
        self.size = size
        self.color.text[1], self.color.text[2], self.color.text[3], self.color.text[4] = r * 255, g * 255, b * 255, a * 255
        self.x, self.y = love.mouse.getPosition()
        self.x = math.floor(self.x + 8)
        self.y = math.floor(self.y - self.font[self.size]:getHeight()/2)
        local t = {type = "finish", lineID = textID, x = self.x, y = self.y, size = self.size, color = {r, g, b, a}, text = self.text}
        states.game.server:send(binser.s(t))
      end
      self:delete();
      textbox = nil;
    end)

  	textbox:update(0)
  	textbox.focus = true
    return
	end

  if textbox then
    textbox:keypressed(key, scan)
  end

  if scan == "escape" and textbox then
    local t = {type = "finish", lineID = textID, text = ""}
    local t2 = {type = "delete", lineID = textID}
    states.game.server:send(binser.s(t))
    states.game.server:send(binser.s(t2))
    textbox:delete()
    textbox = nil
  end
end


game.mousepressed = function(self, x, y, butt)
  if butt == 1 then
  	if not tempLine then-- create a line!
	    lineID = nextID
	    nextID = nextID + 1
	    tempLine = {size = size, color = {r, g, b, a}, x, y}
	    local t = {type = "create", lineID = lineID, x = x, y = y, size = size, color = {r, g, b, a}, smoothness = smoothness}
	    self.server:send(binser.s(t))
	    tempLines[lineID] = tempLine
	  else
	  	tempLine:send(x, y)
	  	tempLine = nil
	  end
  elseif butt == 2 then
    CP:create(x - 192, y - 192, 192)
    colorPicker = CP
  end

  if textbox then
  	textbox:mousepressed(x, y, butt)
  end
end


game.textinput = function(self, char)
	if textbox then
		textbox:typed(char)
	end
end

game.mousemoved = function(self, x, y, dx, dy)
  if tempLine then -- we're drawing
  	if tempLine.mousemoved then
  		tempLine:mousemoved(x, y, dx, dy)
  	else
    	tempLine[#tempLine + 1] = x
    	tempLine[#tempLine + 1] = y
    	self.server:send(binser.s{type = "update", lineID = lineID, x = x, y = y, smoothness = smoothness})
    end
  end
end


game.wheelmoved = function(self, dx, dy)
  size = math.max(1, size + dy)
end

game.mousereleased = function(self, x, y, butt)
  if butt == 1 and tempLine then
  	if tempLine.send then
  		tempLine:send(x, y)
  	else
  		self.server:send(binser.s{type = "finish", lineID = lineID, x = x, y = y})
  	end
    tempLine = nil
  elseif butt == 2 then
    r, g, b = unpack(colorPicker.nc or colorPicker.sc)
    r = r / 255
    g = g / 255
    b = b / 255
    colorPicker = nil
  end

end

game.quit = function(self)
	self.server:disconnect()
	self.host:flush()
end

return game