--[[
    GD50
    Super Mario Bros. Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Title Screen
]]

StartState = Class{__includes = BaseState}

function StartState:init()
    -- create a small level that fills the screen to have a background
    self.level = GameLevel(math.ceil(VIRTUAL_WIDTH / TILE_SIZE) + 1)
end

function StartState:update(dt)
    -- go to PlayState if any key other than escape is pressed
    if keyboardWasPressed('escape') then
        love.event.quit()
    elseif next(getKeysPressed()) then
        gSounds['confirm']:play()
        gStateMachine:change('play')
    end
end

function StartState:render()
    self.level:renderBackground(0)
    self.level:render(0)

    love.graphics.setFont(gFonts['title'])
    love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
    love.graphics.printf(GAME_TITLE, 1, VIRTUAL_HEIGHT / 2 - 40 + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.printf(GAME_TITLE, 0, VIRTUAL_HEIGHT / 2 - 40, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
    love.graphics.printf('Press any Key', 1, VIRTUAL_HEIGHT / 2 + 17, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.printf('Press any Key', 0, VIRTUAL_HEIGHT / 2 + 16, VIRTUAL_WIDTH, 'center')
end
