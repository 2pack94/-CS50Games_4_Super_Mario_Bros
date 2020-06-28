--[[
    GD50
    Super Mario Bros. Remake

    -- Snail Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    moves on the ground and can chase the player.
]]

SNAIL_MOVE_SPEED = 10

Snail = Class{__includes = Entity}

function Snail:init(x, y, level, player)
    -- init parent
    Entity.init(self, {
        x = x, y = y,
        width = CREATURE_SIZE,
        height = CREATURE_SIZE,
        hitboxes = {Rect(x, y + 4, CREATURE_SIZE, CREATURE_SIZE - 4)},  -- 1 hitbox that is aligned to the Snail texture
        texture = 'creatures',
        state_machine = StateMachine {      -- the StateMachine Classes get a reference to the snail, supplied as a parameter to their init methods when instantiated
            ['idle'] = function() return SnailIdleState(self) end,
            ['moving'] = function() return SnailMovingState(self) end,
            ['chasing'] = function() return SnailChasingState(self) end
        },
        id = ENTITY_ID_SNAIL,
        level = level
    })

    -- because the snail can chase the player, it needs a reference to it
    self.player = player
    -- distance in which the snail can spot the player and chase him
    self.scan_radius = 5 * TILE_SIZE
    -- if true the snail detects if there is a ledge and turns around if roaming. if chasing, it does not go beyond the ledge.
    self.falls_off_cliffs = false

    -- set initial state
    self.state_machine:change('idle')
end

-- overrides Entity:doCollideWithEntity()
function Snail:doCollideWithEntity(self_collision_data, opponent_collision_data)
    -- if player jumped on top of the snail
    if
        opponent_collision_data.entity.id == ENTITY_ID_PLAYER and
        self_collision_data.hitbox:getIntersectingEdgeHitbox(opponent_collision_data.hitbox)[3]
    then
        -- kill snail
        self:onScreenDeath()
        -- give points to the player
        opponent_collision_data.entity.score = opponent_collision_data.entity.score + POINTS_PER_ENEMY
    end
end
