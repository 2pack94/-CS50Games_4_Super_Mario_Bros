--[[
    GD50
    Super Mario Bros. Remake

    -- Entity Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Entities are all living things.
    Base Class for all entities.
]]

Entity = Class{__includes = Rect}

function Entity:init(def)
    -- pixel position
    self.x = def.x
    self.y = def.y
    -- dimensions
    self.width = def.width
    self.height = def.height

    -- an entity can have multiple hitboxes
    -- hitboxes are used in the collision detection functions
    -- entity hitboxes collide with objects and other entity hitboxes
    -- the order of the hitboxes in the hitboxes table is the priority.
    -- The priority determines the order in which the hitboxes are checked inside the collision detection functions.
    self.hitboxes = def.hitboxes or {Rect(self.x, self.y, self.width, self.height)}
    -- the hitbox offset is needed to realign the entity to the hitbox coordinates or the hitbox to the entity coordinates (after rebound or after set position)
    for _, hitbox in pairs(self.hitboxes) do
        hitbox.x_offset, hitbox.y_offset = hitbox.x - self.x, hitbox.y - self.y
    end

    -- velocity
    -- This does not include the velocity caused by collisions with moving objects or the mount velocity.
    -- This is not physically correct, but sufficient for simple mechanics and it simplifies the code.
    self.dx, self.dy = 0, 0

    -- key string of the gFrames table. Specifies the Spritesheet
    self.texture = def.texture
    -- Animation Class instance. Switches between the textures (frames) of the Entity that make up the animation.
    self.animation = def.animation or Animation()
    -- state machine to switch between entity states. entity states are Classes with their own update functions
    self.state_machine = def.state_machine or StateMachine()
    -- store the state if a State change occurs.
    -- switch to the new state at the end of the update function, to not instantiate multiple State classes in one frame.
    -- A change to the same state is possible. In this case a new object from the same State Class gets instantiated.
    self.new_state, self.new_state_params = nil, nil

    -- ID to differentiate between entities
    self.id = def.id

    -- reference to the platform/ object that the Entity stands on
    -- the entity can react to the platform movement with this
    self.mount = nil

    -- left or right movement direction which defines also the render direction (to mirror the texture)
    self.direction = 'right'
    -- vertical render direction
    self.vertical_direction = 'up'
    -- if entity is affected by gravity
    self.has_gravity = true

    -- self.is_alive = false when entity dies. A death animation will play.
    -- is_remove = true after death animation or if fallen into a chasm. It then gets removed from the game level entity table
    self.is_alive = true
    self.is_remove = false
    -- if entity collides with other entities. If false, rebounding between entities gets disabled, but the collision callback functions are still triggered
    self.collides_with_others = true
    -- store the side with which the entity collided with something else for every frame (only 1 side can be set to true)
    -- if entity collided with an object (with a rebound)
    self.is_collision_obj_lrtb = {false, false, false, false}
    -- if entity collided with an object or is touching the side of one (with or without a rebound)
    self.is_slight_collision_obj_lrtb = {false, false, false, false}
    -- if entity collided with a moving object that was also moving in the direction of the collided side (towards the entity)
    self.is_vel_collision_obj_lrtb = {false, false, false, false}
    -- if entity collided with another entity
    self.is_collision_ent_lrtb = {false, false, false, false}
    -- store references to objects and entities that collided with the entity in the current frame
    self.collided_objects = {}
    self.collided_entities = {}

    -- reference to the game level to be able to check collisions against other entities and objects
    self.level = def.level
end

-- set Entity Position to x, y
function Entity:setPosition(x, y)
    self.x = x
    self.y = y
    for _, hitbox in pairs(self.hitboxes) do
        hitbox.x, hitbox.y = self.x + hitbox.x_offset, self.y + hitbox.y_offset
    end
end

