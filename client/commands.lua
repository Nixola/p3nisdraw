local commands = {}

commands.star = function(radius, points, circled)
	points = tonumber(points)
	radius = tonumber(radius)
	if not (points and radius) then return end
	if (points <= 2) then return end
	local star = {}
	star.basePoints = {}
	local n = math.floor(points/2 + 1)
	for i = 0, points do
		local a = i * n/points * 2 * math.pi
		star.basePoints[i*2+1] = math.sin(a) * radius
		star.basePoints[i*2+2] = -math.cos(a) * radius
		print(i, star.basePoints[i*2+1], star.basePoints[i*2+2])
	end
	star.mousemoved = function(self, x, y, dx, dy)
		for i = 1, #self.basePoints/2 do
			self[i*2-1] = self.basePoints[i*2-1] + x
			self[i*2]   = self.basePoints[i*2]   + y
		end
	end
	star:mousemoved(love.mouse.getPosition())

	star.update = function(self, dt, size, r, g, b, a)
		self.size = size
		self.color[1] = r
		self.color[2] = g
		self.color[3] = b
		self.color[4] = a
	end

	star.send = function(self, lineID)
		local server = states.game.server
		--local t = {type = "create", lineID = lineID, x = x, y = y, size = size, color = {r, g, b, a}, smoothness = smoothness}
		server:send(binser.s{type = "create", lineID = self.lineID, x = self[1], y = self[2], color = self.color, size = self.size, smoothness = 0})
		server:send(binser.s{type = "finish", lineID = self.lineID, unpack(self, 3)})
	end

	return star
end

return commands