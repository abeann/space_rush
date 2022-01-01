require 'Util'

Asteroid = Class{}

local SCALE = 4

function Asteroid:init()
    self.width = 21 * SCALE
    self.height = 16 * SCALE
    self.ax = math.random(30, VIRTUAL_WIDTH - self.width - 30)
    self.ay = -self.height
    self.x = self.ax + (4 * SCALE)
    self.y = self.ay + (2 * SCALE)
    self.dy = asteroidVelocity

    self.texture = love.graphics.newImage('graphics/grey_asteroid.png')
    self.frames = generateQuads(self.texture, 27, 22)

    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[1]
            }
        }),
        ['explosion'] = Animation({
            texture = self.texture,
            frames = {
               self.frames[2], self.frames[3], self.frames[4], self.frames[5]
            },
            interval = 0.15
        })
    }

    self.animation = self.animations['idle']

end

function Asteroid:update(dt)
    self.animation:update(dt, 'asteroid')

    self.ay = self.ay + self.dy * dt
    self.y = self.ay + (2 * SCALE)
    
     --Laser collision
     for i,laser in ipairs(lasers) do
        if self:collision(laser) and self.animation == self.animations['idle'] then
            self.dy = 0
            self.animation = self.animations['explosion']
            explosionSound:clone():play()
            table.remove(lasers, i)
            score = score + 50
        end
     end
end

function Asteroid:collision(laser)
    if self.x > laser.x + laser.width or laser.x > self.x + self.width then
        return false
    end
    if self.y> laser.y + laser.height or laser.y > self.y + self.height then
        return false
    end
    return true
end

function Asteroid:render()
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.ax), math.floor(self.ay), 0, SCALE, SCALE)
end

