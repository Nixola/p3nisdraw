local events = {}

local lines = require "lines"

events.Create = function(event)
  local time = os.time()
  local order = os.clock()

  event.time = time
  event.order = order

  local line = {id = event.lineID, width = event.width, color = event.color, x, y}
  line.startTime = time
  line.order = order
