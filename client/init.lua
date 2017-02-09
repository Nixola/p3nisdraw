require "love.event"
require "love.graphics"
require "love.image"
require "love.keyboard"

require "love.mouse"

require "love.timer"
require "love.touch"
require "love.window"
--require "love.thread"

local CP = require "colorPicker"

config.address = config.address or "nixola.me"
config.port    = config.port    or 42069

--local host = enet.host_create(config.address .. ":" .. config.port)
local host = enet.host_create()
local server = host:connect(config.address .. ":" .. config.port)

local self_id

local line_id = 0
local temp_line

local temp_lines = {}

local lines = {}

local buffer = {}

local colorPicker

love.window.setMode(1280, 720)

local canvas = love.graphics.newCanvas(1280, 720)

local size, r, g, b, a = 3, 1, 1, 1, 1

love.update = function(dt)
  while true do
    local event = host:service(0)

    if event and event.type == "receive" then
      --local t = {}

      --for part in event.data:gmatch("([^:]+)") do
      --  t[#t+1] = part
      --end

      local t = binser.d(event.data)

      local peer_id = t[2] 
      local line_id = t[3] -- clients can choose their own line IDs, as every client has its own table

      local peer_lines = lines[peer_id]
      if not peer_lines then
        peer_lines = {}
        lines[peer_id] = peer_lines
      end

      local line = peer_lines[line_id]

      if t[1] == "PNG" then
        local png = t[2]
        local fileData = love.filesystem.newFileData(png, "snapshot.png")
        local imgData = love.image.newImageData(fileData)
        local img = love.graphics.newImage(imgData)

        love.graphics.setColor(255, 255, 255)
        love.graphics.setCanvas(canvas)
          love.graphics.draw(img)
        love.graphics.setCanvas()

      elseif t[1] == "STATUS" then

        lines = t[2]
        for i, peer_lines in pairs(lines) do
          for ii, line in pairs(peer_lines) do
            buffer[#buffer + 1] = line
          end
        end

      elseif t[1] == "C" then -- creating a new line!

        local x, y, width, r, g, b, a, time = t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11]

        line = {id = line_id, width = width, time = time, x, y}
        line.color = {r, g, b, a}
        peer_lines[line_id] = line

        buffer[#buffer + 1] = line
      
      elseif t[1] == "d" then -- adding a new point to a line!

        line[#line+1] = tonumber(t[4])
        line[#line+1] = tonumber(t[5])

      elseif t[1] == "D" then -- deleting a line!

        peer_lines[line.id] = nil

      elseif t[1] == "S" then -- squashing a line!
        local line = peer_lines[line_id]

        if #line >= 4 then

          local c = line.color
          love.graphics.setColor(c[1] * 255, c[2] * 255, c[3] * 255, c[4] or 255)
          love.graphics.setLineWidth(line.width)
          love.graphics.setCanvas(canvas)
            love.graphics.line(line)
          love.graphics.setCanvas()

          peer_lines[line.id] = nil

          for i, v in ipairs(buffer) do
            if v == line then
              table.remove(buffer, i)
              break
            end
          end

        end

      elseif t[1] == "ID" then

        self_id = peer_id

      elseif t[1] == "f" then

        if self_id == peer_id then

          temp_lines[tonumber(line_id)] = nil

        end

      end

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

  table.sort(buffer, function(a, b) return a.time < b.time end)

  for i, line in ipairs(buffer) do
    if #line >= 4 then
      local c = line.color
      local r, g, b, a = unpack(c)
      r = r * 255
      g = g * 255
      b = b * 255
      a = (a or 1) * 255
      love.graphics.setColor(r,g,b,a)
      love.graphics.setLineWidth(line.width)
      love.graphics.line(line)
    end
  end

  for i, v in pairs(temp_lines) do
    if #v >= 4 then
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
    love.graphics.circle("fill", mx, my, size + 1, size * 2)
  else
    love.graphics.setColor(r * 255, g * 255, b * 255, a * 192)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", mx, my, size + 1, size * 2)
  end
end


love.mousepressed = function(x, y, butt)
  if butt == 1 then -- create a line!
    line_id = line_id + 1
    temp_line = {size = size, color = {r, g, b, a}, x, y}
    --server:send("C:" .. line_id .. ":" .. x .. ":" .. y .. ":3:1:1:1:1")
    server:send(binser.s("C", line_id, x, y, size, r, g, b, a))
    server:send(binser.s("d", line_id, x, y))
    temp_lines[line_id] = temp_line
  elseif butt == 2 then
    CP:create(x - 192, y - 192, 192)
    colorPicker = CP
  end
end


love.mousemoved = function(x, y, dx, dy)
  if temp_line then -- we're drawing
    temp_line[#temp_line + 1] = x
    temp_line[#temp_line + 1] = y
    --server:send("d:" .. line_id .. ":" .. x .. ":" .. y)
    server:send(binser.s("d", line_id, x, y))
  end
end


love.wheelmoved = function(dx, dy)
  size = math.max(1, size + dy)
end

love.mousereleased = function(x, y, butt)
  if butt == 1 and temp_line then
    temp_line = nil
    --server:send("f:" .. line_id)
    server:send(binser.s("f", line_id))
  elseif butt == 2 then
    r, g, b = unpack(colorPicker.nc or colorPicker.sc)
    r = r / 255
    g = g / 255
    b = b / 255
    print(r, g, b)
    colorPicker = nil
  end
  print(b)

end