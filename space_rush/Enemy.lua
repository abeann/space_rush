require 'Util'

Enemy = Class{}

SCALE = 4

function Enemy:init()
    self.width = 21 * SCALE
    self.height = 22 * SCALE 
    self.x = math.random(30, VIRTUAL_WIDTH - self.width - 30)
    self.y = -self.height
    self.dy = enemyVelocity
    self.dx = 0

    self.texture = love.graphics.newImage('graphics/enemy.png')
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
    }

    self.animation = self.animations['moving']

    self.timer = 0
    self.laserInterval = enemyLaserInterval
end

function Enemy:update(dt)
    self.animation:update(dt)
    
    self.x = math.max(0, math.min(VIRTUAL_WIDTH - self.width, self.x + self.dx * dt))
    self.y = math.max(0, math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt))

    for i, laser in ipairs(lasers) do
        if (self:topCollision(laser) or self:baseCollision(laser)) and self.animation == self.animations['moving'] then
            self.animation = self.animations['explosion']
            explosionSound:clone():play()
            table.remove(lasers, i)
            score = score + 100
        end
    end

    if (self:playerTopCollision(player) or self:playerBaseCollision(player)) and self.animation == self.animations['moving'] then
        self.animation = self.animations['explosion']
        player.animation = player.animations['explosion']
        explosionSound:clone():play()
        player.dy = 0
        player.dx = 0
    end

    --enemy movement
    if self.animation == self.animations['moving'] then
        if self.y > self.height + 10 then
            self.dy = 0
        end
        
        self:AI(player)
    else
        self.dx = 0
        self.dy = 0
    end

    self.timer = self.timer + dt
end

--collision functions

function Enemy:topCollision(object)
    if self.x + (8 * SCALE) > object.x + object.width or object.x > self.x + (8 * SCALE) + (5 * SCALE) then
        return false
    end
    if self.y + self.height - (5 * SCALE) > object.y + object.height or object.y > self.y + self.height  then
        return false
    end
    return true
end

function Enemy:baseCollision(object)
    if self.x > object.x + object.width or object.x > self.x + self.width then
        return false
    end
    if self.y + (5 * SCALE) > object.y + object.height or object.y > self.y + self.height - (5 * SCALE) then
        return false
    end
    return true
end

function Enemy:playerTopCollision(player)
    if self.x + (8 * SCALE) > player.x + (8 * SCALE) + (5 * SCALE) or player.x + (8 * SCALE) > self.x + (8 * SCALE) + (5 * SCALE) then
        return false
    end
    if self.y + self.height - (5 * SCALE) > player.y + (5 * SCALE) or player.y > self.y + self.height then
        return false
    end
    return true
end

function Enemy:playerBaseCollision(player)
    if self.x > player.x + player.width or player.x > self.x + self.width then
        return false
    end
    if self.y + (5 * SCALE) > player.y + player.height or player.y + (5 * SCALE) > self.y + self.height - (5 * SCALE) then
        return false
    end
    return true
end

--Enemy player-tracking 
function Enemy:AI(player)
    if player.x + (player.width / 2) > self.x + (self.width / 2) + SCALE then
        self.dx = enemyVelocity
    elseif player.x + (player.width / 2) < self.x + (self.width / 2) - SCALE then
        self.dx = -enemyVelocity
    else
        self.dx = 0
        if self.timer > self.laserInterval then
            table.insert(lasers, Laser(self, 400, 'graphics/laserEnemy.png'))
            self.timer = 0
        end
    end
end

function Enemy:render()
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x), math.floor(self.y), 0, SCALE, SCALE)
end