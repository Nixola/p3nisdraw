local events = {}

local cairo = require "lgi".cairo
local surface = cairo.ImageSurface.create("ARGB32", 1280, 720)
local cr = cairo.Context.create(surface)

local lines, buffer = require "lines"

-- event handlers return a table of events. Every event in the table contains a boolean, "broadcast",
-- which specifies whether the returned event should be broadcast to everyone or not. If not, it's just
-- sent to the sender. The table is to be iterated in order, as the order of events (obviously) matters.

events.create = function(event)
  local time = os.time()
  local order = os.clock()

  event.time = time
  event.order = order

  local line = {lineID = event.lineID, width = event.width, color = event.color, peerID = event.peerID, event.x, event.y}
  line.startTime = time
  line.order = order

  local peerLines = lines[event.peerID]
  peerLines[event.lineID] = line
  buffer[#buffer + 1] = line

  table.sort(buffer, function(a, b)
    return a.startTime < b.startTime
  end)

  event.broadcast = true

  local returns = {event}
  local i = 1
  while true do
    local line = buffer[i]
    if not line then break end
    if line.endTime and (time - line.endTime > 120) then
      returns[#returns + 1] = {type = "squash", lineID = line.lineID, broadcast = true}
      cr:moveTo(line[1], line[2])
      for i = 2, #line / 2 do
        local x, y = line[i * 2 - 1], line[i * 2]
        cr:line_to(x, y)
      end

      cr.line_width = line.width
      cr.line_cap = "ROUND"
      cr:set_source_rgba(unpack(line.color))
      cr:stroke()

      table.remove(buffer, i)
      peerLines[line.id] = nil
      i = i - 1
    end

    i = i + 1
  end

  return returns
end


events.draw = function(event)
  local line = lines[event.peerID][event.lineID]
  if not line then
    print("Error! Missing line", event.lineID .. " (" .. type(event.lineID) .. ")", "by", event.peerID)
    return
  end

  line[#line + 1] = event.x
  line[#line + 1] = event.y

  event.broadcast = true
  return {event}
end


events.finish = function(event)
  event.time = os.time()

  local line = lines[event.peerID][event.lineID]
  line.endTime = event.time

  event.broadcast = true
  return {event}
end


events.delete = function(event)
  local line = lines[event.peerID][event.lineID]

  for i, v in ipairs(buffer) do
    if line == v then
      table.remove(buffer, i)
      break
    end
  end

  lines[event.peerID][event.lineID] = nil

  event.broadcast = true
  return {event}
end


events.connect = function(peerID) -- this is different
  local event = {}
  event.lines = lines
  event.id = peerID

  local filename = os.tmpname()
  surface:write_to_png(filename)

  local f = io.open(filename, "r")
  local png = f:read "*a"
  f:close()
  os.remove(filename)

  event.png = png

  return event
end