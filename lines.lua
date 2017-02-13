local lines = {}
local mt = {}

local buffer = {}

mt.__index = function(self, peerID)
  self[peerID] = {}
  print("First line of", peerID)
  return self[peerID]
end

return lines, buffer