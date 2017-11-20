local events = require "events"

lines = {}
buffer = {}

config.address = config.address or "0.0.0.0"
config.port    = config.port    or 42069

local host = enet.host_create(config.address .. ":" .. config.port)

local relay = function(host, data, peerID)
  table.insert(data, 2, peerID)
  return host:broadcast(binser.s(unpack(data)))
  --return host:broadcast(data:gsub("^([^:]+:)", "%1" .. peerID .. ":"), 0)
end


while true do
  local event = host:service(100)
  local send
  if event and event.type == "connect" then
     send = events.connect(event.peer:connect_id())
  
  elseif event and event.type == "receive" then
    local result
    local t = binser.d(event.data)[1]
    t.peerID = event.peer:connect_id()

    result, send = pcall(events[t.type], t)
    if not result then
      print("Error in event", event.type, send)
      send = false
    end

  end

  if send then
    for i, ev in ipairs(send) do
      print("Sending event of type", "." .. ev.type .. ".")
      if ev.broadcast then
        host:broadcast(binser.s(ev))
      else
        event.peer:send(binser.s(ev))
      end
    end
  end

end