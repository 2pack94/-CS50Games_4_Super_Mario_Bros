--[[
    GD50
    Super Mario Bros. Remake

    -- SnailMovingState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

SnailMovingState = Class{__includes = BaseState}

function SnailMovingState:init(owner)
    self.owner = owner
    self.owner.animation = Animation(SNAIL_FRAME_IDS_MOVING, 0.5)

    -- set movement direction randomly
    self.owner.direction = math.random() < 0.5 and 'left' or 'right'
    if self.owner.direction == 'left' then
        self.owner.dx = -SNAIL_MOVE_SPEED
    else
        self.owner.dx = SNAIL_MOVE_SPEED
    end
    -- change to a new state somewhere in this time window
    self.moving_period_max = 5
    self.moving_period = math.random(self.moving_period_max)
    -- measure time in this state
    self.moving_timer = 0
    -- if the snail bumped into something it should change its direction
    -- new direction gets set at the end of updateStage3()
    -- if the snail is cornered, it should not change its direction every frame.
    -- self.dir_change_timer gets set to a value after a direction change. It then counts down to 0.
    -- The next direction change can only happen if the timer is at 0.
    self.new_direction = self.owner.direction
    self.dir_change_timer = 0
end

function SnailMovingState:updateStage1(dt)
    self.dir_change_timer = math.max(0, self.dir_change_timer - dt)

    self.moving_timer = self.moving_timer + dt
    if self.moving_timer >= self.moving_period then
        -- if the next state is 'moving', the snail can have a different direction
        self.owner.new_state = math.random() < 0.5 and 'idle' or 'moving'
    end

    -- if the distance between snail and player is smaller than scan_radius, chase the player
    if math.sqrt((self.owner.player.x - self.owner.x)^2 + (self.owner.player.y - self.owner.y)^2) < self.owner.scan_radius then
        self.owner.new_state = 'chasing'
    end

    self.owner:updatePosition(dt)

    local ground_objs = {}
    -- when moving left scan objects on the bottom left of the snail
    -- when moving right scan objects on the bottom right of the snail
    -- change direction if no ground found. Set velocity to 0 to not keep moving if self.dir_change_timer is set.
    if self.owner.direction == 'left' then
        -- velocity has to be updated every frame, because it could be lost through collisions
        self.owner.dx = -SNAIL_MOVE_SPEED
        ground_objs = self.owner.level:getObjects(self.owner.x, self.owner.y + self.owner.height)
        if not self.owner.falls_off_cliffs and not containsSolidObject(ground_objs) then
            self.new_direction = 'right'
            self.owner.dx = 0
        end
    else
        self.owner.dx = SNAIL_MOVE_SPEED
        ground_objs = self.owner.level:getObjects(self.owner.x + self.owner.width, self.owner.y + self.owner.height)
        if not self.owner.falls_off_cliffs and not containsSolidObject(ground_objs) then
            self.new_direction = 'left'
            self.owner.dx = 0
        end
    end

    self.owner:checkObjectCollisions()
end

function SnailMovingState:updateStage2(dt)
    self.owner:checkEntityCollisions()
end

function SnailMovingState:updateStage3(dt)
    -- change direction if bumped into a wall or into another entity.
    -- the velocity does not need to be set to 0 here, because it gets already set to 0 in the collision check functions.
    if (self.owner.is_collision_obj_lrtb[1] or self.owner.is_collision_ent_lrtb[1]) and self.owner.direction == 'left' then
        self.new_direction = 'right'
    elseif (self.owner.is_collision_obj_lrtb[2] or self.owner.is_collision_ent_lrtb[2]) and self.owner.direction == 'right' then
        self.new_direction = 'left'
    end
    -- set new direction of applicable
    if self.new_direction ~= self.owner.direction and self.dir_change_timer == 0 then
        self.owner.direction = self.new_direction
        self.dir_change_timer = 0.4
    end
end
