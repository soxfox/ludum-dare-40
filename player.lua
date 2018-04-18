local Entity = require 'entity'
local class = require 'middleclass'

local Player = class('Player', Entity)

function Player:initialize(x, y, world, collected)
  Entity.initialize(self, x, y, world, love.graphics.newImage('art/player.png'), 12, 16, 2, 0, 'player', true, love.graphics.newImage('art/playerlook.png'), false, collected)
end

function Player:update(dt, gravity, world)
  self.dead = false
  next = Entity.update(self, dt, gravity, world)
  if self.pos.y > 256 then
    self:die(world)
  end
  if love.keyboard.isDown('left') then
    self.look = 'left'
  elseif love.keyboard.isDown('right') then
    self.look = 'right'
  else
    self.look = nil
  end
  return next
end

function Player:check_enemy(col, world)
  if col.other.id == 'enemy' then
    self:die(world)
    return true
  end
end

return Player
