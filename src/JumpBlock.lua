--[[
    GD50
    -- Super Mario Bros. Remake --

    can contain a coin. can move.
    when player hits the bottom with a jump, the coin gets spawned.
]]

JumpBlock = Class{__includes = GameObject}

function JumpBlock:init(x, y, frame_id, level)
    -- init parent
    GameObject.init(self, {
        x = x, y = y,
        texture = 'jump-blocks', frame_id = frame_id,
        is_collidable = true, is_solid = true,
        level = level
    })
    -- determine the coin type randomly
    local coin_ind = math.random(1, #COIN_FRAME_IDS)
    self.coin_frame_id = COIN_FRAME_IDS[coin_ind]       -- texture of the coin
    self.coin_points = COIN_SCORE_POINTS[coin_ind]      -- points that the player gets from the coin
    -- coin object that gets spawned when block gets hit (if block contains a coin)
    self.coin = nil

    -- amount of the velocity vector if moving
    self.velocity = 0
    -- table containing anchor points with a x, y coordinate
    -- if the block is moving, it will move from anchor_point to anchor_point with the speed of self.velocity
    -- wrap around to the first point when at the last point
    self.anchor_points = {}
    self.anchor_point_nr_next = 0   -- index of the next anchor point

    -- the movement between the anchor points is done with this tween timer
    -- it can be started with startMovement()
    self.tween_timer = nil
end

-- overrides GameObject:doCollideWithEntity()
function JumpBlock:doCollideWithEntity(collision_data)
    -- check if the player hit the bottom with a jump
    if collision_data.entity.id == ENTITY_ID_PLAYER and collision_data.dy < 0 and self:getIntersectingEdgeHitbox(collision_data.hitbox)[4] then
        if self.frame_id == JUMP_BLOCK_FRAME_ID_FILLED then     -- if the block contains a coin
            -- add coin points to player score
            collision_data.entity.score = collision_data.entity.score + self.coin_points
            -- stop the block if it was moving
            self:stopMovement()
            -- change to emtpy block, so this code segment will only be executed once
            self.frame_id = JUMP_BLOCK_FRAME_ID_EMPTY

            -- use a tween timer to have a up- down moving effect
            local hit_tween_time = 0.08                     -- up- and downwards moving time in seconds
            local hit_tween_distance = TILE_SIZE / 4        -- up- and downwards moving distance
            Timer.tween(hit_tween_time, {
                [self] = {y = self.y - hit_tween_distance}
            })
            :finish(function()
                Timer.tween(hit_tween_time, {
                    [self] = {y = self.y + hit_tween_distance}
                })
            end)

            -- spawn a coin and insert it in the game level objects table to let it get rendered
            self.coin = GameObject({x = self.x, y = self.y, texture = 'coins', frame_id = self.coin_frame_id})
            table.insert(self.level.objects, self.coin)

            -- play the corresponding coind sound.
            -- stop previous sounds in case multiple blocks were hit at the same time to not have a overlay effect.
            gSounds['coin1']:stop()
            gSounds['coin2']:stop()
            gSounds['coin3']:stop()
            if self.coin_frame_id == COIN_FRAME_IDS[1] then
                gSounds['coin1']:play()
            elseif self.coin_frame_id == COIN_FRAME_IDS[2] then
                gSounds['coin2']:play()
            elseif self.coin_frame_id == COIN_FRAME_IDS[3] then
                gSounds['coin3']:play()
            end

            -- make a tween animation for the coin. remove the coin reference from the level and from this block itself when finished
            Timer.tween(0.2, {
                [self.coin] = {y = self.coin.y - self.coin.width}
            })
            :finish(function()
                self.coin.is_remove = true
                self.coin = nil
            end)
        elseif self.frame_id == JUMP_BLOCK_FRAME_ID_EMPTY then  -- if the block does not contain a coin
            gSounds['empty-block']:play()
        end
    end
end

-- this function starts the movement of the block according to the specified movement preset
-- a movement preset sets the anchor points and the velocity of the block
-- move_preset: input. valid presets are: 'l', 'r', 'u', 'd'
-- 'l': the block moves 1 Tile size to the left and back. Every anchor point is reached in 1 second. The velocity is 1 TILE_SIZE / s
-- 'r': the block moves 1 Tile size to the right and back. Every anchor point is reached in 1 second. The velocity is 1 TILE_SIZE / s
-- 'u': the block moves 1 Tile size up and back. Every anchor point is reached in 1 second. The velocity is 1 TILE_SIZE / s
-- 'd': the block moves 1 Tile size down and back. Every anchor point is reached in 1 second. The velocity is 1 TILE_SIZE / s
function JumpBlock:setMovementPreset(move_preset)
    local move_dist = TILE_SIZE

    self.anchor_points = {{x = self.x, y = self.y}}
    if move_preset == 'l' then
        table.insert(self.anchor_points, {x = self.anchor_points[1].x - move_dist, y = self.anchor_points[1].y})
    elseif move_preset == 'r' then
        table.insert(self.anchor_points, {x = self.anchor_points[1].x + move_dist, y = self.anchor_points[1].y})
    elseif move_preset == 'u' then
        table.insert(self.anchor_points, {x = self.anchor_points[1].x, y = self.anchor_points[1].y - move_dist})
    elseif move_preset == 'd' then
        table.insert(self.anchor_points, {x = self.anchor_points[1].x, y = self.anchor_points[1].y + move_dist})
    end

    if #self.anchor_points > 1 then
        self.velocity = move_dist / 1
        self.anchor_point_nr_next = 2
        self:startMovement()
    end
end

-- stop the movement by stopping self.tween_timer. Also set the velocity to 0
-- the movement can be started again with startMovement(). It will start from the point where it stopped
function JumpBlock:stopMovement()
    if self.tween_timer then
        self.tween_timer:remove()
    end
    self.dx = 0
    self.dy = 0
end

-- start the block movement by registering self.tween_timer
function JumpBlock:startMovement()
    -- distance between the current position and the next anchor point
    local distance = math.sqrt((self.anchor_points[self.anchor_point_nr_next].x - self.x)^2 + (self.anchor_points[self.anchor_point_nr_next].y - self.y)^2)

    if self.velocity == 0 or distance == 0 then
        return
    end

    -- time needed to reach the next anchor point
    local d_time = distance / self.velocity
    -- set velocity resulting from distance / time.
    -- The velocity is not needed inside this object itself because the tween timer does the movement, but it's needed in the collision detection functions
    self.dx = (self.anchor_points[self.anchor_point_nr_next].x - self.x) / d_time
    self.dy = (self.anchor_points[self.anchor_point_nr_next].y - self.y) / d_time

    -- note that when the timer gets registered, the block only starts moving in the next frame when executing Timer.update() again
    self.tween_timer = Timer.tween(d_time, {
        [self] = {x = self.anchor_points[self.anchor_point_nr_next].x, y = self.anchor_points[self.anchor_point_nr_next].y}
    }):finish(
        function()
            self.anchor_point_nr_next = (self.anchor_point_nr_next % #self.anchor_points) + 1
            self:startMovement()
        end
    )
end
