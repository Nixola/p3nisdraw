local events = require "events"
local commands = require "commands"

local socket = require "socket" --I'm gonna need LuaSocket for non-blocking keyboard input. ew.
local input  = socket.tcp()
input:close()
input:setfd(0)
inputT = {input}

peers_by = {
  nick = {},
  ip = {}
}

bans = {}

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
  --handle keyboard input, if any
  local readable = socket.select(inputT, nil, 0)
  if readable[input] then
    local line = io.read("*l")
    local parts = line:split(" ")
    local cmd = parts[1]
    --table.remove(parts, 1)
    if commands[cmd] then
      commands[cmd](unpack(parts, 2))
    end
  end

  --then network input
  local event = host:service(100)
  local send
  if event and event.type == "connect" then
    local ip = tostring(event.peer)
    print("Incoming connection", ip)
    if not ip then
      print("Can't figure out IP. Like hell I'm letting this through.")
      event.peer:reset()
    else
      ip = ip:match("^(.-)%:%d+$")
      if bans[ip] then
        print("Banned IP attempted joining")
        event.peer:reset()
      else
        peers_by.ip[ip] = event.peer
      end
    end
  elseif event and event.type == "receive" then
    local result
    local t = binser.d(event.data)[1]
    t.peerID = event.peer:connect_id()
    print("Received event", t.type, "from", event.peer)

    if not events[t.type] then
      print("Received invalid event (" .. t.type .. "). Ignoring.")
      send = false
    end

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