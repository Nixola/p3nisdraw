local brushes = {}

brushes.points = function(self, line)
	assert(#line >= 4, "Invalid line")
	local lengths = {[0] = 0}
	local length = 0
	for i = 1, #line/2-1 do
		local x1, y1, x2, y2 = unpack(line, i*2 - 1, i*2 + 2)
		local dx, dy = x2 - x1, y2 - y1
		local l = math.sqrt(dx*dx + dy*dy)
		length = length + l
		lengths[i] = length
	end

	local points = {}
	local segment = 1
	for t = 0, 1, self.step / length do
		while t*length > lengths[segment] do
			segment = segment + 1
		end

		local l1, l2 = lengths[segment-1] / length, lengths[segment] / length
		local portion = (t-l1)/(l2-l1)
		local x1, y1, x2, y2 = unpack(line, segment*2-1, segment*2+2)
		local px, py
		px = x2 * portion + x1 * (1-portion)
		py = y2 * portion + y1 * (1-portion)
		points[#points+1] = px
		points[#points+1] = py
	end
	return points
end


--[[brushes.new = function(self, png, step)
	local t = setmetatable({}, {__index = self})
	t.png = png
	t.step = step
	return t
end--]]
brushes.new = function(self, t)
	t.step = 3
	t.w = t.img:getWidth()
	t.h = t.img:getHeight()
	return setmetatable(t, {__index = self})
end

return brushes