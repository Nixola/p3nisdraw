require "love.event"
require "love.graphics"
require "love.image"
require "love.keyboard"

require "love.mouse"

require "love.timer"
require "love.touch"
require "love.window"
--require "love.thread"

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

love.window.setMode(1280, 720)

local canvas = love.graphics.newCanvas(1280, 720)

love.update = function(dt)
  while true do
    local event = host:service(0)
    if event then
      print(event.type)
    end
    if event and event.type == "receive" then
      local t = {}

      for part in event.data:gmatch("([^:]+)") do
        t[#t+1] = part
      end

      local peer_id = t[2] 
      local line_id = t[3] -- clients can choose their own line IDs, as every client has its own table

      local peer_lines = lines[peer_id]
      if not peer_lines then
        peer_lines = {}
        lines[peer_id] = peer_lines
      end

      local line = peer_lines[line_id]

      if t[1] == "C" then -- creating a new line!

        local x, y, width, r, g, b, a, time = tonumber(t[4]), tonumber(t[5]), tonumber(t[6]), tonumber(t[7]), tonumber(t[8]), tonumber(t[9]), tonumber(t[10]), tonumber(t[11])
        print("Creating line", line_id, "created on", time)

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
end


love.draw = function()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(canvas)

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
      love.graphics.setColor(255, 255, 255, 64)
      love.graphics.line(v)
    end
  end
end


love.mousepressed = function(x, y, b)
  if b == 1 then -- create a line!
    line_id = line_id + 1
    temp_line = {x, y}
    server:send("C:" .. line_id .. ":" .. x .. ":" .. y .. ":3:1:1:1:1")
    temp_lines[line_id] = temp_line
  end
end


love.mousemoved = function(x, y, dx, dy)
  if temp_line then -- we're drawing
    temp_line[#temp_line + 1] = x
    temp_line[#temp_line + 1] = y
    server:send("d:" .. line_id .. ":" .. x .. ":" .. y)
  end
end


love.mousereleased = function(x, y, b)
  if b == 1 and temp_line then
    temp_line = nil
    server:send("f:" .. line_id)
  end
end