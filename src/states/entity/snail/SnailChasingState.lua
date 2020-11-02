--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

SnailChasingState = Class{__includes = BaseState}

-- enter when the player is nearby
function SnailChasingState:init(owner)
    self.owner = owner
    self.owner.animation = Animation(SNAIL_FRAME_IDS_MOVING, 0.5)

    -- set starting direction
    if self.owner.player.x < self.owner.x then
        self.owner.direction = 'left'
        self.owner.dx = -SNAIL_MOVE_SPEED
    else
        self.owner.direction = 'right'
        self.owner.dx = SNAIL_MOVE_SPEED
    end
end

function SnailChasingState:updateStage1(dt)
    -- if the distance between snail and player became bigger than scan_radius, stop chasing
    if math.sqrt((self.owner.player.x - self.owner.x)^2 + (self.owner.player.y - self.owner.y)^2) > self.owner.scan_radius then
        self.owner.new_state = math.random() < 0.5 and 'idle' or 'moving'
    end

    -- change direction based on player x coordinate
    -- have a hysteresis, so that the snail can not change its direction every frame when it reached self.owner.player.x
    if self.owner.x > self.owner.player.x + 1 then
        self.owner.direction = 'left'
        self.owner.dx = -SNAIL_MOVE_SPEED
    elseif self.owner.x < self.owner.player.x - 1 then
        self.owner.direction = 'right'
        self.owner.dx = SNAIL_MOVE_SPEED
    else
        self.owner.dx = 0
    end

    -- when moving left scan objects on the bottom left of the snail
    -- when moving right scan objects on the bottom right of the snail
    -- stop movement if no ground found
    local ground_objs = {}
    if self.owner.direction == 'left' then
        ground_objs = self.owner.level:getObjects(self.owner.x, self.owner.y + self.owner.height)
    else
        ground_objs = self.owner.level:getObjects(self.owner.x + self.owner.width, self.owner.y + self.owner.height)
    end
    if not self.owner.falls_off_cliffs and not containsSolidObject(ground_objs) then
        self.owner.dx = 0
    end

    self.owner:updatePosition(dt)

    self.owner:checkObjectCollisions()
end

function SnailChasingState:updateStage2(dt)
    self.owner:checkEntityCollisions()
end

function SnailChasingState:updateStage3(dt) end
