require 'Util'

Player = Class{}

local VELOCITY = 400
SCALE = 4


function Player:init()
    self.width = 21 * SCALE
    self.height = 22 * SCALE
    self.x = VIRTUAL_WIDTH / 2 - (self.width / 2)
    self.y = VIRTUAL_HEIGHT - self.height
    self.dy = 0
    self.dx = 0

    self.texture = love.graphics.newImage('graphics/player.png')
    self.frames = generateQuads(self.texture, 21, 22)

    self.animations = {
        ['moving'] = Animation({
            texture = self.texture,
            frames = {
               self.frames[2], self.frames[3], self.frames[4]
            },
            interval = 0.15
        }),
        ['explosion'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[5], self.frames[6], self.frames[7], self.frames[8]
            },
            interval = 0.15
        }),
        ['blank'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[8]
            },
        })
    }

    self.animation = self.animations['moving']

    self.timer = 0
    self.laserInterval = 0.45
end

function Player:update(dt)
    
    self.animation:update(dt)

    self.x = math.max(0, math.min(VIRTUAL_WIDTH - self.width, self.x + self.dx * dt))
    self.y = math.max(0, math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt))

    if gameState == 'play' and self.animation == self.animations['moving'] then
        if love.keyboard.isDown('w') then
            self.dy = -VELOCITY
        elseif love.keyboard.isDown('s') then
            self.dy = VELOCITY
        else
            self.dy = 0
        end

        if love.keyboard.isDown('a') then
            self.dx = -VELOCITY
        elseif love.keyboard.isDown('d') then
            self.dx = VELOCITY
        else
            self.dx = 0
        end

        if love.keyboard.wasPressed('space') and self.timer > self.laserInterval then
            table.insert(lasers, Laser(self, -400, 'graphics/laserPlayer.png'))
            love.keyboard.keysPressed['space'] = false
            self.timer = 0
        end
    end

    --check for asteroid collisions
    for i,asteroid in ipairs(asteroids) do
        if (self:topCollision(asteroid) or self:baseCollision(asteroid)) and asteroid.animation == asteroid.animations['idle'] then
            self.dy = 0
            self.dx = 0
            self.animation = self.animations['explosion']
            asteroid.animation = asteroid.animations['explosion']
            explosionSound:play()
            asteroid.dy = 0
        end
    end

    --check for enemy laser collisions 
    for i, laser in ipairs(lasers) do
        if (self:topCollision(laser) or self:baseCollision(laser)) and laser.dy > 0 then
            self.dy = 0
            self.dx = 0
            self.animation = self.animations['explosion']
            explosionSound:clone():play()
            table.remove(lasers, i)
        end
    end

    --laser cooldown
    self.timer = self.timer + dt
end

function Player:topCollision(object)
    if self.x + (8 * SCALE) > object.x + object.width or object.x > self.x + (8 * SCALE) + (5 * SCALE) then
        return false
    end
    if self.y > object.y + object.height or object.y > self.y + (5 * SCALE) then
        return false
    end
    return true
end

function Player:baseCollision(object)
    if self.x > object.x + object.width or object.x > self.x + self.width then
        return false
    end
    if self.y + (5 * SCALE) > object.y + object.height or object.y > self.y + self.height then
        return false
    end
    return true
end

function Player:render()
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x), math.floor(self.y), 0, SCALE, SCALE)
end