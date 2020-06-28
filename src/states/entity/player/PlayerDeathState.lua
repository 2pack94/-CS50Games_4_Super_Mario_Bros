--[[
    GD50
    Super Mario Bros. Remake

    -- PlayerDeathState Class --
]]

PlayerDeathState = Class{__includes = BaseState}

-- this state plays the death animation
function PlayerDeathState:init(owner)
    self.owner = owner
    self.owner.animation = Animation(PLAYER_FRAME_ID_DEATH)

    -- keep the player at its place for 1 second. turn gravity on afterwards so the player falls below the screen.
    -- this will get detected and the game will go back to the Start Screen
    self.owner.is_alive = false
    self.owner.has_gravity = false
    self.owner.dx, self.owner.dy = 0, 0
    gSounds['death']:play()

    Timer.after(1, function()
        self.owner.has_gravity = true
        self.owner.vertical_direction = 'down'
    end)
end

function PlayerDeathState:updateStage1(dt)
    self.owner:updatePosition(dt)
end

function PlayerDeathState:updateStage2(dt) end
function PlayerDeathState:updateStage3(dt) end
