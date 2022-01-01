Class = require 'class'
push = require 'push'
require 'Animation'
require 'Util'
require 'Player'
require 'Enemy'
require 'Laser'
require 'Asteroid'

VIRTUAL_WIDTH = 864
VIRTUAL_HEIGHT = 486

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

math.randomseed(os.time())

love.graphics.setDefaultFilter('nearest', 'nearest')

background = love.graphics.newImage('graphics/background.png')

local timer = 0
local blink = true
local waveOver = true

local asteroidTimer = 0
local asteroidAmount = 1
local asteroidInterval = 1
local ac = 0
local ad = 0

score = 0

player = Player()
lasers = {}
enemyLasers = {}
asteroids = {}
enemies = {}

explosionSound = love.audio.newSource('sounds/explosion.mp3', 'static')
music = love.audio.newSource('sounds/music.mp3', 'static')

function love.load()
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    love.window.setTitle('Space')

    love.keyboard.keysPressed = {}

    gameState = 'title'

    titleFontIn = love.graphics.newFont('fonts/fontIn.ttf', 150)
    titleFontOut = love.graphics.newFont('fonts/fontOut.ttf', 150)
    medFont = love.graphics.newFont('fonts/fontIn.ttf', 60)
    smallFont = love.graphics.newFont('fonts/fontScore.ttf', 22)
    finalScoreFont = love.graphics.newFont('fonts/fontScore.ttf', 40)

    music:play()
    initialize()
end

function love.keyboard.wasPressed(key)
    if (love.keyboard.keysPressed[key]) then
        return true
    else
        return false
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
    if key == 'return' and gameState == 'title' then
        gameState = 'play'
    end    
    if key == 'return' and gameState == 'gameOver' then
        gameState = 'play'
        initialize()
    end

    love.keyboard.keysPressed[key] = true
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)

    if gameState == 'title' or gameState == 'gameOver' then

        --blinking title 
        timer = timer + dt
        if timer > 0.5  then
            if blink == true then
                blink = false
            elseif blink == false then
                blink = true
            end
            timer = 0
        end 

    end

    if gameState == 'play' then
                
        asteroidTimer = asteroidTimer + dt

        --player updating
        player:update(dt)

        --laser updating and despawning
        for i,laser in ipairs(lasers) do
            laser:update(dt)
            if laser.y < -laser.height or laser.y > VIRTUAL_HEIGHT then
                table.remove(lasers, i)
            end
        end

        --asteroid and enemy spawning
        if waveOver then
            if math.random(2) == 1 then
                if asteroidTimer > 0.5 then
                    table.insert(asteroids, Asteroid())
                    asteroidTimer = 0
                    ac = ac + 1
                end
                if ac >= asteroidAmount then
                    waveOver = false
                    ac = 0
                end
            elseif ac == 0 then
                table.insert(enemies, Enemy())
                waveOver = false
            end
        end


        --asteroid updating and despawning
        for i,asteroid in ipairs(asteroids) do
            asteroid:update(dt)
            if asteroid.y > VIRTUAL_HEIGHT or asteroid.animation:getCurrentFrame() == asteroid.frames[5] then
                table.remove(asteroids, i)
                ad = ad + 1
            end
        end
        if ad >= asteroidAmount then
            ad = 0
            asteroidAmount = asteroidAmount + 1
            asteroidVelocity = math.min(400, asteroidVelocity + 10)
            waveOver = true
        end

        --player despawn
        if player.animation:getCurrentFrame() == player.frames[8] then
            player.animation = player.animations['blank']
            gameState = 'gameOver'
        end

        --enemy updating and despawn
        for i, enemy in ipairs(enemies) do
            enemy:update(dt)
            if enemy.animation:getCurrentFrame() == enemy.frames[8] then
                table.remove(enemies, i)
                waveOver = true
                enemyVelocity = math.min(400, enemyVelocity + 20)
                enemyLaserInterval = math.max(0.1, enemyLaserInterval - 0.1)
            end
        end

    end
end

function love.draw()
    push:apply('start')

    love.graphics.draw(background, 0, 0, 0, 2.2, 2.2)

    if gameState == 'title' then
        renderTitle()
        renderBlink(medFont, 'PRESS ENTER TO PLAY', VIRTUAL_HEIGHT / 2)
    end

    if gameState == 'play' then

        player:render()

        for i,laser in ipairs(lasers) do
            laser:render()
        end

        for i,asteroid in ipairs(asteroids) do
            asteroid:render()
        end

        for i, enemy in ipairs(enemies) do 
            enemy:render()
        end

        renderScore()

    end

    if gameState == 'gameOver' then
        renderGameOver()
        renderBlink(finalScoreFont, 'PRESS ENTER TO PLAY AGAIN', VIRTUAL_HEIGHT / 2 + 80)
    end

    push:apply('end')
end

function renderTitle()
    love.graphics.setColor(0, 0, 1)
    love.graphics.setFont(titleFontIn)
    love.graphics.printf('SPACE RUSH', 0, 80, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(medFont)
    love.graphics.setFont(titleFontOut)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf('SPACE RUSH', 0, 80, VIRTUAL_WIDTH, 'center')
end

function renderBlink(font, text, y)
    love.graphics.setFont(font)
    if blink then
        love.graphics.setColor(1, 1, 1)
    else 
        love.graphics.setColor(32 / 255, 19 / 255, 19 / 255)
    end
    love.graphics.printf(text, 0 , y, VIRTUAL_WIDTH, 'center')
end

function renderGameOver()
    love.graphics.setColor(1, 0, 0)
    love.graphics.setFont(titleFontIn)
    love.graphics.printf('GAME OVER', 0, VIRTUAL_HEIGHT / 2 - 100, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(finalScoreFont)
    love.graphics.printf('FINAL SCORE: ' .. tostring(score), 0, VIRTUAL_HEIGHT / 2 + 25, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(titleFontOut)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf('GAME OVER', 0, VIRTUAL_HEIGHT / 2 - 100, VIRTUAL_WIDTH, 'center')
end

function renderScore()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print('SCORE: ' .. tostring(score), 8, VIRTUAL_HEIGHT - 25)
end

--initialize game values
function initialize()
    score = 0
    player:init()
    lasers = {}
    asteroids = {}
    enemies = {}

    enemyLaserInterval = 1
    enemyVelocity = 150
    asteroidVelocity = 150

    waveOver = true

    asteroidTimer = 0
    asteroidAmount = 1
    ac = 0
    ad = 0

    music:stop()
    music:play()
end