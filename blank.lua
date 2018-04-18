local class = require "middleclass"
local Entity = require "entity"

local Blank = class('Blank', Entity)

function Blank:initialize(x, y, world, id, ignore)
  Entity.initialize(self, x, y, world, nil, 1, 16, 0, 0, id, nil, nil, ignore)
end

function Blank.draw()
end

return Blank
