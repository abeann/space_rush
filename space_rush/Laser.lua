Laser = Class{}

local SCALE = 2

function Laser:init(ship, velocity, sprite)
    self.height = 10 * SCALE
    self.width = 3 * SCALE
    self.x = ship.x + (ship.width / 2) - (self.width / 2)
    if velocity < 0 then
        self.y = ship.y - self.height
    else
        self.y = ship.y + ship.height
    end
    self.dy = velocity

    self.texture = love.graphics.newImage(sprite)

    love.audio.newSource('sounds/laser.mp3', 'static'):play()
end

function Laser:update(dt)
    self.y = self.y + self.dy * dt
end

function Laser:render()
    love.graphics.draw(self.texture, math.floor(self.x), math.floor(self.y), 0, SCALE, SCALE)
end