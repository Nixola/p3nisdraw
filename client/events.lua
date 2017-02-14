local events = {}


events.start = function(event)
  local fileData = love.filesystem.newFileData(event.png, "snapshot.png")
  local imgData = love.image.newImageData(fileData)
  local img = love.graphics.newImage(imgData)

  love.graphics.setColor(255, 255, 255)
  love.graphics.setCanvas(canvas)
    love.graphics.draw(img)
  love.graphics.setCanvas()

  lines = event.lines
  for i, peerLines in pairs(lines) do
    for ii, line in pairs(peerLines) do
      buffer[#buffer + 1] = line
      print("Added existing line", line.id, "by", line.peer)
    end
  end

  selfID = event.id