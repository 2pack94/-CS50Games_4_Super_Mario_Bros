--[[
    GD50
    Super Mario Bros. Remake

    -- Player Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    the player object is controlled by the keyboard
    Movement: WASD or arrow keys
    Running: shift left or numpad 2
    jump: space or numpad 1
]]

PLAYER_HEIGHT = 20
PLAYER_WIDTH = TILE_SIZE
PLAYER_ACCELERATION = 250       -- acceleration constant for left right movement
PLAYER_MAX_WALK_SPEED = 70
PLAYER_MAX_RUN_SPEED = 110

Player = Class{__includes = Entity}

function Player:init(x, y, level)
    --[[
        the player has 5 hitboxes, aligned like this:
          +--+
        +-+--+-+
        | |  | |
        +-+--+-+
          +--+
        feet hitbox:
            has the shift_up member. It's needed to go up small heights (e.g. stairs) and it makes jumping on enemies fairer.
            must have a low priority (collision gets resolved late), otherwise the player would teleport to the top of a ledge when hitting it with sufficient speed from the side.
        arm hitboxes:
            has shift_right or shift_left member. needed because the player would get shifted upwards unnaturally when jumping and hitting an edge with the feet.
            they create a buffer so that the feet hitbox is less likely hit from the side. they are shifting outwards, so the player cannot stand on one arm on an edge.
        head hitbox:
            has shift_down member. needed to get pushed down when jumping between 2 blocks that the player does not fit in between.
            The player can still jump in between 2 blocks while hitting only the arm hitboxes, but this is acceptable.
        body hitbox:
            has the highest priority (collision gets resolved first).
            in the case more than 1 hitbox with a shift member is hit at the same time (is likely because they are not very thick), there is also a collision with the body hitbox.
            after the player gets rebounded at the body hitbox first, other hitbox collisions are resolved implicitly and there is now only a collision with 1 hitbox left.
    ]]
    local hitbox_x_offset = 1   -- the left arm hitbox starts 1 pixel to the right of the player x position, making the total hitbox area smaller
    local feet_height = 3
    local head_height = 3
    local arm_width = 1
    local hitbox_head = Rect(x + hitbox_x_offset + arm_width, y, PLAYER_WIDTH - arm_width * 2 - hitbox_x_offset * 2, head_height)
    local hitbox_left_arm = Rect(x + hitbox_x_offset, y + head_height, arm_width, PLAYER_HEIGHT - feet_height - head_height)
    local hitbox_body = Rect(hitbox_head.x, y + hitbox_head.height, hitbox_head.width, hitbox_left_arm.height)
    local hitbox_right_arm = Rect(hitbox_body.x + hitbox_body.width, hitbox_left_arm.y, hitbox_left_arm.width, hitbox_left_arm.height)
    local hitbox_feet = Rect(hitbox_head.x, y + PLAYER_HEIGHT - feet_height, hitbox_body.width, feet_height)
    hitbox_feet.shift_up = true             -- player gets shifted up when hitbox_feet is rebounded
    hitbox_left_arm.shift_right = true      -- player gets shifted right when hitbox_left_arm is rebounded
    hitbox_right_arm.shift_left = true      -- player gets shifted left when hitbox_right_arm is rebounded
    hitbox_head.shift_down = true           -- player gets shifted down when hitbox_head is rebounded

    Entity.init(self, {
        x = x, y = y,
        width = PLAYER_WIDTH,
        height = PLAYER_HEIGHT,
        hitboxes = {hitbox_body, hitbox_right_arm, hitbox_left_arm, hitbox_head, hitbox_feet},  -- the order of the hitboxes is the priority
        texture = 'pink_alien',
        state_machine = StateMachine {      -- the StateMachine Classes get a reference to the player, supplied as a parameter to their init methods when instantiated
            ['idle'] = function() return PlayerIdleState(self) end,
            ['walking'] = function() return PlayerWalkingState(self) end,
            ['jump'] = function() return PlayerJumpState(self) end,
            ['falling'] = function() return PlayerFallingState(self) end,
            ['death'] = function() return PlayerDeathState(self) end
        },
        id = ENTITY_ID_PLAYER,
        level = level
    })

    -- player score displayed on the screen
    self.score = 0
    -- set to true if doCollideWithEntity() callback function got executed once
    self.had_entity_interaction = false
    -- flag set by FlagPole and checked in PlayState, to go to the next level
    self.finished_level = false
    -- set initial state
    self.state_machine:change('idle')
