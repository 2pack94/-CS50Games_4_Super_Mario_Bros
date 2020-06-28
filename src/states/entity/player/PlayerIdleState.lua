--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerIdleState = Class{__includes = BaseState}

function PlayerIdleState:init(owner)
    self.owner = owner
    self.owner.animation = Animation(PLAYER_FRAME_ID_IDLE)
end

function PlayerIdleState:updateStage1(dt)
    if self.owner:doMovement(dt) then
        self.owner.new_state = 'walking'
    end

    if keyboardWasPressed('space') or keyboardWasPressed('kp1') then
        self.owner.new_state = 'jump'
    end

    self.owner:checkObjectCollisions()
end

function PlayerIdleState:updateStage2(dt)
    self.owner:checkEntityCollisions()
end

function PlayerIdleState:updateStage3(dt)
    -- try not to override a new state that got set inside the collision detection functions
    -- if no ground under the feet
    if not self.owner.is_slight_collision_obj_lrtb[4] and not self.owner.is_collision_ent_lrtb[4] and not self.owner.new_state then
        self.owner.new_state = 'falling'
    end
end
