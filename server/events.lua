local events = {}

local ffi = require "ffi"
local libpng = require "libpng"

local cairo = require "cairo"
local surface = cairo.image_surface("argb32", 1280, 720)
local cr = surface:context()
cr:font_face("Vera")
local smooth = require "smooth"
local base64 = require "base64"

local pr = function(s, stride)
	local i = 0
    for c in s:gmatch(".") do
    	if i == stride then
    		print()
    		i = 0
    	end
    	i = i + 1
    	io.write(string.format("%02X ", c:byte()))
    	--if i%4 == 0 then
    	--	io.write " "
      --end
    end
    print()
    print()
end

local pr_sur = function(s)
  print("Printing surface with stride", s:stride())
  local str = ffi.string(s:data(), s:height()*s:stride())
  pr(str, s:stride())
end

-- event handlers return a table of events. Every event in the table contains a boolean, "broadcast",
-- which specifies whether the returned event should be broadcast to everyone or not. If not, it's just
-- sent to the sender. The table is to be iterated in order, as the order of events (obviously) matters.

events.create = function(event)
  local time = os.time()
  local order = os.clock()

  event.time = time
  event.order = order
  event.smoothness = event.smoothness or 0

  print("Created line", event.peerID, event.lineID, "smoothness", event.smoothness)

  local line = {lineID = event.lineID, size = event.size, color = event.color, peerID = event.peerID, text = event.text, smoothness = event.smoothness, brush = event.brush, event.x, event.y}
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
    if line.endTime and (time - line.endTime > (tonumber(config.endTime) or 120)) then
      local t = line
      returns[#returns + 1] = {type = "squash", lineID = line.lineID, peerID = line.peerID, broadcast = true}
      if line.text then --it's text
      	cr:new_path()
        cr:font_size(line.size)
        local fextents = cr:font_extents()
        cr:move_to(t[1], t[2] + fextents.ascent)
        cr:rgba(unpack(line.color))
        cr:text_path(line.text)
        cr:fill()
      else
        local steps = smooth(line, line.smoothness)
      	steps = require "brush".points(nil, steps)
      	local b = brushes[line.brush]
      	print("Drawing", b.id, surfaces[b], b, cr:operator())
        --let's change the color of the brush
        cr:rgb(line.color[1], line.color[2], line.color[3])
      	for i = 1, #steps/2 do
      	  local x, y = steps[i*2-1], steps[i*2]
      	  cr:mask(surfaces[b], x, y)
      	end
      end

      table.remove(buffer, i)
      lines[line.peerID][line.lineID] = nil
      i = i - 1
    end

    i = i + 1
  end

  return returns
end


events.update = function(event)
  local line = lines[event.peerID][event.lineID]
  if not line then
    print("Error! Missing line", event.lineID .. " (" .. type(event.lineID) .. ")", "by", event.peerID)
    return
  end

  if line.text then
    line[1] = event.x
    line[2] = event.y
    line.text = event.text
    line.size = event.size
    line.color = event.color
  else
    line[#line + 1] = event.x
    line[#line + 1] = event.y
    line.smoothness = event.smoothness or line.smoothness
  end

  event.broadcast = true
  return {event}
end


events.finish = function(event)
  event.time = os.time()

  local line = lines[event.peerID][event.lineID]
  print("Finishing line", event.peerID, event.lineID)
  line.endTime = event.time
  for i, v in ipairs(event) do
    line[#line + 1] = v
  end

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


events.connect = function(event)

  local send = {}
  local nick = event.nick
  if nick == "" then
    nick = string.format("Guest - %08x", math.random(0x10000000, 0xffffffff))
  end
  local onick = nick
  local i = 1
  while peers_by.nick[nick] do --a user with the same nick is already logged in
    nick = onick .." - " .. i
    i = i + 1
  end
  local peerID = event.peerID
  local peer = peers_by.id[peerID]
  peers_by.nick[nick] = peer
  peer.nick = nick
  local ping = peer.obj:round_trip_time()
  peer.latency = ping
  local ev = {type = "start"}
  ev.lines = lines
  ev.id = peerID

  ev.peers = {}
  local n = 1
  for id, peer in pairs(peers_by.id) do
    ev.peers[n] = {nick = peer.nick, id = peer.id, latency = peer.latency}
    n = n + 1
  end
  local newBrushes = {}
  for i, b in ipairs(event.brushes) do
    local png = base64.decode(b.png64)
    local t = {string = png, header_only = true}
    local header = libpng.load(t).file
    if header.w > 256 or header.h > 256 then
      print("A brush exceeded max size; ignoring")
    elseif header.channels ~= "g" then
      print("A brush has invalid pixel format; ignoring")
    else
      t.header_only = false
      t.accept = {"g"}
      local image = libpng.load(t)
      local str = ffi.string(image.data, image.size)
      print("Brush pixel format", image.pixel, "stride", image.stride)
      if brushes_cache[str] then -- brush is already in memory
        print("Received a brush in memory")
      else
        brushes_cache[str] = true
        local id = #brushes + 1
        brushes[id] = b
        b.id = id
        newBrushes[id] = b
        local data = str
        --pr(str, 15)
        --data = data:gsub("(.)(.)(.)(.)", "")
        surfaces[b] = cairo.image_surface("a8", image.w, image.h)
        --fix the stride differences
        local dstride = surfaces[b]:stride() - image.stride
        local pattern = ("(%s)"):format(("."):rep(image.stride))
        local substit = string.format("%%1%s", ('0'):rep(dstride)) -- padding with zeroes. using actual null bytes fucked stuff up.
        data = data:gsub(pattern, substit)
        ffi.copy(surfaces[b]:data(), data)
        surfaces[b]:mark_dirty()
        surfaces[b]:save_png("/tmp/testbrush.png")
        print("W", image.w, "H", image.h, "stride", image.stride)
        --pr_sur(surfaces[b])
        print("Brush", id, surfaces[b], b)
      end
    end
  end
  ev.brushes = brushes

  lines[peerID] = {}

  local filename = os.tmpname()
  surface:save_png(filename)

  local f = io.open(filename, "r")
  local png = f:read "*a"
  f:close()
  --os.remove(filename)

  ev.png = png

  local connect = {type = "connect", nick = nick, latency = ping, newBrushes = newBrushes}
  print("Someone connected", ping)
  connect.broadcast = true
  connect.peerID = peerID

  send[#send+1] = ev
  send[#send+1] = connect

  return send
end


return events