-- update entity position according to its velocity
function Entity:updatePosition(dt)
    -- if mounted, the entity mimics the movement of the mount object
    if self.mount then
        self.x = self.x + self.mount.dx * dt
        -- if the downward velocity of the mount is higher than the maximum falling velocity, don't stay on the mount. The entity will get unmounted as a result.
        if self.mount.dy <= MAX_Y_VELOCITY then
            self.y = self.y + self.mount.dy * dt
        end
    end
    -- apply gravity for all entities across all entity states.
    -- If it would only be applied in the Jump and Falling state, the Entity would not properly stay on downwards moving platforms
    -- update y position with Semi-implicit Euler Integration
    if self.has_gravity then
        self.dy = self.dy + GRAVITY * dt
        -- limit downward/ falling velocity
        self.dy = math.min(self.dy, MAX_Y_VELOCITY)
        self.y = self.y + self.dy * dt
    end
    -- move left and right if entity has a velocity
    self.x = self.x + self.dx * dt
    -- update also hitbox position
    for _, hitbox in pairs(self.hitboxes) do
        hitbox.x, hitbox.y = self.x + hitbox.x_offset, self.y + hitbox.y_offset
    end
end

--[[
    function prototypes that get called when an Entity collided with an entity or object/ tile respectively.
    override in an entity child class to respond to the collision
    self_collision_data, opponent_collision_data: input. Entity data before the collision/ rebound.
        contains members: entity: reference to the colliding Entity, hitbox: entity hitbox before collision,
        dx, dy: entity velocity before the collision
    object: input. reference to the collided object (objects don't get rebounded)
]]
function Entity:doCollideWithEntity(self_collision_data, opponent_collision_data) end
function Entity:doCollideWithObject(self_collision_data, object) end

-- triggered if entity dies on screen. The death animation happens implicitly due to the fact that self.is_alive = false disables collisions.
-- If the entity dies off screen (e.g. when falling into a chasm), this function does not need to be called
-- override this functions to get a custom death behaviour
function Entity:onScreenDeath()
    self.is_alive = false
    self.vertical_direction = 'down'
    gSounds['kill']:play()
end

-- collide with rigid objects such as (collidable) tiles and (collidable) Game objects.
-- They are both referred to as objects in this function
-- entities get rebounded on solid objects and the velocity component pointing to the collision surface gets set to 0.
-- for every collision, collision callback functions for the entity and the object get triggered.
-- only entities check collisions against objects. objects do not check collisions against entities.
function Entity:checkObjectCollisions()
    if not self.is_alive then
        self.mount = nil
        return
    end

    -- loop through all entity hitboxes in order of priority
    for _, hitbox in pairs(self.hitboxes) do
        -- objects/ tiles that the entity collides/ intersects with
        local objects_collided = {}
        -- objects/ tiles that the entity touches, but that it did not move into e.g. the wall at which the entity is standing
        -- these objects do not need to handle a collision and the entity does not need to get rebounded on them
        -- used to set the self.is_slight_collision_obj_lrtb flag
        local objects_slighly_collided = {}
        -- list of absolute rebound shift values. contains either the entity shift_x or shift_y value, depending on whats bigger
        -- used to sort the objects later after the collision sizes
        local shift_abs_list = {}

        -- convert coordinates of all 4 entity boundary corners to tile grid coordinates to select a subset of all tiles to use for collision checks.
        -- Tiles that get considered for the collision detection are:
        --      all tiles that the entity intersects with (also slight intersections where the coordinates of the overlapping edges are exactly the same)
        --      the tiles directly above and left of the entity which he doesn't collide with or just have a slight collision
        -- in a non-tile based platformer all objects would need to be organized in a quad tree data structure that spatially partitions the game world in order to do efficient collision detection.
        local check_x_start = math.floor(hitbox.x / TILE_SIZE)
        local check_x_end = math.floor((hitbox.x + hitbox.width) / TILE_SIZE) + 1
        local check_y_start = math.floor(hitbox.y / TILE_SIZE)
        local check_y_end = math.floor((hitbox.y + hitbox.height) / TILE_SIZE) + 1
        -- get colliding and slightly colliding Tiles
        for x = check_x_start, check_x_end do
            for y = check_y_start, check_y_end do
                if self.level.tiles[y] and self.level.tiles[y][x] and self.level.tiles[y][x].is_collidable then
                    local is_intersect, shift_x, shift_y = hitbox:getDisplacement(self.level.tiles[y][x])
                    if is_intersect then
                        table.insert(objects_collided, self.level.tiles[y][x])
                        table.insert(shift_abs_list, math.max(math.abs(shift_x), math.abs(shift_y)))
                    elseif hitbox:intersectsSlightly(self.level.tiles[y][x]) then
                        table.insert(objects_slighly_collided, self.level.tiles[y][x])
                    end
                end
            end
        end
        -- get colliding and slightly colliding game objects
        for _, object in pairs(self.level.objects) do
            if object and object.is_collidable then
                local is_intersect, shift_x, shift_y = hitbox:getDisplacement(object)
                if is_intersect then
                    table.insert(objects_collided, object)
                    table.insert(shift_abs_list, math.max(math.abs(shift_x), math.abs(shift_y)))
                elseif hitbox:intersectsSlightly(object) then
                    table.insert(objects_slighly_collided, object)
                end
            end
        end

        -- reverse sort the objects_collided array after the biggest shift_abs value.
        -- the highest shift_abs is obtained from a collision with an object whose center is the closest to the center of the entity (on each dimension).
        -- the collisions get resolved in this order. The advantage is, that if the entity collides with a corner of an object,
        -- but also with other objects (with a potentially bigger collision area), the major collisions get resolved first and the corner collision cannot push the entity in a potentially wrong direction.
        -- This is needed for entities with hitboxes that don't have special "shift" flags. It also has the positive side effect to get the optimal mount object.
        objects_collided = reverseSortWithHelperTbl(objects_collided, shift_abs_list)

        -- store entity collision data for the collision callback function in order to collide with every object in the same way as before the rebound (at least for the current hitbox)
        local entity_collision_data = {entity = self,
            hitbox = deepcopy(hitbox),
            dx = self.dx, dy = self.dy
        }

        for _, object in pairs(objects_collided) do
            -- get the side on which the hitbox is colliding with the object (if any) and rebound accordingly later.
            local intersects_lrtb = hitbox:getIntersectingEdgeHitbox(object)

            -- if do_collision = true, trigger the collision callback functions
            -- if the entity intersects only slightly after the rebound, still trigger the collision logic (e.g. when jumped into 2 objects simultaniously)
            -- if the entity is too far away from the object after a rebound, don't trigger the collision logic
            -- don't trigger the collision twice with the same object, possibly with another hitbox of the same entity (only do the rebound).
            -- first, a collision with the highest priority (first) entity hitbox is made with the object that this hitbox has the biggest collision size with.
            local do_collision = false
            if hitbox:intersectsSlightly(object) and not table.contains(self.collided_objects, object) then
                do_collision = true
            end

            -- rebound, set flags and set the velocity component pointing to the collision surface to 0.
            if table.contains(intersects_lrtb, true) and object.is_solid then
                if intersects_lrtb[1] then  -- left collision
                    hitbox.x = object.x + object.width
                    self.is_collision_obj_lrtb[1] = true
                    self.is_slight_collision_obj_lrtb[1] = true
                    self.dx = math.max(0, self.dx)
                    if object.dx > 0 then
                        self.is_vel_collision_obj_lrtb[1] = true
                    end
                elseif intersects_lrtb[2] then  -- right collision
                    hitbox.x = object.x - hitbox.width
                    self.is_collision_obj_lrtb[2] = true
                    self.is_slight_collision_obj_lrtb[2] = true
                    self.dx = math.min(0, self.dx)
                    if object.dx < 0 then
                        self.is_vel_collision_obj_lrtb[2] = true
                    end
                elseif intersects_lrtb[3] then  -- top collision
                    hitbox.y = object.y + object.height
                    self.is_collision_obj_lrtb[3] = true
                    self.is_slight_collision_obj_lrtb[3] = true
                    self.dy = math.max(0, self.dy)
                    if object.dy > 0 then
                        self.is_vel_collision_obj_lrtb[3] = true
                    end
                elseif intersects_lrtb[4] then  -- bottom collision
                    hitbox.y = object.y - hitbox.height
                    self.is_collision_obj_lrtb[4] = true
                    self.is_slight_collision_obj_lrtb[4] = true
                    self.dy = math.min(0, self.dy)
                    if object.dy < 0 then
                        self.is_vel_collision_obj_lrtb[4] = true
                    end
                    -- because the objects were ordered before, the mount object will be the one with the biggest collision size.
                    self.mount = object
                end
                -- after the hitbox was shifted, align the entity coordinates and all other hitboxes using the hitbox x, y offset values
                self:setPosition(hitbox.x - hitbox.x_offset, hitbox.y - hitbox.y_offset)
            end

            -- trigger collision callback functions
            if do_collision then
                table.insert(self.collided_objects, object)

                object:doCollideWithEntity(entity_collision_data)
                self:doCollideWithObject(entity_collision_data, object)
            end
        end

        -- after rebounding the hitbox, check on which sides the entity still slightly collides with objects that were previously selected as slightly colliding objects.
        for _, object in pairs(objects_slighly_collided) do
            local side = 1
            for _, is_slight_collision in pairs(hitbox:getSlightlyIntersectingEdge(object)) do
                if is_slight_collision and object.is_solid then
                    self.is_slight_collision_obj_lrtb[side] = true
                end
                side = side + 1
            end
        end
    end

    -- unmount from object if no bottom collision occured
    if not self.is_slight_collision_obj_lrtb[4] then
        self.mount = nil
    end

    -- check if the entity was crushed between 2 objects. At least one of the objects has to be moving towards the entity.
    if
        (self.is_vel_collision_obj_lrtb[1] and self.is_collision_obj_lrtb[2]) or
        (self.is_vel_collision_obj_lrtb[2] and self.is_collision_obj_lrtb[1]) or
        (self.is_vel_collision_obj_lrtb[3] and self.is_collision_obj_lrtb[4]) or
        (self.is_vel_collision_obj_lrtb[4] and self.is_collision_obj_lrtb[3])
    then
        self:onScreenDeath()
    end
end

-- check collisions between all other entities
-- The difference between object collisions is that both entities that are part of the collision can get rebounded. Also every entity checks collisions against all other entities.
-- for every collision, collision callback functions for both entities get triggered.
function Entity:checkEntityCollisions()
    if not self.is_alive then
        return
    end
    -- loop through all entity hitboxes in order of priority
    -- every hitbox of this entity checks collisions with all hitboxes of all other entities. And all other entities do the same in every frame.
    for _, hitbox in pairs(self.hitboxes) do
        -- entities that the entity collides/ intersects with
        local entities_collided = {}
        -- list of absolute rebound shift values. contains either the self shift_x or shift_y value from the opponent entity hitbox with the biggest collision size, depending on whats bigger
        -- used to sort the entities later after the collision sizes
        local shift_abs_list = {}

        -- get the colliding entities
        for _, entity in pairs(self.level.entities) do
            -- self is in the entity list too
            if self ~= entity and entity.is_alive then
                local shift_abs_max = 0
                -- use the biggest absolute shift value from the entity hitbox with the biggest collision shift value
                for _, entity_hitbox in pairs(entity.hitboxes) do
                    local is_intersect, shift_x, shift_y = hitbox:getDisplacement(entity_hitbox)
                    if is_intersect then
                        shift_abs_max = math.max(shift_abs_max, math.max(math.abs(shift_x), math.abs(shift_y)))
                    end
                end
                if shift_abs_max > 0 then
                    table.insert(entities_collided, entity)
                    table.insert(shift_abs_list, shift_abs_max)
                end
            end
        end

        -- reverse sort the entities_collided array after the biggest shift_abs value. (see object collisions)
        entities_collided = reverseSortWithHelperTbl(entities_collided, shift_abs_list)
        -- store self collision data for the collision callback function in order to collide with every other entity in the same way as before the rebound (at least for the current hitbox)
        local self_collision_data = {entity = self,
            hitbox = deepcopy(hitbox),
            dx = self.dx, dy = self.dy
        }

        for _, entity in pairs(entities_collided) do
            for _, entity_hitbox in pairs(entity.hitboxes) do
                -- store opponent collision data for the collision callback function in order to collide with it as before the rebound (at least for the current hitbox)
                local opponent_collision_data = {entity = entity,
                    hitbox = deepcopy(entity_hitbox),
                    dx = entity.dx, dy = entity.dy
                }
                -- get the side on which the hitbox is colliding with the entity hitbox (if any) and rebound accordingly later.
                local intersects_lrtb = hitbox:getIntersectingEdgeHitbox(entity_hitbox)
                -- if do_collision = true, trigger the collision callback functions of both entities
                -- if the entity intersects only slightly after the rebound, still trigger the collision logic
                -- if the entity is too far away from the other entity after a rebound, don't trigger the collision logic
                -- don't trigger the collision twice with the same entity (only do the rebound).
                -- This can happen if more than 1 hitbox of an entity is colliding with another one or if an entity gets pushed back into the same entity again because of a later collision in the same frame.
                -- first, a collision with the highest priority (first) self hitbox is made with the highest priority (first) other entity hitbox
                local do_collision = false
                if hitbox:intersectsSlightly(entity_hitbox) and not table.contains(self.collided_entities, entity) then
                    do_collision = true
                end

                -- the shift factor specifies the shift ratio that the current hitbox of self will get shifted during rebound. The other entity will then get shifted by the remaining part.
                -- the shift factor is determined from the speed ratio of the entities. The higher the speed of self in the collision surface direction, the higher shift_factor becomes
                -- if both entities have no velocity while colliding, they will both get shifted 50/50
                -- if a pushing mechanic is desired, it can be implemented at another place outside of the collision detection function
                local shift_factor = 0.5
                -- the rebounding of an entity gets prevented under certain circumstances with these flags
                -- if an entity is at the wall it should not gets pushed into the wall by another entity
                -- rather push entities into each other in this case
                local is_rebound_self = false
                local is_rebound_opponent = false

                -- set flags and set the velocity component pointing to the collision surface to 0. Do all of that for both entities symmetrically
                if table.contains(intersects_lrtb, true) and self.collides_with_others and entity.collides_with_others then
                    if intersects_lrtb[3] or intersects_lrtb[4] then    -- top or bottom collision of self
                        -- dy is the relevant velocity to determine the shift_factor
                        local dy_abs_sum = math.abs(self.dy) + math.abs(entity.dy)
                        if dy_abs_sum > 0 then
                            shift_factor = math.abs(self.dy) / dy_abs_sum
                        end
                        if shift_factor > 0 then
                            is_rebound_self = true
                        end
                        if shift_factor < 1 then
                            is_rebound_opponent = true
                        end
                        -- a top collision for self is a bottom collision for the opponent and vice versa
                        if intersects_lrtb[3] then
                            self.is_collision_ent_lrtb[3] = true
                            entity.is_collision_ent_lrtb[4] = true
                            self.dy = math.max(0, self.dy)
                            entity.dy = math.min(0, entity.dy)
                        elseif intersects_lrtb[4] then
                            self.is_collision_ent_lrtb[4] = true
                            entity.is_collision_ent_lrtb[3] = true
                            self.dy = math.min(0, self.dy)
                            entity.dy = math.max(0, entity.dy)
                        end
                        -- if self cannot move up or down
                        if (self.is_collision_ent_lrtb[3] and self.is_slight_collision_obj_lrtb[4]) or (self.is_collision_ent_lrtb[4] and self.is_slight_collision_obj_lrtb[3]) then
                            is_rebound_self = false
                        end
                        -- if the opponent cannot move up or down
                        if (entity.is_collision_ent_lrtb[3] and entity.is_slight_collision_obj_lrtb[4]) or (entity.is_collision_ent_lrtb[4] and entity.is_slight_collision_obj_lrtb[3]) then
                            is_rebound_opponent = false
                            shift_factor = 1
                        end
                    else        -- right or left collision of self
                        -- dx is the relevant velocity to determine the shift_factor
                        local dx_abs_sum = math.abs(self.dx) + math.abs(entity.dx)
                        if dx_abs_sum > 0 then
                            shift_factor = math.abs(self.dx) / dx_abs_sum
                        end
                        if shift_factor > 0 then
                            is_rebound_self = true
                        end
                        if shift_factor < 1 then
                            is_rebound_opponent = true
                        end
                        -- a left collision for self is a right collision for the opponent and vice versa
                        if intersects_lrtb[1] then
                            self.is_collision_ent_lrtb[1] = true
                            entity.is_collision_ent_lrtb[2] = true
                            self.dx = math.max(0, self.dx)
                            entity.dx = math.min(0, entity.dx)
                        elseif intersects_lrtb[2] then
                            self.is_collision_ent_lrtb[2] = true
                            entity.is_collision_ent_lrtb[1] = true
                            self.dx = math.min(0, self.dx)
                            entity.dx = math.max(0, entity.dx)
                        end
                        -- if self cannot move left or right
                        if (self.is_collision_ent_lrtb[1] and self.is_slight_collision_obj_lrtb[2]) or (self.is_collision_ent_lrtb[2] and self.is_slight_collision_obj_lrtb[1]) then
                            is_rebound_self = false
                        end
                        -- if the opponent cannot move left or right
                        if (entity.is_collision_ent_lrtb[1] and entity.is_slight_collision_obj_lrtb[2]) or (entity.is_collision_ent_lrtb[2] and entity.is_slight_collision_obj_lrtb[1]) then
                            is_rebound_opponent = false
                            shift_factor = 1
                        end

                    end
                    -- rebound self by the amount specified by shift_factor and then the opponent by the rest amount
                    if is_rebound_self then
                        local shift_x, shift_y = 0, 0
                        if intersects_lrtb[1] then
                            shift_x = ((entity_hitbox.x + entity_hitbox.width) - hitbox.x) * shift_factor
                        elseif intersects_lrtb[2] then
                            shift_x = ((entity_hitbox.x - hitbox.width) - hitbox.x) * shift_factor
                        elseif intersects_lrtb[3] then
                            shift_y = ((entity_hitbox.y + entity_hitbox.height) - hitbox.y) * shift_factor
                        elseif intersects_lrtb[4] then
                            shift_y = ((entity_hitbox.y - hitbox.height) - hitbox.y) * shift_factor
                        end
                        if shift_x ~= 0 then
                            hitbox.x = hitbox.x + shift_x
                        elseif shift_y ~= 0 then
                            hitbox.y = hitbox.y + shift_y
                        end
                    end
                    if is_rebound_opponent then
                        if intersects_lrtb[1] then
                            entity_hitbox.x = hitbox.x - entity_hitbox.width
                        elseif intersects_lrtb[2] then
                            entity_hitbox.x = hitbox.x + hitbox.width
                        elseif intersects_lrtb[3] then
                            entity_hitbox.y = hitbox.y - entity_hitbox.height
                        elseif intersects_lrtb[4] then
                            entity_hitbox.y = hitbox.y + hitbox.height
                        end
                    end
                    -- after the hitbox was shifted, align the entity coordinates and all other hitboxes using the hitbox x, y offset values
                    self:setPosition(hitbox.x - hitbox.x_offset, hitbox.y - hitbox.y_offset)
                    entity:setPosition(entity_hitbox.x - entity_hitbox.x_offset, entity_hitbox.y - entity_hitbox.y_offset)
                end

                -- trigger collision callback functions (symmetrically for both entities)
                if do_collision then
                    -- when the opponent entity gets updated later, it will not reach this point of the code again for the same entity.
                    table.insert(self.collided_entities, entity)
                    table.insert(entity.collided_entities, self)

                    entity:doCollideWithEntity(opponent_collision_data, self_collision_data)
                    self:doCollideWithEntity(self_collision_data, opponent_collision_data)

                    -- if an entity just got rebounded (for the first time with this opponent entity), recursively call this function again to check if the entity collides with a new entity after the rebound
                    -- This goes on until all collisions are resolved. It increases the accuracy of the simulation.
                    -- e.g. when multiple entities are stacked on top of each other and every entity falls down as a result of gravity,
                    -- not every entity might detect a collision in the same frame depending on the entity update order.
                    -- For the purpose of this simple platformer this is not really needed though.
                    if is_rebound_self then
                        self:checkEntityCollisions()
                    end
                    if is_rebound_opponent then
                        entity:checkEntityCollisions()
                    end
                end
            end
        end
    end
end

-- Entities have 3 update stages. Only after all entities have executed a stage, the next update stage shall be executed for all entities.
-- This is needed for a more accurate calculation of the entity - entity collisions, which should be independent of the update order.
-- Entities get updated after all game objects got updated.
-- update stage 1 should contain the movement of the entity and the entity - objects collision checks.
-- update stage 2 should contain the entity - entity collision checks.
-- This way it can be ensured that all entities are updated in the current frame and entities from the current frame don't get compared with entities from the last frame
-- update stage 3 can contain an entity state change check, based on the previous calculated collisions (e.g. the collision side members are all available at this point)

-- function that should be executed at the start of update stage 1.
-- resets members that get calculated every frame.
function Entity:commonEntryTask(dt)
    self.collided_objects = {}
    self.collided_entities = {}
    self.is_collision_obj_lrtb = {false, false, false, false}
    self.is_vel_collision_obj_lrtb = {false, false, false, false}
    self.is_slight_collision_obj_lrtb = {false, false, false, false}
    self.is_collision_ent_lrtb = {false, false, false, false}
end

-- function that should be executed at the end of update stage 3.
-- check game level boundaries. change to a new entity state if necessary.
function Entity:commonExitTask(dt)
    -- constrain entity x no matter which state
    if self.x < 0 then
        self.x = 0
        self.dx = math.max(0, self.dx)
    elseif self.x > TILE_SIZE * self.level.grid_width - self.width then
        self.x = TILE_SIZE * self.level.grid_width - self.width
        self.dx = math.min(0, self.dx)
    end
    -- if fallen below the map boundary, remove entity (death animation can be skipped)
    if self.y > VIRTUAL_HEIGHT then
        self.is_alive = false
        self.is_remove = true
    end
    -- change to a new entity state if necessary.
    if self.new_state then
        self.state_machine:change(self.new_state, self.new_state_params)
        self.new_state, self.new_state_params = nil, nil
    end
end

-- 3 update stages. Most of the update logic is inside the Entity state classes.
function Entity:updateStage1(dt)
    self:commonEntryTask(dt)
    self.animation:update(dt)
    self.state_machine.current:updateStage1(dt)
end

function Entity:updateStage2(dt)
    self.state_machine.current:updateStage2(dt)
end

function Entity:updateStage3(dt)
    self.state_machine.current:updateStage3(dt)
    self:commonExitTask(dt)
end

-- this function is only used inside PlayState when the player died. Otherwise the update stages are used separately.
function Entity:update(dt)
    self:updateStage1(dt)
    self:updateStage2(dt)
    self:updateStage3(dt)
end

function Entity:render()
    -- get the current frame from the Animation class
    -- all entity textures in the sprite sheet are all facing to the right
    -- if self.direction == 'left' the y scale factor will be set to -1. The entity gets mirrored on its y position value. same principal for self.vertical_direction.
    -- set the origin to the center with the x, y origin offset. The mirroring will be applied relative to the origin. This keeps the texture at its place when mirroring.
    -- the x, y position has to be adjusted by the same origin shift amount, to render the entity at the correct position.
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.animation:getCurrentFrame()],
        math.floor(self.x) + self.width / 2, math.floor(self.y) + self.height / 2, 0,           -- x, y position, orientation (0)
        self.direction == 'left' and -1 or 1, self.vertical_direction == 'down' and -1 or 1,    -- x, y scale factor
        self.width / 2, self.height / 2                                                         -- x, y origin offset
    )
end
