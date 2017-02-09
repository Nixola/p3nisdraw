config = {}

enet = require "enet"
binser = require "binser.binser"

local load = function(args)
  if love then
    table.remove(arg, 1)
  end
  for i, v in ipairs(arg) do
    if v:match("^%-%-") then --option
      config[v:match("^%-%-(.-)$")] = true
    else --par
      local o = arg[i-1]:match("^%-%-(.-)$")
      if o then
        config[o] = v
      end
    end
  end

  if config.server then
    require "server.init"
  else
    require "client.init"
  end
end

if love then
  love.load = load
else
  load({...})
end