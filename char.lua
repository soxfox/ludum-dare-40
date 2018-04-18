local Entity = require 'entity'
local class = require 'middleclass'

local Char = class('Char', Entity)

function Char:initialize(x, y, world, r, g, b)
  Entity.initialize(self, x, -256, world, love.graphics.newImage('art/char.png'), 12, 512, 2, 0, 'char')
  self.y = y
  self.color = {r, g, b}
  self.on = true
end

function Char:draw()
  love.graphics.setColor(self.color)
  love.graphics.draw(self.image, self.pos.x-self.ox, self.y)
  love.graphics.setColor(255, 255, 255)
end

function Char:disable(world)
  self.draw = function () end
  self.update = function () end
  world:remove(self)
  self.dead = true
end

return Char
