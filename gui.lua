local utf8 = require "utf8"
local UTF8 = require "UTF8"

local clamp = function(min, X, max)

        if X < min then return max end
        if X > max then return max end
        return X
		
end

local round = function(x)

	return math.floor(x+.5)
	
end

local dist = function(x1, y1, x2, y2)

	return math.sqrt(((x1-x2)^2)+(y1-y2)^2)
	
end

local setLine = function(size, style)
	love.graphics.setLineWidth(size)
	love.graphics.setLineStyle(style)
end

local getCharAtX = function(font, string, mousex)
	local prevw = 0
	local c
	for i = 1, utf8.len(string) do
		local s = UTF8.sub(string, 1, i)
		local w = font:getWidth(s)
		if w > mousex then
			return i, (mousex - prevw) / (w - prevw)
		end
		prevw = w
		c = i
	end
	return c, 1
end


return function()

	local gui = {}
	gui.mt = {__index = gui}

	gui.load = function(self)

		self.__checkboxes = {}
		self.__labels = {}
		self.__buttons = {}
		self.__sliders = {}
		self.__textLines = {}
		self.__sliders2d = {}
		self.__radiobuttons = {}
		self.__drawables = {'checkboxes', 'labels', 'buttons', 'sliders', 'textLines', 'sliders2d'}
		self.__clickables = {'checkboxes', 'buttons', 'textLines', 'sliders', 'sliders2d'}
		self.__updateables = {'sliders', 'buttons', 'sliders2d'}
		self.__typeables = {'textLines'}
		
		love.keyboard.setKeyRepeat(0.25, 0.025)
		
	end

	gui:load()

	local white = {255,255,255}
	local black = {0,0,0}
	local grey = {}
	grey.c7 = {224,224,224}
	grey.c6 = {192,192,192}
	grey.c5 = {160,160,160}
	grey.c4 = {128,128,128}
	grey.c3 = {96,96,96}
	grey.c2 = {64,64,64}
	grey.c1 = {32,32,32}

	gui.font = setmetatable({}, {__index = function(t, i) if tonumber(i) then t[i] = love.graphics.newFont(i) return t[i] end end})

	gui.delete = function(self)
		self._delete = true
		gui.__delete = true
	end

	--#------#####--####---#####--#------#####--
	--#------#---#--#--#---#------#------#------
	--#------#####--#####--#####--#------#####--
	--#------#---#--#---#--#------#----------#--
	--#####--#---#--#####--#####--#####--#####--
	-----------------LABELS---------------------
		
	gui.label = {label = '', color = white, size = 12}
	setmetatable(gui.label, gui.mt)


	gui.label.draw = function(self)

		love.graphics.setFont(gui.font[self.size])
		
		love.graphics.print(self.label, self.x, self.y)
		
	end

	--Set methods

	gui.label.setX = function(self, x)

		self.x = x
		
	end


	gui.label.setY = function(self, y)

		self.y = y
		
	end


	gui.label.setPosition = function(self, x, y)

		self.x, self.y = x, y
		
	end


	gui.label.setColor = function(self, c)

		self.color = c
		
	end


	gui.label.setLabel = function(self, s)

		self.label = s
		
	end


	gui.label.setSize = function(self, s)

		self.size = s
		
	end

	--Get methods

	gui.label.getX = function(self)

		return self.x
		
	end


	gui.label.getY = function(self)

		return self.y
		
	end


	gui.label.getPosition = function(self)

		return self.x, self.y
		
	end


	gui.label.getColor = function(self)

		return self.color

	end


	gui.label.getLabel = function(self)

		return self.label
		
	end


	gui.label.getSize = function(self)

		return self.size
		
	end

	--#####--#---#--#####--#####--#--#--####---#####--#----#--#####--#####--
	--#------#---#--#------#------#-#---#--#---#---#---#--#---#------#------
	--#------#####--#####--#------##----#####--#---#----##----#####--#####--
	--#------#---#--#------#------#-#---#---#--#---#---#--#---#----------#--
	--#####--#---#--#####--#####--#--#--#####--#####--#----#--#####--#####--
	------------------------------CHECKBOXES--------------------------------

	gui.checkbox = {value = false, width = 12, height = 12, padding = 2, label = '', color = {border = white, check = white, label = white}, size = 12}
	setmetatable(gui.checkbox, gui.mt)


	gui.checkbox.clicked = function(self, b)

		if b == 1 then
		
			self.value = not self.value
			
		end
		
	end


	gui.checkbox.draw = function(self)

		love.graphics.setColor(self.color.border)
		
		love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
		
		if self.value then
		
			love.graphics.setColor(self.color.check)
			
			love.graphics.rectangle('fill', self.x+self.padding, self.y+self.padding, self.width-self.padding*2, self.height-self.padding*2)
			
		end
		
		love.graphics.setColor(self.color.label)
		
		love.graphics.setFont(gui.font[self.size])
		
		love.graphics.print(self.label, self.x+self.width+self.padding, self.y+self.padding)
		
	end

	--Set Methods

	gui.checkbox.setX = function(self, x)

		self.x = x
		
	end


	gui.checkbox.setY = function(self, y)

		self.y = y
		
	end


	gui.checkbox.setPosition = function(self, x, y)

		self.x, self.y = x, y
		
	end


	gui.checkbox.setWidth = function(self, w)

		self.width = w
		
	end


	gui.checkbox.setHeight = function(self, h)

		self.height = h
		
	end


	gui.checkbox.setDimension = function(self, w, h)

		self.width, self.height = w, h
		
	end


	gui.checkbox.setValue = function(self, v)

		self.value = v
		
	end


	gui.checkbox.setPadding = function(self, p)

		self.padding = p
		
	end


	gui.checkbox.setColor = function(self, c)

		self.color = c
		
	end


	gui.checkbox.setLabel = function(self, s)

		self.label = s
		
	end


	gui.checkbox.setTextSize = function(self, s)

		self.size = s
		
	end

	--Get methods

	gui.checkbox.getX = function(self)

		return self.x
		
	end


	gui.checkbox.getY = function(self)

		return self.y
		
	end


	gui.checkbox.getPosition = function(self)

		return self.x, self.y
		
	end


	gui.checkbox.getWidth = function(self)

		return self.width
		
	end


	gui.checkbox.getHeight = function(self)

		return self.height
		
	end


	gui.checkbox.getDimension = function(self)

		return self.width, self.height
		
	end


	gui.checkbox.getValue = function(self)

		return self.value
		
	end


	gui.checkbox.getPadding = function(self)

		return self.padding
		
	end


	gui.checkbox.getColor = function(self)

		return self.color
		
	end


	gui.checkbox.getLabel = function(self)

		return self.label
		
	end


	gui.checkbox.getTextSize = function(self)

		return self.size
		
	end


	--####---#---#--#####--#####--#####--#---#--#####--
	--#--#---#---#----#------#----#---#--##--#--#------
	--#####--#---#----#------#----#---#--#-#-#--#####--
	--#---#--#---#----#------#----#---#--#--##------#--
	--#####--#####----#------#----#####--#---#--#####--
	---------------------BUTTONS-----------------------

	gui.button = {label = '', padding = 2, color = {border = grey.c6, center = grey.c4, down = grey.c2, up = grey.c4, label = white}, size = 12, clicked = function() end}
	setmetatable(gui.button, gui.mt)


	gui.button.draw = function(self)

		love.graphics.setColor(self.color.center)
		
		love.graphics.rectangle('fill', self.x+1, self.y+1, self.width-2, self.height-2)
		
		love.graphics.setColor(self.color.border)
		
		love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
		
		love.graphics.setColor(self.color.label)
		
		love.graphics.setScissor(self.x+1+self.padding, self.y+1+self.padding, self.width-2-self.padding*2, self.height-2-self.padding*2)
		
		love.graphics.setFont(gui.font[self.size])
		
		love.graphics.print(self.label, self.x+1+self.padding, self.y+1+self.padding)
		
		love.graphics.setScissor()
		
	end


	gui.button.update = function(self, b, x, y)

		if x >= self.x and x <= self.x+self.width and y >= self.y and y <= self.y+self.height and b == 1 then
		
			self.color.center = self.color.down
			
		else
		
			self.color.center = self.color.up
			
		end
		
	end

	--Set methods

	gui.button.setX = function(self, x)

		self.x = x
		
	end


	gui.button.setY = function(self, y)

		self.y = y
		
	end


	gui.button.setPosition = function(self, x, y)

		self.x, self.y = x, y
		
	end


	gui.button.setWidth = function(self, w)

		self.width = w
		
	end


	gui.button.setHeight = function(self, h)

		self.height = h
		
	end


	gui.button.setDimension = function(self, w, h)

		self.width, self.height = w, h
		
	end


	gui.button.setClickedFunc = function(self, f)

		self.value = f
		
	end


	gui.button.setPadding = function(self, p)

		self.padding = p
		
	end


	gui.button.setColor = function(self, c)

		self.color = c
		
	end


	gui.button.setLabel = function(self, s)

		self.label = s
		
	end


	gui.button.setTextSize = function(self, s)

		self.size = s
		
	end

	--Get methods

	gui.button.getX = function(self)

		return self.x
		
	end


	gui.button.getY = function(self)

		return self.y
		
	end


	gui.button.getPosition = function(self)

		return self.x, self.y
		
	end


	gui.button.getWidth = function(self)

		return self.width
		
	end


	gui.button.getHeight = function(self)

		return self.height
		
	end


	gui.button.getDimension = function(self)

		return self.width, self.height
		
	end


	gui.button.getClickedFunc = function(self)

		return self.value
		
	end


	gui.button.getPadding = function(self)

		return self.padding
		
	end


	gui.button.getColor = function(self)

		return self.color
		
	end


	gui.button.getLabel = function(self)

		return self.label
		
	end


	gui.button.getTextSize = function(self)

		return self.size
		
	end


	--#####--#####--#---#--#####--#------#--#---#--#####--#####--
	----#----#-------#-#-----#----#---------##--#--#------#------
	----#----#####----#------#----#------#--#-#-#--#####--#####--
	----#----#-------#-#-----#----#------#--#--##--#----------#--
	----#----#####--#---#----#----#####--#--#---#--#####--#####--

	---------------------------TEXTLINES-------------------------

	gui.textLine = {text = '', padding = 2, color = {border = grey.c6, center = grey.c4, text = white}, size = 12, enter = function() end, cursorTime = 0}
	setmetatable(gui.textLine, gui.mt)


	gui.textLine.draw = function(self)

		setLine(1, 'smooth')
		
		love.graphics.setColor(self.color.center)
		
		love.graphics.rectangle('fill', self.x+1, self.y+1, self.width-2, self.height-2)
		
		love.graphics.setColor(self.color.border)
		
		love.graphics.rectangle('line', self.x, self.y, self.width, self.height)

		local labelWidth = love.graphics.getFont():getWidth(self.text)

		local preCursorWidth = love.graphics.getFont():getWidth(UTF8.sub(self.text, 1, self.cursor))
		
		local cursorX = preCursorWidth + self.printX

		local marginL, marginR = self.x + 1 + self.padding, self.x - labelWidth + self.width - self.padding

		local dx = cursorX - marginL
		
		if dx < 16 and self.printX < marginL then

			self.printX = self.printX + marginL + 16 - cursorX
			
		end

		if dx > self.width - self.padding - 16 and self.printX > marginR then
		
			self.printX = self.printX + self.x + self.width - cursorX - 15
			
		end

		self.printX = math.min(marginL, math.max(marginR, self.printX))
		cursorX = preCursorWidth + self.printX

		love.graphics.setColor(self.color.text)
		
		love.graphics.setScissor(self.x-1+self.padding, self.y+1+self.padding, self.width+2-self.padding*2, self.height-2-self.padding*2)
		
		love.graphics.setFont(gui.font[self.size])
		
		love.graphics.print(self.text, self.printX, self.y+1+self.padding)
		
		if self.cursorTime < 0.5 and self.focus then
		
			setLine(1, 'rough')
			
			love.graphics.line(cursorX, 1, cursorX, 1080)
			
		end
		
		love.graphics.setScissor()
		
	end


	gui.textLine.clicked = function(self, b, x, y)

		if b == 1 then
		
			self.focus = true

			local c, p = getCharAtX(gui.font[self.size], self.text, x - self.printX)

			self.cursor = c + math.floor(p + 0.5) - 1
			
		end
		
	end


	gui.textLine.typed = function(self, char)

		local p1, p2 = UTF8.sub(self.text, 1, self.cursor), UTF8.sub(self.text, self.cursor+1, utf8.len(self.text))
			
		self.text = p1 .. char .. p2
		
		self.cursor = self.cursor + 1
	end

	gui.textLine.keypressed = function(self, key, scancode)

		if key == 'left' then
		
			self.cursor = math.max(self.cursor - 1, 0)
			
		end
		
		if key == 'right' then
		
			self.cursor = math.min(self.cursor + 1, #self.text)
			
		end
		
		if scancode == 'backspace' and self.cursor ~= 0 then
		
			self.text = UTF8.sub(self.text, 1, self.cursor-1) .. UTF8.sub(self.text, self.cursor+1, -1)
			
			self.cursor = self.cursor-1
			
		end
		
		if scancode == 'delete' and self.cursor ~= utf8.len(self.text) then
		
			self.text = UTF8.sub(self.text, 1, self.cursor) .. UTF8.sub(self.text, self.cursor+2, -1)
			
		end
		
		if key == 'home' then
		
			self.cursor = 0
			
		end
		
		if key == 'end' then
		
			self.cursor = #self.text
			
		end
		
		if key == 'return' then
			
			self:enter()
			
		end

		if scancode == 'tab' then

			local newid = self.id % #self.__textLines + 1

			self.__textLines[newid].focus = true
			self.focus = false
			return true
		end

		
	end

	--Set methods

	gui.textLine.setX = function(self, x)

		self.x = x
		
	end


	gui.textLine.setY = function(self, y)

		self.y = y
		
	end


	gui.textLine.setPosition = function(self, x, y)

		self.x, self.y = x, y
		
	end


	gui.textLine.setWidth = function(self, w)

		self.width = w
		
	end


	gui.textLine.setHeight = function(self, h)

		self.height = h
		
	end


	gui.textLine.setDimension = function(self, w, h)

		self.width, self.height = w, h
		
	end


	gui.textLine.setTextSize = function(self, s)

		self.text = s
		
	end


	gui.textLine.setPadding = function(self, p)

		self.padding = p
		
	end


	gui.textLine.setColor = function(self, c)

		self.color = c
		
	end


	gui.textLine.setEnterFunc = function(self, f)

		self.enter = f
		
	end


	gui.textLine.setText = function(self, t)

		self.text = t
		
	end


	gui.textLine.setCursor = function(self, c)

		self.cursor = c
		
	end

	--Get methods

	gui.textLine.getX = function(self)

		return self.x
		
	end


	gui.textLine.getY = function(self)

		return self.y
		
	end


	gui.textLine.getPosition = function(self)

		return self.x, self.y
		
	end


	gui.textLine.getWidth = function(self)

		return self.width
		
	end


	gui.textLine.getHeight = function(self)

		return self.height
		
	end


	gui.textLine.getDimension = function(self)

		return self.width, self.height
		
	end


	gui.textLine.getTextSize = function(self)

		return self.text
		
	end


	gui.textLine.getPadding = function(self)

		return self.padding
		
	end


	gui.textLine.getColor = function(self)

		return self.color
		
	end


	gui.textLine.getEnterFunc = function(self)

		return self.enter
		
	end


	gui.textLine.getText = function(self)

		return self.text
		
	end


	gui.textLine.getCursor = function(self)

		return self.cursor
		
	end

		--]]

		
	--NEW!

	gui.newCheckbox = function(self, x, y, v, l, w, h, p, c, s)

		local t = {}
		
		t.x = x
		
		t.y = y
		
		t.value = v
		
		t.label = l
		
		t.width = w
		
		t.height = h
		
		t.padding = p
		
		t.color = c
		
		t.size = s
		
		t.id = #self.__checkboxes + 1
		
		t.type = 'checkboxes'
		
		setmetatable(t, {__index = function(t, i) return self.checkbox[i]end})
		
		table.insert(self.__checkboxes, t)
		
		return self.__checkboxes[t.id]
		
	end



	gui.newLabel = function(self, x, y, l, c, s)

		local t = {}
		
		t.x = x
		
		t.y = y
		
		t.label = l
		
		t.color = c
		
		t.size = s
		
		t.id = #self.__labels + 1
		
		t.type = 'labels'
		
		setmetatable(t, {__index = function(t,i) return self.label[i] end})
		
		table.insert(self.__labels, t)
		
		return self.__labels[t.id]
		
	end



	gui.newButton = function(self, x, y, f, l, w, h, p, c, s)

		local t = {}
		
		t.x = x
		
		t.y = y
		
		t.clicked = f
		
		t.label = l
		
		t.padding = p or self.button.padding
		
		t.color = c or {border = {}, center = {}, down = {}, up = {}, label = {}}
		
		t.size = s
		
		t.width = w or self.font[s or self.button.size]:getWidth(l or '')+t.padding*2+2
		
		t.height = h or self.font[s or self.button.size]:getHeight()+t.padding*2+2
		
		t.id = #self.__buttons + 1
		
		t.type = 'buttons'
		
		if not c then
		
			for i, v in pairs(t.color) do
			
				v[1] = gui.button.color[i][1]
				
				v[2] = gui.button.color[i][2]
				
				v[3] = gui.button.color[i][3]
				
			end
			
		end
		
		setmetatable(t, {__index = function(t,i) return self.button[i] end})
		
		table.insert(self.__buttons, t)
		
		return self.__buttons[t.id]
		
	end



	gui.newSlider = function(self, x, y, min, max, value, vert, w, h, slider, color)

		local t = {}
		
		t.x = x
		
		t.y = y
		
		t.min = min
		
		t.max = max
		
		t.value = value or (min+max)/2
		
		t.vert = vert
		
		t.height = h
		
		t.slider = slider
		
		t.color = color
		
		t.width = w or max
		
		t.id = #self.__sliders + 1
		
		t.type = 'sliders'
		
		setmetatable(t, {__index = function(t,i) return self.slider[i] end})
		
		table.insert(self.__sliders, t)
		
		return self.__sliders[t.id]
		
	end



	gui.newTextLine = function(self, x, y, enter, text, width, size, padding, color)

		local t = {}
		
		t.x = x
		
		t.y = y
		
		t.enter = enter
		
		t.text = text
		
		t.width = width or gui.font[size or self.textLine.size]:getWidth(t.text or self.textLine.text)
		
		t.height = gui.font[size or self.textLine.size]:getHeight() + (padding or self.textLine.padding)*2 + 2
		
		t.size = size
		
		t.padding = padding
		
		t.color = color or {border = {}, center = {}, text = {}}
		
		t.cursor = utf8.len(t.text)
		
		t.id = #self.__textLines + 1
		
		t.type = 'textLines'
		
		if not color then
		
			for i, v in pairs(t.color) do
			
				t.color[i][1] = gui.textLine.color[i][1]
				
				t.color[i][2] = gui.textLine.color[i][2]
				
				t.color[i][3] = gui.textLine.color[i][3]
				
			end
			
		end
		
		setmetatable(t, {__index = function(t,i) return self.textLine[i] end})

		t.printX = t.x + 1 + t.padding
		
		table.insert(self.__textLines, t)
		
		return self.__textLines[t.id]
		
	end



	gui.newSlider2d = function(self, x, y, Xmin, Xmax, Xvalue, Ymin, Ymax, Yvalue, sliderX, sliderY, w, h, slider, color, border)

		local t = {}
		
		t.x = x
		
		t.y = y
		
		t.Xmin = Xmin
		
		t.Xmax = Xmax
		
		t.Xvalue = Xvalue or (Xmin+Xmax)/2
		
		t.Ymin = Ymin
		
		t.Ymax = Ymax
		
		t.Yvalue = Yvalue or (Ymin+Ymax)/2
		
		t.height = h or Ymax-Ymin
		
		t.slider = slider
		
		t.color = color
		
		t.width = w or Xmax - Xmin
		
		t.sliderX = sliderX
		
		t.sliderY = sliderY
		
		t.id = #self.__sliders + 1
		
		t.type = 'sliders2d'
		
		setmetatable(t, {__index = function(t,i) return self.slider2d[i] end})
		
		table.insert(self.__sliders2d, t)
		
		return self.__sliders2d[t.id]
		
	end



	gui.update = function(self, dt)

		self.textLine.cursorTime = self.textLine.cursorTime + dt
		
		if self.textLine.cursorTime >= 1 then
		
			self.textLine.cursorTime = self.textLine.cursorTime - 1
			
		end
		
		local x, y = love.mouse.getPosition()
		
		local b = ''
		
		if love.mouse.isDown(1) then b = 1
		
		elseif love.mouse.isDown(2) then b = 2
		
		elseif love.mouse.isDown(3) then b = 3
		
		else b = nil
		
		end
		
		for i, v in pairs(self.__updateables) do
		
			for i, v in ipairs(self['__' .. v]) do
			
				v:update(b, x, y)
				
			end
			
		end
		
		if self.__delete then
		
			for i1, v in ipairs(self.__drawables) do
			
				local t = self['__'..v]
				
				for i2 = #t, 1, -1 do
				
					if t[i2]._delete then
					
						table.remove(t, i2)
						
					end
					
				end
				
			end
			
			self.__delete = false
			
		end
		
	end



	gui.mousepressed = function(self, x, y, b)

		for i, v in pairs(self.__clickables) do
		
			if v == 'textLines' then
			
				reset = function(v) v.focus = false end
				
			else
			
				reset = function() end
				
			end
			
			for i, v in ipairs(self['__' .. v]) do
			
				reset(v)
				
				if v.radius and dist(x, y, v.x, v.y) <= v.radius then
				
					v:clicked(b, x, y)
				
				elseif x >= v.x and x <= v.x+v.width and y >= v.y and y <= v.y+v.height then
				
					v:clicked(b, x, y)
					
				end
				
			end
			
		end
		
	end



	gui.keypressed = function(self, key, scan)

		for i, v in ipairs(self.__typeables) do
		
			for i, v in ipairs(self['__' .. v]) do
			
				if v.focus then
				
					self.textLine.cursorTime = 0
					
					if v:keypressed(key, scan) then break end
					
				end
				
			end
			
		end
		
	end


	gui.textinput = function(self, char)

		for i, v in ipairs(self.__typeables) do

			for i, v in ipairs(self['__' .. v]) do

				if v.focus then

					self.textLine.cursorTime = 0

					v:typed(char)

				end

			end

		end

	end



	gui.draw = function(self)

		local settings = {}
		
		setLine(1, 'smooth')
		
		for i1, v1 in pairs(self.__drawables) do
		
			for i2, v2 in ipairs(self['__' .. v1]) do
			
				v2:draw()
				
			end
			
		end
		
	end



	gui.erase = function(self)

		self:load()
		
	end

	return gui

end