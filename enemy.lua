local Entity = require 'entity'
local class = require 'middleclass'

local Enemy = class('Enemy', Entity)

Enemy.speed = 1
function Enemy:initialize(x, y, world)
  Entity.initialize(self, x, y, world, love.graphics.newImage('art/enemy.png'), 10, 8, 3, 8, 'enemy', false, love.graphics.newImage('art/enemylook.png'))
  self.look = 'left'
end

function Enemy:update(dt, gravity, world)
  if self.pos.y > 256 then
    world:update(self, self.origin.x, self.origin.y)
    self.pos = self.origin
    self.vel = {x = 0, y = 0}
  end
  if self.look == 'left' then
    self.pos.x = self.pos.x - Enemy.speed
  else
    self.pos.x = self.pos.x + Enemy.speed
  end
  local function filt(item, other)
    return item.collide and not other.ignore and 'slide' or 'cross'
  end
  x, y, cols, len = world:move(self, self.pos.x, self.pos.y, filt)
  for i, col in ipairs(cols) do
    if col.other.id == 'left' then
      self.look = 'right'
    end
    if col.other.id == 'right' then
      self.look = 'left'
    end
    if col.other.id == 'player' then
      col.other:die(world)
    end
  end
  self.pos = {x = x, y = y}
  self:update_world(dt, gravity, world)
end

return Enemy
