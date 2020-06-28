--[[
    GD50
    Super Mario Bros. Remake

    -- GameLevel Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    generates and updates the game level
]]

GameLevel = Class{}

function GameLevel:init(grid_width)
    self.entities = {}      -- Table of Entity objects. entities are all living things.
    self.objects = {}       -- Table of GameObject objects. game objects are non living things that are not tiles: jump blocks, plants, ...
    self.tiles = {}         -- Tile objects (normal ground/ platforms) contained in the level. all rows of tiles are in a separate sub-table.
    self.background = nil   -- contains the frame ID for the background texture
    -- dimensions of the level in tiles
    self.grid_width = grid_width
    self.grid_height = math.ceil(VIRTUAL_HEIGHT / TILE_SIZE)     -- the level generation does not go above the screen (y camera position is fixed)
    -- create the level
    self:generate()
end

-- fill self.objects, self.tiles and self.background with content
-- the level will get generated randomly
function GameLevel:generate()
    local tile_frame_id = TILE_FRAME_ID_FULL    -- tile frame ID to use for the current tile.
    local topper_frame_id = nil                 -- topper frame ID to use for the topper of the current tile

    -- choose a random texture set for the level. The global tables below contain set frame ID's (or background frame ID's). set frame ID's at the same index fit together.
    local set_ind = math.random(#TILESET_FRAME_IDS)
    local tileset = TILESET_FRAME_IDS[set_ind]
    local topperset = TOPPERSET_FRAME_IDS[set_ind]
    self.background = BACKGROUND_FRAME_IDS[set_ind]

    -- level generation parameters
    -- height, width and distances are measured in tiles. The height is measured from bottom to top (in reverse y-axis direction)
    -- the player must be able to traverse the level from left to right and the other way around without beeing blocked.
    -- player jump height: about 3.5 tiles, player height: 1.25 tiles
    -- the spawn probability of some objects can be a bit lower than specified in the parameter, because the object might have restrictions on where it can spawn.
    -- chasm variables
    self.chasm_p = 0.15             -- per column probability to generate a chasm. range: 0 .. 1
    self.chasm_width_max = 3        -- maximum width of the chasm to generate
    self.chasm_width_min = 1        -- minimum width of the chasm to generate
    local is_chasm = false          -- flag to indicate if a chasm is currently generated
    -- section variables. A section has a specific ground height (or is a chasm).
    self.section_width_max = 7      -- maximum width of a ground section
    self.section_width_min = 1      -- minimum width of a ground section
    local section_w_cur = 0         -- width of the current section
    local section_w_count = 0       -- counter for the current section width. counts backwards
    -- ground height variables
    self.ground_height_max = self.grid_height - 2   -- don't generate anything above this height
    self.ground_height_min = 1      -- don't generate anything below this height. 1 is the lowest tile that can be seen on the screen
    local ground_height_cur = 3     -- ground height of the current section. the initial value defines the heights at which the game level can start
    local ground_height_prev = 0    -- ground height of the previous section.
    self.ledge_height_max = 3       -- maximum ground height difference between 2 consecutive level columns
    self.ledge_height_min = 1       -- minimum ground height difference between 2 consecutive level columns
    -- platform variables
    self.platform_p = 0.15              -- per column probability to generate a platform. range: 0 .. 1
    self.platform_width_max = 6         -- maximum width of a platform to generate
    self.platform_width_min = 2         -- minimum width of a platform to generate
    local platform_height = 0           -- heigth of the current platform
    local platform_ground_d = 0         -- distance between the current platform and the ground
    self.platform_ground_d_max = 2      -- maximum distance between a platform and the ground
    self.platform_ground_d_min = 2      -- minimum distance between a platform and the ground
    -- jump blocks
    self.jump_block_p = 0.2             -- per column probability to generate a jump block. range: 0 .. 1
    self.jump_block_moving_p = 0.3      -- probability that a generated jump block can move
    local jump_block_height = 0         -- height of the current block
    local jump_block_ground_d = 0       -- distance between the current block and the ground/ platform
    self.jump_block_ground_d_max = 3    -- maximum distance between a jump block and the ground/ platform
    self.jump_block_ground_d_min = 2    -- minimum distance between a jump block and the ground/ platform
    -- misc
    self.flora_p = 0.2          -- probability to generate a bush/ cactus/ grass decoration on top of a tile
    self.entity_p = 0.15        -- probability to spawn an enemy on top of a tile

    -- initialize self.tiles. The tiles at the row self.grid_height are at the lowest layer that is still visible.
    for y = 1, self.grid_height do
        -- insert tables representing the rows of tiles for this level
        table.insert(self.tiles, {})
        for _ = 1, self.grid_width do
            -- fill the tables with nil values
            table.insert(self.tiles[y], nil)
        end
    end

    -- do a column by column random level generation
    -- generate the ground layers of the level with Tiles
    for x = 1, self.grid_width do
        -- a new section should start
        if section_w_count == 0 then
            -- create a chasm with a chance of self.chasm_p (if not at the edges of the level). Don't create another chasm if the generation of one has just ended.
            local chasm_width = math.random(self.chasm_width_min, self.chasm_width_max)     -- choose a random chasm width. The chasm should not reach the right edge of the level
            if x > 1 and x + chasm_width - 1 < self.grid_width and not is_chasm and math.random() < self.chasm_p then
                is_chasm = true
                section_w_count = chasm_width

            -- if no chasm, create a ground section
            else
                is_chasm = false
                -- choose a random ledge height (upwards or downwards)
                -- do not create a ledge that is too high (or too low). The ground height should also not be too high or too low.
                local ledge_height = 0
                repeat
                    ledge_height = math.random(self.ledge_height_min, self.ledge_height_max)
                    ledge_height = math.random() < 0.5 and -ledge_height or ledge_height
                until ground_height_cur + ledge_height >= self.ground_height_min and ground_height_cur + ledge_height <= self.ground_height_max
                ground_height_cur = ground_height_cur + ledge_height

                section_w_count = math.random(self.section_width_min, self.section_width_max)
            end
        end

        -- create a chasm by not inserting tiles into self.tiles
        -- otherwise create ground by inserting tiles into self.tiles for this column (x)
        if not is_chasm then
            -- because the flag pole at the end of the level is so high, make sure that it fits on the screen
            if x == self.grid_width then
                ground_height_cur = math.min(ground_height_cur, self.grid_height - math.ceil(FLAG_POLE_HEIGHT / TILE_SIZE))
            end
            for y = self.grid_height, self.grid_height - ground_height_cur + 1, -1 do
                if y == self.grid_height - ground_height_cur + 1 then
                    topper_frame_id = TOPPER_FRAME_ID_FLAT      -- add a topper for the topmost tile
                else
                    topper_frame_id = nil
                end
                self.tiles[y][x] = Tile(x, y, tile_frame_id, topper_frame_id, tileset, topperset)
            end
        end

        -- decrement section_w_count. The section ends if it reaches 0
        section_w_count = math.max(section_w_count - 1, 0)
    end

    -- re-initialize variables
    -- section_w_count is now used to count down the platform width
    section_w_count = 0
    ground_height_cur = 0

    -- create platforms based on the generated ground tiles
    -- counter that starts after a platform was generated. counts backwards. the counter value determines for how many tiles no platforms will be generated.
    local platform_gen_cooldown = 0

    -- the player should be able to jump on all platforms. the platforms should not block the player from progressing the level
    for x = 1, self.grid_width do
        -- store ground height (if not a chasm)
        local ground_height_cur_tmp = self:getHeightLevels(x)[1]
        if ground_height_cur_tmp > 0 then
            ground_height_cur = ground_height_cur_tmp
        end
        -- if no platform is currently generated and platform generation is not on cooldown
        if platform_gen_cooldown == 0 and section_w_count == 0 then
            local is_platform = false   -- flag to indicate if a platform will be generated
            section_w_count = math.random(self.platform_width_min, self.platform_width_max)   -- determine platform width
            section_w_cur = section_w_count     -- store the width of the current platform

            -- create a platform with a chance of self.platform_p. don't generate a platform at the start or end of the level
            if x > 2 and x < self.grid_width - section_w_count - 1 and math.random() < self.platform_p then
                platform_ground_d = math.random(self.platform_ground_d_min, self.platform_ground_d_max)
                -- differentiate between the ground height left and right of the platform and directly under the platform.
                -- initialize the heights with the last ground height (in case there is a big chasm)
                local ground_h_plat_side = ground_height_prev
                local ground_h_plat_middle = ground_height_prev
                -- determine the highest ground height under the platform.
                -- The ground at the side of the platform is considered to be 3 tiles left and right each. From that ground the platform is usually jumped on
                for x_platform = x - 3, x + section_w_count + 2 do
                    if x_platform < x or x_platform >= x + section_w_count then
                        ground_h_plat_side = math.max(ground_h_plat_side, self:getHeightLevels(x_platform)[1])
                    else
                        ground_h_plat_middle = math.max(ground_h_plat_middle, self:getHeightLevels(x_platform)[1])
                    end
                end
                -- calculate the platform height, depending on the ground height at the platform sides
                -- if the ground directly under the platform would be considered too, the platform would maybe not be reachable (if the sides were lower).
                platform_height = ground_h_plat_side + platform_ground_d + 1
                -- don't generate a platform if it would be too high.
                -- don't generate a platform if the ground under the platform is higher than at the sides (player could get blocked otherwise)
                if platform_height <= self.ground_height_max and ground_h_plat_side >= ground_h_plat_middle then
                    is_platform = true
                end
            end

            -- if no platform will be generated, reset the variables
            if not is_platform then
                section_w_count = 0
                section_w_cur = 0
            end
        end

        platform_gen_cooldown = math.max(platform_gen_cooldown - 1, 0)

        -- insert the tiles for the platform if one should be generated
        if section_w_count > 0 then
            -- the sides of the platform should be a rounded tile
            -- first tile of platform
            if section_w_count == section_w_cur then
                tile_frame_id = TILE_FRAME_ID_ROUNDED_LEFT_BOTTOM
            end
            -- platform middle tiles
            if section_w_count > 1 and section_w_count < section_w_cur then
                tile_frame_id = TILE_FRAME_ID_FULL
            end
            -- last tile of the platform
            if section_w_count == 1 then
                platform_gen_cooldown = 1       -- add a platform generation cooldown
                tile_frame_id = TILE_FRAME_ID_ROUNDED_RIGHT_BOTTOM
            end
            -- if the platform is only 1 tile, use a both sides rounded tile instead
            if section_w_cur == 1 then
                tile_frame_id = TILE_FRAME_ID_ROUNDED_BOTTOM
            end
            local y = self.grid_height - platform_height + 1
            -- insert a tile (if it does not replace an already existing tile) at the specific x, y coordinates
            if not self.tiles[y][x] or not self.tiles[y][x].is_collidable then
                self.tiles[y][x] = Tile(x, y, tile_frame_id, TOPPER_FRAME_ID_FLAT, tileset, topperset)
            end
        end

        section_w_count = math.max(section_w_count - 1, 0)
        ground_height_prev = ground_height_cur
    end

    -- generate vegetation (only for decoration)
    for x = 1, self.grid_width do
        -- get all levels of solid ground for this column where a plant texture can be placed (including platforms)
        local height_levels = self:getHeightLevels(x)

        for _, height_level in pairs(height_levels) do
            -- create a plant with a chance of self.flora_p (if not chasm or end of the level)
            if x < self.grid_width and height_level > 0 and math.random() < self.flora_p then
                -- the height at which the texture is placed is one above the ground height
                local y = self.grid_height - height_level
                -- the frame_id is an index in the 'plants' spritesheet. The frame ID's to choose from depend on the level type which is defined by the background texture
                local frame_id = PLANT_FRAME_IDS[self.background][math.random(#PLANT_FRAME_IDS[self.background])]
                -- instantiate a GameObject which only renders the texture at the corresponding position
                table.insert(self.objects, GameObject({x = (x - 1) * TILE_SIZE, y = (y - 1) * TILE_SIZE, texture = 'plants', frame_id = frame_id}))
            end
        end
    end

    -- generate jump blocks
    -- don't spawn a jump block under a platform, but on top of a platform.
    -- the jump blocks need to be modified later once created, so store them in a separate table
    local jump_blocks = {}
    for x = 1, self.grid_width do
        -- get all levels of solid ground for this column
        local height_levels = self:getHeightLevels(x)
        -- get highest position
        ground_height_cur = height_levels[#height_levels]
        -- if not a chasm or start or end of the level generate a block with a chance of self.jump_block_p
        if x > 2 and x < self.grid_width - 1 and ground_height_cur > 0 and math.random() < self.jump_block_p then
            jump_block_ground_d = math.random(self.jump_block_ground_d_min, self.jump_block_ground_d_max)
            local ground_h_base = ground_height_cur
            -- determine the highest ground height under the block.
            -- The ground at the side of the block is considered to be 1 tile left and right each. From that ground the block is usually jumped on.
            local height_levels_scan = nil
            local do_spawn = true
            for x_block = x - 1, x + 1 do
                height_levels_scan = self:getHeightLevels(x_block)
                -- don't spawn a block at the edge of a chasm
                if #height_levels == 1 and height_levels_scan[1] == 0 then
                    do_spawn = false
                    break
                end
                ground_h_base = math.max(ground_h_base, height_levels_scan[#height_levels_scan])
            end
            jump_block_height = ground_h_base + jump_block_ground_d + 1
            if do_spawn and jump_block_height <= self.ground_height_max then
                local y = self.grid_height - jump_block_height + 1
                -- instantiate a Jump Block object with a coin in it
                local jump_block = JumpBlock((x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, JUMP_BLOCK_FRAME_ID_FILLED, self)
                table.insert(self.objects, jump_block)
                table.insert(jump_blocks, jump_block)
            end
        end
    end

    -- give movement to selected jump blocks
    for _, jump_block in pairs(jump_blocks) do
        if math.random() < self.jump_block_moving_p then
            -- convert block grid coordinates to pixel coordinates
            local x, y = math.floor(jump_block.x / TILE_SIZE) + 1, math.floor(jump_block.y / TILE_SIZE) + 1
            -- determine the movement direction freedom that the jump block has. A moving block should not overlap with another solid object
            -- two jump blocks can theoretically still overlap, when they are next to each other with different height levels and one is moving horizontally and the other is moving vertically
            -- a block has the following movement options: right <-> left or up <-> down. They are represented by the table can_move_lrud
            local can_move_lrud = {true, true, true, true}
            -- check if there is a solid object left or right of the block. The up and down movement is always possible
            for x_block = x - 2, x + 2 do
                if x_block ~= x then
                    -- point to the center of potential objects/ tiles to get them
                    local objects = self:getObjects((x_block - 1) * TILE_SIZE + TILE_SIZE / 2, (y - 1) * TILE_SIZE + TILE_SIZE / 2)
                    if containsSolidObject(objects) then
                        if x_block < x then
                            can_move_lrud[1] = false    -- the starting movement direction can not be left
                        elseif x_block > x then
                            can_move_lrud[2] = false    -- the starting movement direction can not be right
                        end
                    end
                end
            end
            -- get another representation of the available movement starting directions
            -- choose one available option randomly and give the block the ability to move
            local can_move_dir = {}
            if can_move_lrud[1] then
                table.insert(can_move_dir, 'l')
            end
            if can_move_lrud[2] then
                table.insert(can_move_dir, 'r')
            end
            if can_move_lrud[3] then
                table.insert(can_move_dir, 'u')
            end
            if can_move_lrud[4] then
                table.insert(can_move_dir, 'd')
            end
            if #can_move_dir > 0 then
                jump_block:setMovementPreset(can_move_dir[math.random(1, #can_move_dir)])
            end
        end
    end

    -- generate the flag pole at the end of the level, to mark the level goal
    -- the height at which the texture is placed is one above the ground height
    table.insert(self.objects, FlagPole(
        (self.grid_width - 1) * TILE_SIZE,
        (self.grid_height - self:getHeightLevels(self.grid_width)[1] - (FLAG_POLE_HEIGHT / TILE_SIZE)) * TILE_SIZE)
    )
end

-- spawn enemies at random positions inside the level. fills self.entities with content
-- player: input. reference to the player that is needed for the Entity objects
function GameLevel:spawnEnemiesRand(player)
    for x = 1, self.grid_width do
        -- get all levels of solid ground for this column
        local height_levels = self:getHeightLevels(x)
        -- the height level number at which the entity should spawn
        local height_level_nr = 0
        for _, height_level in pairs(height_levels) do
            height_level_nr = height_level_nr + 1
            -- spawn an enemy with a chance of enemy_p (if not chasm or start or end of the level)
            if x > 3 and x < self.grid_width - 1 and height_level > 0 and math.random() < self.entity_p then
                -- don't spawn an enemy below a platform that is too near the ground
                local do_spawn = true
                local height_levels_scan = nil
                for x_entity = x - 1, x + 1 do
                    height_levels_scan = self:getHeightLevels(x_entity)
                    if height_levels_scan[height_level_nr + 1] and height_levels_scan[height_level_nr + 1] - height_level <= 3 then
                        do_spawn = false
                        break
                    end
                end
                if not do_spawn then
                    goto continue_h_lvl
                end

                -- don't spawn an enemy too close to a ledge that is too high, to not block the player from progressing.
                -- within a scan range, get the smallest ground height difference between the scanned ground and the ground that the entity is standing on.
                -- higher ground gives a negative ground height difference. Only lower ground with a ledge that is too high can cause the entity to not spawn.
                -- do the process for the ground left and right of the Entity. If no small enough ground height difference is found the entity can't spawn.
                local ground_h_scan_range = 4           -- the number of Tiles scanned left and right of the Entity
                -- the number of Tiles left or right of the Entity that are left out from scanning (but only if the ground height is the same)
                -- the entity should not spawn if there is the same ground height right next to it, because it could still be too close to a ledge.
                -- But if the ground height is different (and not too high) that means that the player can use this ground without getting hit by the entity.
                local ground_h_scan_range_start = 1
                -- minimal ground height difference left and right (initialize with a high value)
                local ground_h_min_diff_left = self.grid_height
                local ground_h_min_diff_right = self.grid_height
                local height_level_cur_scan = 0     -- currently scanned height level. is either the height level on which the entity is or lower

                -- scan left from the entity
                for x_entity = x - ground_h_scan_range, x - 1 do
                    height_levels_scan = self:getHeightLevels(x_entity)
                    height_level_cur_scan = height_levels_scan[math.min(height_level_nr, #height_levels_scan)]

                    if x_entity < x - ground_h_scan_range_start or height_level_cur_scan ~= height_level then
                        ground_h_min_diff_left = math.min(ground_h_min_diff_left, height_level - height_level_cur_scan)
                    end
                end
                if ground_h_min_diff_left >= self.ledge_height_max then
                    goto continue_h_lvl
                end
                -- scan right from the entity
                for x_entity = x + 1, x + ground_h_scan_range do
                    height_levels_scan = self:getHeightLevels(x_entity)
                    height_level_cur_scan = height_levels_scan[math.min(height_level_nr, #height_levels_scan)]

                    if x_entity > x + ground_h_scan_range_start or height_level_cur_scan ~= height_level then
                        ground_h_min_diff_right = math.min(ground_h_min_diff_right, height_level - height_level_cur_scan)
                    end
                end
                if ground_h_min_diff_right >= self.ledge_height_max then
                    goto continue_h_lvl
                end

                -- the height at which the entity is placed is one above the ground height
                local y = self.grid_height - height_level
                -- instantiate an Entity (there is only a Snail enemy in this game)
                table.insert(self.entities, Snail((x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, self, player))
            end
            ::continue_h_lvl::
        end
    end
end

-- get the height levels in tiles of the level according to the self.tiles table
-- x_grid: input. Column of the level that the height shall be calculated for
-- return: height_levels table. a new height entry gets added to the table for every tile that one can stand on.
-- if a column has a platform, it has 2 height levels. the height is measured from bottom to top (reverse y-axis direction)
-- the first element of the returned table will be 0 if the column is a chasm, even if there is a platform above
-- Game objects are not considered for the height levels, only tiles
function GameLevel:getHeightLevels(x_grid)
    local height_levels = {}
    local is_empty = true       -- if current tile position is empty

    for y_grid = self.grid_height, 1, -1 do
        -- first look for a present tile. if found, the next tile that is empty marks a new height level
        if is_empty and (self.tiles[y_grid][x_grid] and self.tiles[y_grid][x_grid].is_solid) then
            is_empty = false
        elseif not is_empty and (not self.tiles[y_grid][x_grid] or not self.tiles[y_grid][x_grid].is_solid) then
            is_empty = true
            table.insert(height_levels, self.grid_height - y_grid)
        end
        -- if a chasm, insert height level 0
        if y_grid == self.grid_height and is_empty then
            table.insert(height_levels, 0)
        end
    end

    return height_levels
end

-- get all objects/ tiles that are at certain coordinates
-- x, y: input pixel coordinates to check
-- return: table of objects and tiles that were found
function GameLevel:getObjects(x, y)
    local objects = {}
    -- convert x, y to grid coordinates to find the tile at that position (if existing)
    local x_grid, y_grid = math.floor(x / TILE_SIZE) + 1, math.floor(y / TILE_SIZE) + 1
    if self.tiles[y_grid] and self.tiles[y_grid][x_grid] then
        table.insert(objects, self.tiles[y_grid][x_grid])
    end
    -- check if a game object contains the x, y point
    for _, object in pairs(self.objects) do
        if object and object:containsSlightly({x = x, y = y}) then
            table.insert(objects, object)
        end
    end

    return objects
end

-- check if a table contains a solid object or tile
function containsSolidObject(objects)
    for _, obj in pairs(objects) do
        if obj.is_solid then
            return true
        end
    end
    return false
end

-- update entities and game objects.
-- entities and game objects might use Timers (from knife library). They are updated outside of this function
-- cam_x: input. x coordinate of the player camera. Used to not update objects/ entities that are too far away from the current screen.
function GameLevel:update(dt, cam_x)
    -- only update objects/ entities that are at maximum 3 tile sizes off screen
    local off_camera_update_offset = 3 * TILE_SIZE
    -- update objects before the entities, so the entities can react to a change in the same frame
    for _, object in pairs(self.objects) do
        if object.x + object.width >= cam_x - off_camera_update_offset and object.x <= cam_x + VIRTUAL_WIDTH + off_camera_update_offset then
            object:update(dt)
        end
    end
    -- execute all update stages of entities (see Entity class)
    for _, entity in pairs(self.entities) do
        if entity.x + entity.width >= cam_x - off_camera_update_offset and entity.x <= cam_x + VIRTUAL_WIDTH + off_camera_update_offset then
            entity:updateStage1(dt)
        end
    end
    for _, entity in pairs(self.entities) do
        if entity.x + entity.width >= cam_x - off_camera_update_offset and entity.x <= cam_x + VIRTUAL_WIDTH + off_camera_update_offset then
            entity:updateStage2(dt)
        end
    end
    for _, entity in pairs(self.entities) do
        if entity.x + entity.width >= cam_x - off_camera_update_offset and entity.x <= cam_x + VIRTUAL_WIDTH + off_camera_update_offset then
            entity:updateStage3(dt)
        end
    end

    -- remove entities and objects that have their is_remove member set.
    -- iterate backwards to not skip the element that comes after a removed element (when removing, all elements after the removed one decrement their index)
    for i = #self.objects, 1, -1 do
        if self.objects[i].is_remove then
            table.remove(self.objects, i)
        end
    end
    for i = #self.entities, 1, -1 do
        if self.entities[i].is_remove then
            table.remove(self.entities, i)
        end
    end
end

function GameLevel:renderBackground(x)
    -- number of extended background textures that are needed to fill the screen vertically. Each for top and bottom.
    local num_bg_extended = math.ceil((VIRTUAL_HEIGHT / 2 - BACKGROUND_HEIGHT / 2) / BACKGROUND_HEIGHT)
    -- at minimum the VIRTUAL_WIDTH plus 1 BACKGROUND_WIDTH has to be filled with a background texture
    for i = 1, math.ceil(VIRTUAL_WIDTH / BACKGROUND_WIDTH) + 1 do
        -- draw extended background textures on the top and bottom of the screen
        for j = num_bg_extended, 1, -1 do
            love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][EXTENDED_BACKGROUND_FRAME_IDS[self.background]['top']],
                math.floor(x + BACKGROUND_WIDTH * (i - 1)), VIRTUAL_HEIGHT / 2 - BACKGROUND_HEIGHT / 2 - BACKGROUND_HEIGHT * j)
        end
        for j = 1, num_bg_extended do
            love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][EXTENDED_BACKGROUND_FRAME_IDS[self.background]['bottom']],
                math.floor(x + BACKGROUND_WIDTH * (i - 1)), VIRTUAL_HEIGHT / 2 + BACKGROUND_HEIGHT / 2 + BACKGROUND_HEIGHT * (j - 1))
        end

        -- draw main backgound texture in the y center of the screen
        love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background],
            math.floor(x + BACKGROUND_WIDTH * (i - 1)), VIRTUAL_HEIGHT / 2 - BACKGROUND_HEIGHT / 2)
    end
end

-- render tiles, objects and entities in this order so entities are always displayed in front of objects.
-- cam_x: input. x coordinate of the player camera. Used to not render objects/ entities that are too far away from the current screen.
function GameLevel:render(cam_x)
    -- only render objects/ entities that are on the screen. The offset specifies how much things off the screen are still rendered (in pixels)
    local off_camera_render_offset = 0

    for x = 1, self.grid_width do
        for y = 1, self.grid_height do
            local tile = self.tiles[y][x]
            if tile and tile.x + tile.width >= cam_x - off_camera_render_offset and tile.x <= cam_x + VIRTUAL_WIDTH + off_camera_render_offset then
                tile:render()
            end
        end
    end

    for _, object in pairs(self.objects) do
        if object.x + object.width >= cam_x - off_camera_render_offset and object.x <= cam_x + VIRTUAL_WIDTH + off_camera_render_offset then
            object:render()
        end
    end

    for _, entity in pairs(self.entities) do
        if entity.x + entity.width >= cam_x - off_camera_render_offset and entity.x <= cam_x + VIRTUAL_WIDTH + off_camera_render_offset then
            entity:render()
        end
    end
end
