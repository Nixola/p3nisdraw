local events = {}

local cairo = require "lgi".cairo
local surface = cairo.ImageSurface.create("ARGB32", 1280, 720)
local cr = cairo.Context.create(surface)

local smooth = require "smooth"

-- event handlers return a table of events. Every event in the table contains a boolean, "broadcast",
-- which specifies whether the returned event should be broadcast to everyone or not. If not, it's just
-- sent to the sender. The table is to be iterated in order, as the order of events (obviously) matters.

events.create = function(event)
  local time = os.time()
  local order = os.clock()

  event.time = time
  event.order = order

  print("Created line", event.peerID, event.lineID)

  local line = {lineID = event.lineID, size = event.size, color = event.color, peerID = event.peerID, event.x, event.y}
  line.startTime = time
  line.order = order

  lines[event.peerID][event.lineID] = line
  print("Line:", lines[event.peerID][event.lineID])
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
      local t = smooth(line, 3)
      returns[#returns + 1] = {type = "squash", lineID = line.lineID, peerID = line.peerID, broadcast = true}
      cr:move_to(t[1], t[2])
      for i = 2, #t / 2 do
        local x, y = t[i * 2 - 1], t[i * 2]
        cr:line_to(x, y)
      end

      cr.line_width = line.size
      cr.line_cap = "ROUND"
      cr:set_source_rgba(unpack(line.color))
      cr:stroke()

      table.remove(buffer, i)
      lines[line.peerID][line.lineID] = nil
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
  print("Finishing line", event.peerID, event.lineID)
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
  local event = {type = "start"}
  event.lines = lines
  event.id = peerID

  lines[peerID] = {}

  local filename = os.tmpname()
  surface:write_to_png(filename)

  local f = io.open(filename, "r")
  local png = f:read "*a"
  f:close()
  os.remove(filename)

  event.png = png

  local connect = {type = "connect"}
  connect.broadcast = true
  connect.peerID = peerID

  return {event, connect}
end


return events