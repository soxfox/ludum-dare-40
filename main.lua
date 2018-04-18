local w, h = 512, 512
local playerSpeed = 1.2
local jump = -8
local lowcanvas

local sti = require 'sti'
local bump = require 'bump'
local Entity = require 'entity'
local Player = require 'player'
local Enemy = require 'enemy'
local Crumble = require 'crumble'
local Blank = require 'blank'
local Char = require 'char'

local objs
local cameraX = 0
local cameraY = 0

local map
local level = 0
local paused = false
local win = false

local music = {}

function load_next_level()
  if level == 7 then
    win = true
  else
    level = level + 1
    load_level('level'..level)
  end
end

function load_level(name)
  cameraX = 0
  map = sti('maps/'..name..'.lua', {'bump'})
  local collected = map.layers[1].properties.collected
  world = bump.newWorld()
  objs = {crumble = {}, enemy = {}}
  world:add({}, -1, -256, 1, 512)
  world:add({}, map.layers[1].width*16, -256, 1, 512)

  for k, object in pairs(map.objects) do
    if object.name == 'player' then
      objs.player = Player:new(object.x, object.y, world, collected)
    end
    if object.name == 'door' then
      objs.exit = Entity:new(object.x, object.y, world, love.graphics.newImage('art/door.png'), 16, 32, 0, 0, 'door')
    end
    if object.name == 'enemy' then
      objs.enemy[#objs.enemy+1] = Enemy:new(object.x, object.y, world)
    end
    if object.name == 'left' then
      objs.enemy[#objs.enemy+1] = Blank:new(object.x, object.y, world, 'left', true)
    end
    if object.name == 'right' then
      objs.enemy[#objs.enemy+1] = Blank:new(object.x+15, object.y, world, 'right', true)
    end
    if object.name == 'char' then
      local props = object.properties
      local r, g, b = props.r, props.g, props.b
      objs.char = Char:new(object.x, object.y, world, r, g, b)
    end
  end
  map:removeLayer("Sprite Layer")
  for y, row in pairs(map.layers[2].data) do
    for x, tile in pairs(row) do
      objs.crumble[#objs.crumble+1] = Crumble:new((x-1)*16, (y-1)*16, world)
    end
  end
  map:removeLayer("Crumble Blocks")
  map:bump_init(world)

  colorShader = love.graphics.newShader[[
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
    vec4 pixel = Texel(texture, texture_coords);
    return vec4(pixel.rgb*2, pixel.a);
  }
  ]]
end

function love.load()
  love.window.setMode(w, h)

  lowcanvas = love.graphics.newCanvas(256, 256)
  lowcanvas:setFilter('linear', 'nearest')

  love.window.setTitle('More and More')

  love.graphics.setNewFont('Comfortaa-Bold.ttf', 32)

  love.graphics.setBackgroundColor(50, 200, 255)
  load_level('level'..level)
  music.weow = love.audio.newSource('music/weow.wav')
  music.song2 = love.audio.newSource('music/ld40chiptunethingy.mp3')
  love.audio.play(music.weow)
end

function draw_objs(o)
  for k, obj in pairs(o) do
    if not obj.class then
      draw_objs(obj)
    else
      obj:draw(colorShader)
    end
  end
end

function update_objs(o, dt, gravity, world)
  for k, obj in pairs(o) do
    if not obj.class then
      update_objs(obj, dt, gravity, world)
    else
      local lv = obj:update(dt, gravity, world)
      if lv then
        load_next_level()
      end
    end
  end
end

function love.draw()
  if not win then
    love.graphics.setCanvas(lowcanvas)
    love.graphics.translate(-cameraX, cameraY)
    love.graphics.clear(50, 150, 255)
    love.graphics.setColor(255, 255, 255)
    draw_objs(objs)
    map:draw(-cameraX, cameraY)
    love.graphics.setCanvas()
    love.graphics.origin()
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(lowcanvas, 0, 0, 0, 2)
  else
    love.graphics.setCanvas(lowcanvas)
    love.graphics.clear(50, 150, 255)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("YOU WIN!!!", 0, 50, 256, 'center')
    love.graphics.setCanvas()
    love.graphics.origin()
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(lowcanvas, 0, 0, 0, 2)
  end
end

function love.update(dt)
  if music.weow:isStopped() and music.song2:isStopped() then
    if level < 3 then
      love.audio.play(music.weow)
    elseif level < 5 then
      love.audio.play(music.song2)
    end
  end
  if not paused then
    local pdx = 0, 0
    if love.keyboard.isDown('left') then
      pdx = pdx - playerSpeed
    end
    if love.keyboard.isDown('right') then
      pdx = pdx + playerSpeed
    end
    objs.player:push(pdx, 0)
    update_objs(objs, dt, {x = 0, y = 0.5}, world)
    if objs.player.pos.x - cameraX > 100 then
      cameraX = lerp(objs.player.pos.x - 100, cameraX, 0.15)
    end
    if objs.player.pos.x - cameraX < 50 then
      cameraX = lerp(objs.player.pos.x - 50, cameraX, 0.15)
    end
    if cameraX < 0 then
      cameraX = 0
    end
    if cameraX > map.layers[1].width*16-256 then
      cameraX = map.layers[1].width*16-256
    end
    cameraX = math.floor(cameraX)
    cameraY = math.ceil(math.max(0, 50-objs.player.pos.y))
    map:update(dt)
    local c = objs.player.collected
    playerSpeed = 1.2 - 0.15 * c
    jump = -8 + c/2
    Enemy.speed = 1 + c/4
    local function fix_objs(o)
      for k, obj in pairs(o) do
        if not obj.class then
          fix_objs(obj)
        elseif obj.id == 'crumble' then
          obj.sp = 0.8 - 0.075 * c
        end
      end
    end
    fix_objs(objs)
  end
  if objs.char and objs.char.dead then
    objs.char = nil
  end
  if objs.player.dead then
    load_level('level'..level)
  end
end

function love.keypressed(key, scan, isrepeat)
  if key == 'escape' then
    paused = not paused
    if paused then
      love.audio.pause()
    else
      love.audio.resume()
    end
  end
  if (key == 'up' or key == 'space') and objs.player.onground and not paused then
    objs.player:push(0, jump)
    objs.player.candjump = true
  elseif (key == 'up' or key == 'space') and objs.player.candjump and not paused  then
    if love.keyboard.isDown('left') then
      objs.player:push(-4, 0)
      objs.player.vel.y = jump + 2
    elseif love.keyboard.isDown('right') then
      objs.player:push(4, 0)
      objs.player.vel.y = jump + 2
    else
      objs.player.vel.y = jump + 2
    end
    objs.player.candjump = false
  end
  -- if key == '`' then
  --   load_next_level()
  -- end
  -- if key == '1' then
  --   objs.player.collected = objs.player.collected + 1
  -- end
  if (key == 'enter' or key == 'return') and win then
    love.event.quit()
  end
end

function lerp(a, b, pct)
  return a * pct + b * (1 - pct)
end
