--[[
    GD50
    Super Mario Bros. Remake

    -- PlayState Class --
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    -- camera coordinates that follow the player. game world and background get translated by the camera coordinates
    self.cam_x = 0
    self.cam_y = 0
    -- background scrolling on the x axis. the background moves to the left if the camera moves to the right.
    self.background_x = 0
    -- level number that gets rendered on the screen. gets incremented for every new level. influences the level length
    self.level_nr = 0
    -- if game is paused
    self.is_pause = false
    -- the movement of all objects should get stopped when the player dies
    self.movement_stopped = false
    -- instantiate Player object
    self.player = Player(0, 0, nil)

    self:createNewLevel()
end

-- generate a new level, spawn enemies and put the player to the beginning of the level
function PlayState:createNewLevel()
    -- increase the level length when creating the next level. maximum 200 Tiles
    self.level_length = math.min(math.ceil(VIRTUAL_WIDTH / TILE_SIZE + 10 * self.level_nr), 200)
    -- instantiate a new level
    self.level = GameLevel(self.level_length)

    -- reset the player
    self.player:setPosition(0, 0)
    self.player.dx, self.player.dy = 0, 0
    self.player.level = self.level

    -- insert the player before all other entities, so the player gets updated first.
    -- This way the player can trigger collisions with all entities that he intersected with, before he gets potentially rebounded at an enemy.
    -- This has the effect that when jumping on two enemies at the same time, both die.
    table.insert(self.level.entities, self.player)
    self.level:spawnEnemiesRand(self.player)
    self.level_nr = self.level_nr + 1
end

function PlayState:update(dt)
    -- toggle pause
    if keyboardWasPressed('p') or keyboardWasPressed('kp-') then
        if self.is_pause then
            gSounds['confirm']:play()
        else
            gSounds['back']:play()
        end
        self.is_pause = not self.is_pause
    end
    if self.is_pause then
        return
    end
    -- return to StartState
    if keyboardWasPressed('escape') then
        gStateMachine:change('start')
        gSounds['back']:play()
        -- clear all timers (across all states)
        Timer.clear()
        return
    end

    -- update all timers
    Timer.update(dt)

    if self.player.is_alive then
        -- update player and level
        self.level:update(dt, self.cam_x)
    else
        -- update only the player to play the death animation
        self.player:update(dt)
        -- stop all timers that cause movement
        if not self.movement_stopped then
            for _, object in pairs(self.level.objects) do
                object:stopMovement()
            end
            self.movement_stopped = true
        end
    end

    self:updateCamera()

    -- if the player fell into a chasm or finished playing its death animation, go back to Start State
    if self.player.is_remove then
        gSounds['game-over']:play()
        gStateMachine:change('start')
        -- clear all timers (across all states)
        Timer.clear()
        return
    end
    -- go to the next level and give some points to the player if the level was finished
    if self.player.finished_level then
        self.player.finished_level = false
        self.player.score = self.player.score + math.floor(self.level_length * 4 / 10) * 10
        self:createNewLevel()
    end
end

function PlayState:render()
    self.level:renderBackground(self.background_x)

    -- stores the current coordinate transformation state into the transformation stack.
    love.graphics.push()

    -- translation between world coordinates (the position where sprites or other elements are located in the game world) and
    -- screen coordinates (the actual position where those elements are rendered on the screen).
    -- Shifts the coordinate system by x, y for everything drawn after this call.
    -- All the following drawing operations take effect as if their x and y coordinates were x + translate_x and y + translate_y.
    -- Translate the entire scene by the camera scroll amount to emulate a camera.
    -- When walking to the right, the translation shift goes in the negative direction and vice-versa.
    -- math.floor is used to prevent tearing/ blurring.
    love.graphics.translate(-math.floor(self.cam_x), -math.floor(self.cam_y))

    self.level:render(self.cam_x)

    -- revert the current coordinate transformation. Reverse the previous push operation.
    love.graphics.pop()

    -- render score
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
    love.graphics.print(tostring(self.player.score), 5, 5)
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.print(tostring(self.player.score), 4, 4)

    -- render level Nr.
    love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
    love.graphics.printf('Level ' .. tostring(self.level_nr), 0, 5, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.printf('Level ' .. tostring(self.level_nr), -1, 4, VIRTUAL_WIDTH, 'center')

    -- render pause text
    if self.is_pause then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSE", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:updateCamera()
    -- set cam_x to half the screen left of the player's center, so the player will be in the x center of the screen
    -- restrict camera to stay inside the level (between left and right level boundary). The camera width is the VIRTUAL_WIDTH.
    self.cam_x = math.max(0,
        math.min(TILE_SIZE * self.level.grid_width - VIRTUAL_WIDTH, self.player.x - (VIRTUAL_WIDTH / 2 - self.player.width / 2))
    )

    -- background x moves a third the rate of the camera for parallax effect
    -- if background scrolled to a multiple of BACKGROUND_WIDTH, reset its position to 0
    self.background_x = - ((self.cam_x / 3) % BACKGROUND_WIDTH)
end
