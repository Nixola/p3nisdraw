config = {}

enet = require "enet"

love.load = function(args)
  table.remove(arg, 1)
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
    require "server"
  else
    require "client"
  end
end