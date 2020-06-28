--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A classic platformer in the style of Super Mario Bros., using a free
    art pack. Super Mario Bros. was instrumental in the resurgence of video
    games in the mid-80s, following the infamous crash shortly after the
    Atari age of the late 70s. The goal is to navigate various levels from
    a side perspective, where jumping onto enemies inflicts damage and
    jumping up into blocks typically breaks them or reveals a powerup.

    Art pack:
    https://opengameart.org/content/kenney-16x16
]]

require 'src/Dependencies'

local keys_pressed = {}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.graphics.setFont(gFonts['medium'])
    love.window.setTitle(GAME_TITLE)

    math.randomseed(os.time())

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true,
    })

    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end
    }
    gStateMachine:change('start')

    gSounds['music']:setLooping(true)
    gSounds['music']:setVolume(0.7)
    gSounds['music']:play()
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    -- toggle fullscreen mode by pressing left alt + enter
    if love.keyboard.isDown('lalt') and (key == 'enter' or key == 'return') then
        push:switchFullscreen()
        return      -- don't use this keypress for the game logic
    end
    keys_pressed[key] = true
end

function keyboardWasPressed(key)
    return keys_pressed[key]
end

function getKeysPressed()
    return keys_pressed
end

function love.update(dt)
    -- limit dt
    dt = math.min(dt, 0.07)

    gStateMachine:update(dt)

    keys_pressed = {}
end

function love.draw()
    push:start()
    gStateMachine:render()
    push:finish()
end
