require "love.event"
require "love.graphics"
require "love.image"
require "love.keyboard"
require "love.math"
require "love.mouse"

require "love.timer"
require "love.touch"
require "love.window"

love.window.setMode(1280, 720)

tempLines = {}
lines = {}
buffer = {}

brushes = {}

peers_by = {
  nick = {},
  id = {}
}


states = {}
states.game = require "game"
states.menu = require "menu"

state = states.menu

canvas = love.graphics.newCanvas(1280, 720)
snapshot = love.graphics.newCanvas(1280, 720)

snap = function()
  love.graphics.setCanvas(snapshot)
  love.graphics.clear(0,0,0,1)
  states.game:draw(true)
  love.graphics.setCanvas()
end


love.graphics.setLineJoin("bevel")


love.update = function(dt)
  if state.update then
    state:update(dt)
  end
end

love.draw = function()
  if state.draw then
    state:draw()
  end
end

love.mousepressed = function(x, y, b)
  if state.mousepressed then
    state:mousepressed(x, y, b)
  end
end

love.keypressed = function(k, kk)
  if state.keypressed then
    state:keypressed(k, kk)
  end
end

love.textinput = function(char)
  if state.textinput then
    state:textinput(char)
  end
end

love.mousemoved = function(x, y, dx, dy)
  if state.mousemoved then
    state:mousemoved(x, y, dx, dy)
  end
end

love.mousereleased = function(x, y, b)
  if state.mousereleased then
    state:mousereleased(x, y, b)
  end
end

love.wheelmoved = function(wx, wy)
  if state.wheelmoved then
    state:wheelmoved(wx, wy)
  end
end

love.quit = function()
  if state.quit then
    state:quit()
  end
end