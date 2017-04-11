local events = {}

local lines = lines
local buffer = buffer
local tempLines = tempLines
local canvas = canvas


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
    event.x, event.y
  }
  lines[event.peerID][event.lineID] = line
  buffer[#buffer + 1] = line

end


events.draw = function(event)
  
  local line = lines[event.peerID][event.lineID]

  line[#line + 1] = event.x
  line[#line + 1] = event.y

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

  local c = line.color
  print(c[1] * 255, c[2] * 255, c[3] * 255, (c[4] or 1) * 255)
  love.graphics.setColor(c[1] * 255, c[2] * 255, c[3] * 255, (c[4] or 1) * 255)
  love.graphics.setLineWidth(line.size)
  love.graphics.setCanvas(canvas)

    love.graphics.circle("fill", line[1], line[2], line.size / 2, line.size)
    if #line >= 4 then
      love.graphics.circle("fill", line[#line - 1], line[#line], line.size / 2, line.size)
      love.graphics.line(line)
    end

  love.graphics.setCanvas()

  events.delete(event)

end


events.finish = function(event)

  if event.peerID == selfID then
    tempLines[event.lineID] = nil
  end

  lines[event.peerID][event.lineID].endTime = event.endTime

end


events.connect = function(event)
  
  lines[event.peerID] = {}

end


return events