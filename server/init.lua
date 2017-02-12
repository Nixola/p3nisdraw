local cairo = require "lgi".cairo

config.address = config.address or "0.0.0.0"
config.port    = config.port    or 42069

local host = enet.host_create(config.address .. ":" .. config.port)

local surface = cairo.ImageSurface.create("ARGB32", 1280, 720)
local cr = cairo.Context.create(surface)

local buffer = {}

local lines = {}
local linesList = {}

table.clone = function(t) --shallow clone!
  local t2 = {}
  for i, v in pairs(t) do t2[i] = v end
  return t2
end

local relay = function(host, data, peer_id)
  table.insert(data, 2, peer_id)
  return host:broadcast(binser.s(unpack(data)))
  --return host:broadcast(data:gsub("^([^:]+:)", "%1" .. peer_id .. ":"), 0)
end


while true do
  local event = host:service(100)
  if event and event.type == "connect" then
    event.peer:send(binser.s("ID", event.peer:connect_id()))
    local time = math.floor(os.time() / 60)
    surface:write_to_png("snapshot-" .. time .. ".png")
    local pngFile = assert(io.open("snapshot-" .. time .. ".png"))
    local png = pngFile:read "*a"
    pngFile:close()
    event.peer:send(binser.s("PNG", png))
    event.peer:send(binser.s("STATUS", lines))
  end
  if event and event.type == "receive" then
    --local t = {}
    --for part in event.data:gmatch("([^:]+)") do
    --  t[#t+1] = part
    --end
    local t = binser.d(event.data)
    t.peer_id = event.peer:connect_id()

    local line_id = t[2] -- clients can choose their own line IDs, as every client has its own table
    local peer_id = event.peer:connect_id()


    local peer_lines = lines[peer_id]
    if not peer_lines then
      peer_lines = {}
      lines[peer_id] = peer_lines
    end

    if t[1] == "C" then -- creating a new line!
      print("Create", line_id, type(line_id), "by", peer_id)

      local x, y, width, r, g, b, a = t[3], t[4], t[5], t[6], t[7], t[8], t[9]
      local time = os.time()

      local line = {id = line_id, peer = peer_id, width = width, time = time, x, y}
      line.color = {r, g, b, a}
      peer_lines[line_id] = line
      buffer[#buffer + 1] = line

      --relay(host, event.data .. ":" .. time, peer_id)
      table.insert(t, time)
      relay(host, t, peer_id)

      table.sort(buffer, function(a, b) return a.time < b.time end)
      local i = 1
      while true do
        local line = buffer[i]
        if not line then break end
        if time - line.time > 120 then -- if the line is too old; squash
          host:broadcast(binser.s("S", peer_id, line_id))
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
          lines[line.peer][line.id] = nil
          i = i - 1
        end
        i = i + 1
      end
    
    elseif t[1] == "d" then -- adding a new point to a line!
      local line = peer_lines[line_id]
      if not line then
        print("Error! Missing line", line_id, "by", peer_id)
        return
      end
      line[#line+1] = tonumber(t[3])
      line[#line+1] = tonumber(t[4])

      relay(host, t, peer_id)

    elseif t[1] == "f" then -- finishing a line! ...not sure this needs to be explicit.
      --In fact, it's almost empty for now.

      relay(host, t, peer_id)

    elseif t[1] == "D" then -- deleting a line!
      print("Deleting", line_id)
      local line = peer_lines[line_id]
      for i, v in pairs(buffer) do
        if line == v then
          buffer[i] = nil
          break
        end
      end

      peer_lines[line_id] = nil

      relay(host, t, peer_id)
    end

  end
end