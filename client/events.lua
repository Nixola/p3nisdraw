local events = {}

local lines = lines
local buffer = buffer
local tempLines = tempLines

local smooth = require "smooth"
local brush = require "brush"

local interface = require "interface"


events.start = function(event)
  -- PNG
  local fileData = love.filesystem.newFileData(event.png, "snapshot.png")
  local imgData = love.image.newImageData(fileData)
  local img = love.graphics.newImage(imgData)

  love.graphics.setColor(255, 255, 255)
  love.graphics.setCanvas(canvas)
    love.graphics.draw(img)
  love.graphics.setCanvas()

  -- Brushes
  brushes = event.brushes
  for id, b in ipairs(brushes) do
  	local fdata = love.filesystem.newFileData(b.png64, b.name, "base64")
    local imgD = love.image.newImageData(fdata)
    imgD:mapPixel(function(r,g,b,a) return 255,255,255,b end)
    b.img = love.graphics.newImage(imgD)
  	--b.img = love.graphics.newImage(fdata)
  	brushes[id] = brush:new(b)
  end

  -- Status
  lines = event.lines
  for i, peerLines in pairs(lines) do
    for ii, line in pairs(peerLines) do
    	line.brush = brushes[line.brush]
      buffer[#buffer + 1] = line
      line.dirty = true
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
    dirty = true,
    event.x, event.y
  }

  --if not line.text then
  if line.brush then
    line.batch = love.graphics.newSpriteBatch(line.brush.img, line.len)
  end
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
    line.dirty = true
    --updateLineBatch(line)
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
  print("Finishing line", event.peerID, event.lineID, line)

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