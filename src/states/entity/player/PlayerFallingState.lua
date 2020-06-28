--[[
    GD50
    Super Mario Bros. Remake

    -- PlayerFallingState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerFallingState = Class{__includes = BaseState}

function PlayerFallingState:init(owner)
    self.owner = owner
    self.owner.animation = Animation(PLAYER_FRAME_ID_JUMPING)
end

function PlayerFallingState:updateStage1(dt)
    self.owner:doMovement(dt)

    self.owner:checkObjectCollisions()
end

function PlayerFallingState:updateStage2(dt)
    self.owner:checkEntityCollisions()
end

function PlayerFallingState:updateStage3(dt)
    -- try not to override a new state that got set inside the collision detection functions
    -- if collided with ground
    if (self.owner.is_slight_collision_obj_lrtb[4] or self.owner.is_collision_ent_lrtb[4]) and not self.owner.new_state then
        if math.abs(self.owner.dx) > 0 then
            self.owner.new_state = 'walking'
        else
            self.owner.new_state = 'idle'
        end
    end
end
