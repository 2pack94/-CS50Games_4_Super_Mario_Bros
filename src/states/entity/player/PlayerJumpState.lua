--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerJumpState = Class{__includes = BaseState}

-- enter: when pressed the jump key while on the ground or when jumping off of an enemy
-- exit when dy gets 0 or positive
-- based on the physics and the parameters, the maximum player jump height is about 3,5 tiles
function PlayerJumpState:init(owner)
    self.owner = owner
    self.owner.animation = Animation(PLAYER_FRAME_ID_JUMPING)
    self.enemy_jump_dy = -120         -- jump velocity when jumping off of an enemy and jump key was not held down
    self.jump_dy = -210               -- jump velocity when starting the jump
    -- timer that measures the time period where a jump input is possible. starts when entering jump state.
    -- initialize to the possible jump input time in seconds. timer counts down to 0.
    -- when the jump key is held down after the jump started, the player will jump higher.
    -- holding the jump key down will only have an effect when inside the jump input time window.
    self.jump_input_timer = 0.5
    self.is_jump_input = true       -- will get set to false if the jump key is released
end

function PlayerJumpState:enter(params)
    -- give the player the jump velocity
    if params and params.type == 'enemy' then   -- jump off of enemy
        gSounds['jump2']:play()
        -- when the jump key is held down the player gets the regular jump velocity. else he gets a small jump velocity and will not jump high.
        if love.keyboard.isDown('space') or love.keyboard.isDown('kp1') then
            self.owner.dy = self.jump_dy
        else
            self.owner.dy = self.enemy_jump_dy
        end
    else                                        -- jump from the ground
        gSounds['jump1']:play()
        self.owner.dy = self.jump_dy
    end
end

function PlayerJumpState:updateStage1(dt)
    -- check if the jump key was released during the jump
    if self.is_jump_input and not (love.keyboard.isDown('space') or love.keyboard.isDown('kp1')) then
        self.is_jump_input = false
    end

    self.jump_input_timer = math.max(0, self.jump_input_timer - dt)

    -- if inside the jump input time window and the jump key was released
    if not self.is_jump_input and self.jump_input_timer > 0 then
        -- apply a stronger gravity effect during the jump, so the player falls down earlier
        self.owner.dy = self.owner.dy + GRAVITY * dt * 1.1
    end

    self.owner:doMovement(dt)

    self.owner:checkObjectCollisions()
end

function PlayerJumpState:updateStage2(dt)
    self.owner:checkEntityCollisions()
end

function PlayerJumpState:updateStage3(dt)
    -- try not to override a new state that got set inside the collision detection functions
    -- go into the falling state when y velocity is positive
    -- velocity get set to 0 inside the collision detection functions when bumped into something
    -- the case of a bottom collision can only happen if the ground moves up faster than the player
    if (self.owner.is_slight_collision_obj_lrtb[4] or self.owner.is_collision_ent_lrtb[4]) and not self.owner.new_state then
        if math.abs(self.owner.dx) > 0 then
            self.owner.new_state = 'walking'
        else
            self.owner.new_state = 'idle'
        end
    elseif self.owner.dy >= 0 and not self.owner.new_state then
        self.owner.new_state = 'falling'
    end
end
