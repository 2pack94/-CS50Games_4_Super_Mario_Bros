--[[
    GD50
    Super Mario Bros. Remake

    -- SnailIdleState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

SnailIdleState = Class{__includes = BaseState}

function SnailIdleState:init(owner)
    self.owner = owner
    -- set velocity to 0 instantly
    self.owner.dx = 0
    -- change to a new state somewhere in this time window
    self.wait_period_max = 5
    self.wait_period = math.random(self.wait_period_max)
    -- measure time in this state
    self.wait_timer = 0
    self.owner.animation = Animation(SNAIL_FRAME_ID_IDLE)
end

function SnailIdleState:updateStage1(dt)
    self.wait_timer = self.wait_timer + dt
    if self.wait_timer >= self.wait_period then
        self.owner.new_state = 'moving'
    end

    -- if the distance between snail and player is smaller than scan_radius, chase the player
    if math.sqrt((self.owner.player.x - self.owner.x)^2 + (self.owner.player.y - self.owner.y)^2) < self.owner.scan_radius then
        self.owner.new_state = 'chasing'
    end

    -- still needed, because the snail could have a mount
    self.owner:updatePosition(dt)

    self.owner:checkObjectCollisions()
end

function SnailIdleState:updateStage2(dt)
    self.owner:checkEntityCollisions()
end

function SnailIdleState:updateStage3(dt) end
