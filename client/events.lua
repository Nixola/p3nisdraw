local events = {}

local lines = lines
local buffer = buffer
local tempLines = tempLines

local smooth = require "smooth"
local brush = require "brush"


events.start = function(event)
  -- PNG
  local fileData = love.filesystem.newFileData(event.png, "snapshot.png")
  local imgData = love.image.newImageData(fileData)
  local img = love.graphics.newImage(imgData)

  love.graphics.setColor(255, 255, 255)
  love.graphics.setCanvas(canvas)
    love.graphics.draw(img)
  love.graphics.setCanvas()

  -- Status
  lines = event.lines
  for i, peerLines in pairs(lines) do
    for ii, line in pairs(peerLines) do
      buffer[#buffer + 1] = line
    end
  end

  --Connected peers
  for _, p in ipairs(event.peers) do
  	peers_by.id[p.id] = p
  	peers_by.nick[p.nick] = p
  end

  -- ID
  selfID = event.id

end


events.create = function(event)

  local line = {
    id = event.lineID,
    peerID = event.peerID,
    size = event.size,
    startTime = event.time,
    order = event.order,
    color = event.color,
    text = event.text,
    smoothness = event.smoothness,
    brush = brushes[event.brush],
    len = 100,
    event.x, event.y
  }
  line.batch = love.graphics.newSpriteBatch(line.brush.img, line.len)
  print("Line from", event.peerID, lines[event.peerID])
  lines[event.peerID][event.lineID] = line
  buffer[#buffer + 1] = line

end


events.update = function(event)
  
  local line = lines[event.peerID][event.lineID]

  if line.text then
    line[1] = event.x
    line[2] = event.y
    line.text = event.text
    line.size = event.size
    line.color = event.color
    line.smoothness = event.smoothness
  else
    line[#line + 1] = event.x
    line[#line + 1] = event.y
    local t = smooth(line, line.smoothness)
    local b = line.brush:points(t)
    if line.batch then
      line.batch:clear()
    end
    if #b/2 > line.len then
    	while #b/2 > line.len do
    		line.len = line.len * 2
    	end
    	line.batch = love.graphics.newSpriteBatch(line.brush.img, line.len, "static")
    else
    	line.batch:clear()
    end
    for i = 1, #b/2 do
      line.batch:add(b[i*2-1], b[i*2])
    end
  end

end


events.delete = function(event)
  
  local line = lines[event.peerID][event.lineID]

  lines[event.peerID][event.lineID] = nil

  for i, v in pairs(buffer) do
    if v == line then
      table.remove(buffer, i)
      break
    end
  end

end


events.squash = function(event)

  print(("Squashing lines[%s][%s]"):format(event.peerID, event.lineID))

  local line = lines[event.peerID][event.lineID]

  love.graphics.setCanvas(canvas)

    if line.text then
      states.game:drawText(line)
    else
      states.game:drawLine(line)
    end

  love.graphics.setCanvas()

  events.delete(event)

end


events.finish = function(event)

  if event.peerID == selfID then
    tempLines[event.lineID] = nil
  end

  local line = lines[event.peerID][event.lineID]

  line.endTime = event.endTime

  for i, v in ipairs(event) do
    line[#line + 1] = v
  end

end


events.connect = function(event)

  --if event.peerID == selfID then print("Self connect") return end
  local p = {nick = event.nick, id = event.peerID, latency = event.latency}
  peers_by.id[event.peerID] = p
  peers_by.nick[event.nick] = p
  
  lines[event.peerID] = {}

end


events.disconnect = function(event)

	local p = peers_by.id[event.peerID]
	peers_by.nick[p.nick] = nil
	p.nick = ""

end


events.latency = function(event)
  
  for id, d in pairs(event.data) do
    local ping = d
    if peers_by.id[id] then
      peers_by.id[id].latency = ping
    end
  end

end


return events