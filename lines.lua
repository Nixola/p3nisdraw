local lines = {}
local mt = {}

mt.__index = function(self, peer_id)
  self[peer_id] = {}
  return self[peer_id]
end

