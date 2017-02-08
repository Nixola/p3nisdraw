local cairo = require "lgi".cairo

config.address = config.address or "0.0.0.0"
config.port    = config.port    or 42069

local host = enet.host_create(config.address .. ":" .. config.port)

local surface = cairo.ImageSurface.create("ARGB32", 1280, 720)
local cr = cairo.Context.create(surface)

local buffer = {}

local lines = {}
local linesList = {}

local relay = function(host, data, peer_id)
  return host:broadcast(data:gsub("^([^:]+:)", "%1" .. peer_id .. ":"), 0)
end

while true do
  local event = host:service(100)
  if event and event.type == "connect" then
    event.peer:send("ID:" .. event.peer:connect_id())
  end
  if event and event.type == "receive" then
    local t = {}
    local peer_id = event.peer:connect_id()
    for part in event.data:gmatch("([^:]+)") do
      t[#t+1] = part
    end

    local line_id = t[2] -- clients can choose their own line IDs, as every client has its own table


    local peer_lines = lines[peer_id]
    if not peer_lines then
      peer_lines = {}
      lines[peer_id] = peer_lines
    end

    if t[1] == "C" then -- creating a new line!

      print("Creating line", line_id, "by", peer_id)

      local x, y, width, r, g, b, a = tonumber(t[3]), tonumber(t[4]), tonumber(t[5]), tonumber(t[6]), tonumber(t[7]), tonumber(t[8]), tonumber(t[9])
      local time = os.time()

      local line = {id = line_id, width = width, time = time, x, y}
      line.color = {r, g, b, a}
      peer_lines[line_id] = line
      buffer[#buffer + 1] = line

      --host:broadcast(event.data:gsub("C:", "C:" .. peer_id .. ":")) -- broadcast the exact same event, but add the peer id as second field first
      relay(host, event.data .. ":" .. time, peer_id)
      --event.peer:send(event.data:gsub("^([^:]+:)", "%1" .. peer_id .. ":") .. ":" .. time)

      table.sort(buffer, function(a, b) return a.time < b.time end)
      for i = #buffer, 1, -1 do
        local line = buffer[i]
        if time - line.time > 120 then -- if the line is too old
          host:broadcast("S:" .. peer_id .. ":" .. line.id)
          cr:move_to(line[1], line[2])
          for i = 2, #line/2 do
            local x, y = line[i * 2 - 1], line[i * 2]
            cr:line_to(x, y)
          end

          cr.line_width = line.width
          cr.line_cap = "ROUND"
          cr:set_source_rgba(unpack(line.color))
          cr:stroke()

          table.remove(buffer, i)
          peer_lines[line.id] = nil
        end
      end
    
    elseif t[1] == "d" then -- adding a new point to a line!
      local line = peer_lines[line_id]
      print("Adding point to", line_id)
      line[#line+1] = tonumber(t[3])
      line[#line+1] = tonumber(t[4])

      relay(host, event.data, peer_id)

    elseif t[1] == "f" then -- finishing a line! ...not sure this needs to be explicit.
      --In fact, it's empty for now.

      relay(host, event.data, peer_id)

    elseif t[1] == "D" then -- deleting a line!
      local line = peer_lines[line_id]
      for i, v in pairs(buffer) do
        if line == v then
          buffer[i] = nil
          break
        end
      end

      peer_lines[line.id] = nil

      relay(host, event.data, peer_id)
    end

  end
end