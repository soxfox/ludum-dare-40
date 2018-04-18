local class = require "middleclass"
local vec = require "vector"

local Entity = class('Entity')

function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255
end

function Entity:initialize(x, y, world, image, w, h, ox, oy, id, trail, image2, ignore, collected)
  self.pos = {x = x+ox, y = y+oy}
  self.vel = {x = 0, y = 0}
  self.origin = {x = x+ox, y = y+oy}
  self.onground = false
  self.image = image
  self.ox = ox
  self.oy = oy
  self.w = w
  self.h = h
  world:add(self, x+ox, y+oy, w, h)
  self.collide = true
  self.id = id
  self.trail = {first = 0, last = -1}
  self.showtrail = trail
  self.lookimage = image2
  self.ignore = ignore
  self.collected = collected or 0
  self.trailimage = love.graphics.newImage('art/char.png')
end

function Entity:update(dt, gravity, world)
  local next = self:update_world(dt, gravity, world)
  self.trail.first = self.trail.first - 1
  self.trail[self.trail.first] = {x = self.pos.x-self.ox+self.w/2, y = self.pos.y-self.oy+self.h/2}
  if self.trail.last - self.trail.first > 16 then
    self.trail[self.trail.last] = nil
    self.trail.last = self.trail.last - 1
  end
  return next
end

function Entity:update_world(dt, gravity, world)
  local next = false
  local curX, curY = self.pos.x, self.pos.y
  self.vel = vec.add(self.vel, gravity)
  self.pos = vec.add(self.pos, self.vel)
  local function filt(item, other)
    return (item.collide and (other.collide ~= false) and not other.ignore) and 'slide' or 'cross'
  end
  x, y, cols, len = world:move(self, self.pos.x, self.pos.y, filt)
  for i, col in ipairs(cols) do
    if col.other.id == 'crumble' then
      col.other.t = col.other.t + dt
    end
    if col.other.id == 'door' then
      next = true
    end
    if col.other.id == 'char' then
      col.other:disable(world)
      self.collected = self.collected + 1
      self.trail = {first = 0, last = -1}
    end
    if self:check_enemy(col, world) then
      return
    end
  end
  if curY == y and self.vel.y ~= 0 then
    self.vel.y = 0
    self.onground = true
    self.candjump = false
  else
    self.onground = false
  end
  self.vel.x = self.vel.x * 0.7
  if curX == x then
    self.vel.x = 0
  end
  self.pos = {x = x, y = y}
  return next
end

function Entity:move(dx, dy)
  self.pos = vec.add(self.pos, {x = dx, y = dy})
  x, y, cols, len = world:move(self, self.pos.x, self.pos.y)
  self.pos = {x, y}
end

function Entity:push(dvx, dvy)
  self.vel = vec.add(self.vel, {x = dvx, y = dvy})
  if self.vel.y < -8 then
    self.vel.y = -8
  end
end

function Entity:draw(shad)
  if self.showtrail then
    love.graphics.setLineWidth(3)
    local points = {}
    for i = self.trail.first + 1, self.trail.last, 1 do
      local reli = i - self.trail.first
      local pos = self.trail[i]
      points[#points + 1] = pos.x
      points[#points + 1] = pos.y
    end
    for i = 1, #points, 2 do
      local p = {x = points[i], y = points[i+1]}
      if i % 8 == 7 and i / 8 <= self.collected then
        love.graphics.setColor(HSV((i-7)*8, 255, 255))
        love.graphics.draw(self.trailimage, math.floor(p.x), math.floor(p.y), 0, 1, 1, self.w/2, self.h/2)
      end
    end
  end
  if math.abs(self.vel.x) > 3 then
    love.graphics.setShader(shad)
    love.graphics.setColor(127, 200, 255)
  else
    love.graphics.setColor(255, 255, 255)
  end
  if self.look == 'left' and self.lookimage then
    love.graphics.draw(self.lookimage, math.floor(self.pos.x-self.ox), math.floor(self.pos.y-self.oy))
  elseif self.look == 'right' and self.lookimage then
    love.graphics.draw(self.lookimage, math.floor(self.pos.x-self.ox)+16, math.floor(self.pos.y-self.oy), 0, -1, 1)
  else
    love.graphics.draw(self.image, math.floor(self.pos.x-self.ox), math.floor(self.pos.y-self.oy))
  end
  love.graphics.setColor(255, 255, 255)
  love.graphics.setShader()
end

function Entity:die(world)
  self.pos = self.origin
  world:update(self, self.pos.x, self.pos.y)
  self.vel = {x = 0, y = 0}
  self.trail = {first = 0, last = -1}
  self.dead = true
end

function Entity:check_enemy(col, world)
  return false
end

return Entity
