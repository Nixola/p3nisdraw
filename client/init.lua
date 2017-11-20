require "love.event"
require "love.graphics"
require "love.image"
require "love.keyboard"
require "love.math"
require "love.mouse"

require "love.timer"
require "love.touch"
require "love.window"
--require "love.thread"

local smoothing = 0 --DEBUG

local CP = require "colorPicker"
local smooth = require "smooth"

config.address = config.address or "nixola.me"
config.port    = config.port    or 42069

--local host = enet.host_create(config.address .. ":" .. config.port)
local host = enet.host_create()
local server = host:connect(config.address .. ":" .. config.port)


local lineID = 0
local tempLine

tempLines = {}
lines = {}
buffer = {}

local events = require "events"

local colorPicker

love.window.setMode(1280, 720)

canvas = love.graphics.newCanvas(1280, 720)

love.graphics.setLineJoin("bevel")

local size, r, g, b, a = 3, 1, 1, 1, 1

love.update = function(dt)
  while true do
    local event = host:service(0)

    if event and event.type == "receive" then

      local t = binser.d(event.data)[1]
      events[t.type](t)

    else
      break
    end

  end

  if colorPicker then
    colorPicker:update()
  end
end


love.draw = function()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(canvas)

  local mx, my = love.mouse.getPosition()

  table.sort(buffer, function(a, b) return (a.order or math.huge) < (b.order or math.huge) end)

  for i, line in ipairs(buffer) do
    local c = line.color
    local r, g, b, a = unpack(c)
    r = r * 255
    g = g * 255
    b = b * 255
    a = (a or 1) * 255
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(line.size)
    love.graphics.circle("fill", line[1], line[2], line.size / 2, line.size)
    if #line >= 4 then
      local t = smooth(line, 3)
      love.graphics.circle("fill", line[#line-1], line[#line], line.size / 2, line.size)
      love.graphics.line(t)
    end
  end

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
end


love.keypressed = function(key, scan)
  if scan == "z" and love.keyboard.isDown("ctrl", "lctrl", "rctrl") then
    server:send(binser.s{type = "delete", lineID = lineID})
    lineID = lineID - 1
  elseif scan == "up" then
    smoothing = smoothing + 1
    print("Smoothing:", smoothing)
  elseif scan == "down" then
    smoothing = smoothing - 1
    smoothing = smoothing > 0 and smoothing or 0
    print("Smoothing:", smoothing)
  end
end


love.mousepressed = function(x, y, butt)
  if butt == 1 then -- create a line!
    lineID = lineID + 1
    tempLine = {size = size, color = {r, g, b, a}, x, y}
    local t = {type = "create", lineID = lineID, x = x, y = y, size = size, color = {r, g, b, a}}
    server:send(binser.s(t))
    tempLines[lineID] = tempLine
  elseif butt == 2 then
    CP:create(x - 192, y - 192, 192)
    colorPicker = CP
  end
end


love.mousemoved = function(x, y, dx, dy)
  if tempLine then -- we're drawing
    tempLine[#tempLine + 1] = x
    tempLine[#tempLine + 1] = y
    server:send(binser.s{type = "draw", lineID = lineID, x = x, y = y})
  end
end


love.wheelmoved = function(dx, dy)
  size = math.max(1, size + dy)
end

love.mousereleased = function(x, y, butt)
  if butt == 1 and tempLine then
    tempLine = nil
    --server:send(binser.s("f", lineID, x, y))
    server:send(binser.s{type = "finish", lineID = lineID, x = x, y = y})
  elseif butt == 2 then
    r, g, b = unpack(colorPicker.nc or colorPicker.sc)
    r = r / 255
    g = g / 255
    b = b / 255
    colorPicker = nil
  end

end