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

love.graphics.setLineJoin("bevel")

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

      local peer_lines, line

      peer_lines = lines[peer_id]
      if not peer_lines and t[1] ~= "PNG" then
        print("No lines by", peer_id)
        peer_lines = {}
        lines[peer_id] = peer_lines
      end

      local line = peer_lines and peer_lines[line_id]
      if not line and t[1] ~= "C" and t[1] ~= "PNG" then
        print("Missing line", line_id, "by", peer_id)
        return
      end


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
            print("Added previous line", line.id, "by", line.peer)
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

        local line = peer_lines[line_id]
        peer_lines[line_id] = nil
        for i, v in pairs(buffer) do
          if line == v then
            table.remove(buffer, i)
            break
          end
        end

      elseif t[1] == "S" then -- squashing a line!
        local line = peer_lines[line_id]

        local c = line.color
        love.graphics.setColor(c[1] * 255, c[2] * 255, c[3] * 255, c[4] or 255)
        love.graphics.setLineWidth(line.width)
        love.graphics.setCanvas(canvas)
          love.graphics.circle("fill", line[1], line[2], line.width / 2, line.width)
          if #line >= 4 then
            love.graphics.circle("fill", line[#line-1], line[#line], line.width / 2, line.width)
            love.graphics.line(line)
          end
        love.graphics.setCanvas()

        peer_lines[line.id] = nil

        for i, v in ipairs(buffer) do
          if v == line then
            table.remove(buffer, i)
            break
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
    local c = line.color
    local r, g, b, a = unpack(c)
    r = r * 255
    g = g * 255
    b = b * 255
    a = (a or 1) * 255
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(line.width)
    love.graphics.circle("fill", line[1], line[2], line.width / 2, line.width)
    if #line >= 4 then
      local t = {}
      for ii = 1, (#line/2) do
        local x, y = line[ii*2-1], line[ii*2]
        local n = 1
        for iii = 1, smoothing do
          local x1, y1 = line[ii*2-iii*2-1], line[ii*2-iii*2]
          local x2, y2 = line[ii*2+iii*2-1], line[ii*2+iii*2]
          if x1 and y1 and x2 and y2 then
            n = n + 2
            x = x + x1
            y = y + y1
            x = x + x2
            y = y + y2
          end
        end
        t[#t+1] = x/n
        t[#t+1] = y/n
      end
      love.graphics.circle("fill", line[#line-1], line[#line], line.width / 2, line.width)
      love.graphics.line(smoothing and t or line)
    end
  end

  for i, v in pairs(temp_lines) do
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
    server:send(binser.s("D", line_id))
    line_id = line_id - 1
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
    line_id = line_id + 1
    temp_line = {size = size, color = {r, g, b, a}, x, y}
    --server:send("C:" .. line_id .. ":" .. x .. ":" .. y .. ":3:1:1:1:1")
    server:send(binser.s("C", line_id, x, y, size, r, g, b, a))
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
    server:send(binser.s("f", line_id, x, y))
  elseif butt == 2 then
    r, g, b = unpack(colorPicker.nc or colorPicker.sc)
    r = r / 255
    g = g / 255
    b = b / 255
    colorPicker = nil
  end

end