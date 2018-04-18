local Entity = require 'entity'
local class = require 'middleclass'

local Crumble = class('Crumble', Entity)

function Crumble:initialize(x, y, world)
  Entity.initialize(self, x, y, world, love.graphics.newImage('art/crumble.png'), 16, 16, 0, 0, 'crumble')
  self.t = 0
  self.sp = 0.8
end

function Crumble:update(dt, gravity, world)
  if self.t ~= 0 then
    self.t = self.t + dt
    self.ox = math.random(-1, 1)
  end
  if self.t < self.sp then
    Entity.update_world(self, dt, {x = 0, y = 0}, world)
  else
    self.collide = false
    Entity.update_world(self, dt, gravity, world)
  end
  if self.t > 2 then
    self.collide = true
    self.t = 0
    self.pos = self.origin
    self.vel = {x = 0, y = 0}
    self.ox = 0
    world:update(self, self.origin.x, self.origin.y)
  end
end

return Crumble
