local events = {}

local lines = lines
local buffer = buffer
local tempLines = tempLines

local smooth = require "smooth"


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

  -- ID
  selfID = event.id

end


events.create = function(event)

  local line = {
    id = event.lineID,
    size = event.size,
    startTime = event.time,
    order = event.order,
    color = event.color,
    text = event.text,
    smoothness = event.smoothness,
    event.x, event.y
  }
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

  if event.peerID == selfID then print("Self connect") return end
  
  lines[event.peerID] = {}

  print("Someone connected!", event.peerID, lines[event.peerID])

end


return events