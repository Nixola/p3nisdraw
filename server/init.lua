local events = require "events"
local commands = require "commands"

local socket = require "socket" --I'm gonna need LuaSocket for non-blocking keyboard input. ew.
local input  = socket.tcp()
input:close()
input:setfd(0)
inputT = {input}

peers_by = {
  nick = {},
  ip = {},
  id = {}
}

local peer_id = {}

bans = {}

lines = {}
buffer = {}

brushes = {}
brushes_cache = {}
surfaces = {}

config.address = config.address or "0.0.0.0"
config.port    = config.port    or 42069

local time, otime = os.time(), os.time()

local host = assert(enet.host_create(config.address .. ":" .. config.port))

local relay = function(host, data, peerID)
  table.insert(data, 2, peerID)
  return host:broadcast(binser.s(unpack(data)))
  --return host:broadcast(data:gsub("^([^:]+:)", "%1" .. peerID .. ":"), 0)
end


while true do
  time = os.time()
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
        local id = event.peer:connect_id()
        local p = {id = id, ip = ip, obj = event.peer, latency = "n/a"}
        peers_by.ip[ip] = p
        peers_by.id[id] = p
        peer_id[event.peer] = id
        print("Connecting", id)
      end
    end
  elseif event and event.type == "receive" then
    local result
    local t = binser.d(event.data)[1]
    t.peerID = event.peer:connect_id()
    --print("Received event", t.type, "from", event.peer)

    if not events[t.type] then
      print("Received invalid event (" .. t.type .. "). Ignoring.")
      send = false
    end

    result, send = pcall(events[t.type], t)
    if not result then
      print("Error in event", event.type, send)
      send = false
    end
  elseif event and event.type == "disconnect" then
    local peerID = peer_id[event.peer]
    peer_id[event.peer] = nil
    local nick = peers_by.id[peerID].nick
    peers_by.nick[nick] = nil
    peers_by.id[peerID].nick = ""
    local ev = {type = "disconnect", peerID = peerID, broadcast = true}
    send = {ev}

    -- finish stagnant lines
    local endTime = os.time()
    for id, line in pairs(lines[peerID]) do
      local finishEvent = {peerID = peerID, endTime = endTime, lineID = id}
      send[#send + 1] = finishEvent
    end
  end

  if time ~= otime then --broadcast a latency update
    local t = {type = "latency", broadcast = true, data = {}}
    for id, p in pairs(peers_by.id) do
      if p.nick ~= "" then --the peer is online
        local ping = p.obj:round_trip_time()
        t.data[id] = ping
        p.latency = ping
      end
    end
    if send then --append the event
      send[#send+1] = t
    else -- need sendin'
      send = {t}
    end
  end


  if send then
    for i, ev in ipairs(send) do
      --print("Sending event of type", "." .. ev.type .. ".")
      if ev.broadcast then
        host:broadcast(binser.s(ev))
      else
        event.peer:send(binser.s(ev))
      end
    end
  end

  otime = time
end