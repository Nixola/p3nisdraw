config = {}

enet = require "enet"
binser = require "binser.binser"

pprint = require "pprint"

string.split = function(str, sep)
  assert(#sep == 1, "FUCK OFF")
  local t = {}
  for piece in str:gmatch("([^" .. sep .. "]+)") do
    t[#t+1] = piece
  end
  return t
end

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
    if love then
      love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";server/?.lua")
    end
    package.path = package.path .. ";./server/?.lua"
    require "init"
  else
    assert(love, "You can't run a client without LÖVE.")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";client/?.lua")
    package.path = package.path .. ";./client/?.lua"
    require "client.init"
  end
end

if love then
  love.load = load
else
  load({...})
end