end

-- this function changes the player velocity based on the keybord input
-- the player does not immediately switch to another velocity, but he gets accelerated or decelerated to reach the target speed
-- update the players position based on the velocity afterwards
-- return: true if there is a keyboard input, falsse otherwise
function Player:doMovement(dt)
    local is_movement = false
    -- either PLAYER_MAX_WALK_SPEED or PLAYER_MAX_RUN_SPEED depending on if the running key is pressed
    local max_speed = PLAYER_MAX_WALK_SPEED
    -- absolute target x velocity. gets set to max_speed if left or right movement key is pressed, stays 0 otherwise.
    -- if absolute self.dx is not target_speed, the player gets accelerated or decelerated to reach target_speed
    local target_speed = 0
    if love.keyboard.isDown('lshift') or love.keyboard.isDown('kp2') then
        max_speed = PLAYER_MAX_RUN_SPEED
    end
    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        is_movement = true
        self.direction = 'left'
        target_speed = max_speed
        -- the player should accelerate towards higher negative velocity
        if self.dx > -target_speed then
            self.dx = self.dx - PLAYER_ACCELERATION * dt
            self.dx = math.max(self.dx, -target_speed)
        end
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        is_movement = true
        self.direction = 'right'
        target_speed = max_speed
        -- the player should accelerate towards higher positive velocity
        if self.dx < target_speed then
            self.dx = self.dx + PLAYER_ACCELERATION * dt
            self.dx = math.min(self.dx, target_speed)
        end
    end

    -- the player should decelerate
    if math.abs(self.dx) > math.abs(target_speed) then
        if self.dx > 0 then
            self.dx = self.dx - PLAYER_ACCELERATION * dt
            self.dx = math.max(self.dx, target_speed)
        elseif self.dx < 0 then
            self.dx = self.dx + PLAYER_ACCELERATION * dt
            self.dx = math.min(self.dx, -target_speed)
        end
    end

    self:updatePosition(dt)

    return is_movement
end

-- overrides Entity:doCollideWithEntity()
function Player:doCollideWithEntity(self_collision_data, opponent_collision_data)
    -- only interact with the first entity that was hit this frame. This is the entity that the player had the biggest collision size with.
    -- if the entity intersects slightly with the player after a rebound, this function is still called.
    -- That means that when the intersecting side is calculated from the original collision data,
    -- the calculation is only in line with the calculations inside checkEntityCollisions() for the first collided entity.
    -- This measure is needed only when collides_with_others is set true for the entities.
    if self.had_entity_interaction then
        return
    end

    -- if jumped on top of entity.
    -- if there would be spiked enemies that the player cannot jump on, an additional check would be needed here
    if self_collision_data.hitbox:getIntersectingEdgeHitbox(opponent_collision_data.hitbox)[4] then
        -- change to jump state. Jumping off from an enemy has a different behaviour than jumping from the ground, so the jump type must be specified.
        self.new_state = 'jump'
        self.new_state_params = {type = 'enemy'}

        -- the colliding entity is killed in the entities doCollideWithEntity() function
    else
        -- if collided with another side the player dies
        self:onScreenDeath()
    end

    self.had_entity_interaction = true
end

-- overrides Entity:onScreenDeath()
-- change to DeathState
function Player:onScreenDeath()
    self.new_state = 'death'
end

-- overrides Entity:updateStage3()
function Player:updateStage3(dt)
    self.state_machine.current:updateStage3(dt)
    self:commonExitTask()
    self.had_entity_interaction = false
end
