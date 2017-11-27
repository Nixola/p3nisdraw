local smooth = {}
smooth.smooth = function(line, smoothness)
	assert(#line >= 4 and #line % 2 == 0, "Invalid line")
	assert(smoothness, "Specify a smoothness you dumbass")
  local t = {}
  for ii = 1, (#line/2) do
    local x, y = line[ii*2-1], line[ii*2]
    local n = 1
    for iii = 1, smoothness do
      local x1, y1 = line[ii*2-iii*2-1], line[ii*2-iii*2]
      local x2, y2 = line[ii*2+iii*2-1], line[ii*2+iii*2]
      if x1 and y1 and x2 and y2 then
        n = n + 2
        x = x + x1
        y = y + y1
        x = x + x2
        y = y + y2
      end
    end
    t[#t+1] = x/n
    t[#t+1] = y/n
  end
  return t
end

return setmetatable(smooth, {__call = function(smooth, ...) return smooth.smooth(...) end})