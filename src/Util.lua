--[[
    GD50
    Super Mario Bros. Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Helper functions.
]]

--[[
    atlas: spritesheet.
    tilewidth, tileheight: width and height for the tiles in the spritesheet
    The returned 1 dimensional spritesheet table indexes the quads from left to right and top to bottom (starting index: 1)
]]
function GenerateQuads(atlas, tilewidth, tileheight)
    local sheet_width = atlas:getWidth() / tilewidth
    local sheet_height = atlas:getHeight() / tileheight

    local sheet_counter = 1
    local spritesheet = {}

    for y = 0, sheet_height - 1 do
        for x = 0, sheet_width - 1 do
            spritesheet[sheet_counter] =
                love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth, tileheight, atlas:getDimensions())
            sheet_counter = sheet_counter + 1
        end
    end

    return spritesheet
end

--[[
    quads: input. 1 dimensional table returned from GenerateQuads() containing tiles
    num_tile_sets_x, num_tile_sets_y: number of tile sets in the tile-spritesheet horizontally and vertically
    num_tiles_x, num_tiles_y: number of tiles in each tileset horizontally and vertically
    return a tilesets table (2 dimensional) which is just another representation of the input quads table.
    Every tileset is a sub-table of the tilesets table.
    The tileset subtables represent the tilesets in the spritesheet from left to right and top to bottom.
]]
function GenerateTileSets(quads, num_tile_sets_x, num_tile_sets_y, num_tiles_x, num_tiles_y)
    local tilesets = {}
    local table_counter = 0     -- counts the number of tables in the tilesets table (number of tilesets)
    local sheet_width = num_tile_sets_x * num_tiles_x   -- number of tiles in the tile-spritesheet horizontally

    -- itereate over all tilesets
    for tileset_y = 1, num_tile_sets_y do
        for tileset_x = 1, num_tile_sets_x do
            -- insert a table for a tileset
            table.insert(tilesets, {})
            table_counter = table_counter + 1
            -- iterate over the tiles in a tileset
            for tile_y = num_tiles_y * (tileset_y - 1) + 1, num_tiles_y * (tileset_y - 1) + 1 + num_tiles_y do
                for tile_x = num_tiles_x * (tileset_x - 1) + 1, num_tiles_x * (tileset_x - 1) + 1 + num_tiles_x do
                    -- insert a tile in the tileset sub-table
                    -- translate the 2 dimensional x, y tile coordinates on the tile-spritesheet to an index in the 1 dimensional quads table
                    table.insert(tilesets[table_counter], quads[sheet_width * (tile_y - 1) + tile_x])
                end
            end
        end
    end

    return tilesets
end

--[[
    modified Bubble Sort (reverse)
    the elements in target_tbl are sorted according to the values in helper_tbl
    the element in target_tbl with the smallest corresponding value in helper_tbl will be the last and vice versa
    return: reverse sorted target_tbl, helper_tbl
]]
function reverseSortWithHelperTbl(target_tbl, helper_tbl)
    for i = 1, #target_tbl do
        local swaps = 0
        for j = 1, #target_tbl - i do
            if helper_tbl[j] < helper_tbl[j + 1] then
                swaps = swaps + 1

                local tmp = helper_tbl[j]
                helper_tbl[j] = helper_tbl[j + 1]
                helper_tbl[j + 1] = tmp

                tmp = target_tbl[j]
                target_tbl[j] = target_tbl[j + 1]
                target_tbl[j + 1] = tmp
            end
        end
        if swaps == 0 then
            break
        end
    end

    return target_tbl, helper_tbl
end

--[[
    This method extends the Rect class. The function works like Rect:getIntersectingEdge(), but adds the functionality to work with hitboxes.
    A hitbox is a Rect object and can have the additional members shift_left, shift_right, shift_up or shift_down. Only 1 of them can be true.
    A "shift" member that is true indicates that the hitbox should get shifted in the corresponding direction during the rebound when its colliding.
    This also means that the edge that is intersecting with another hitbox is depends on these "shift" members. A hitbox shifted up, was hit on its bottom edge etc..
    There is also a logic that resolves cases where 2 hitboxes have non-fitting "shift" members set to true.
    return: table that contains boolean values that specify which edge is overlapping in this order: left, right, top, bottom
]]
function Rect:getIntersectingEdgeHitbox(hitbox)
    local intersects_lrtb = {false, false, false, false}
    if not self:intersects(hitbox) then
        return intersects_lrtb
    end

    -- if shift members on both hitboxes are set
    if
        (self.shift_left or self.shift_right or self.shift_up or self.shift_down) and
        (hitbox.shift_left or hitbox.shift_right or hitbox.shift_up or hitbox.shift_down)
    then
        -- calculate the necessary shift amount if either the shift member of self or the shift member of the input parameter "hitbox" would be prioritized.
        -- calculate new position minus previous position.
        local shift_amount_self = 0
        local shift_amount_other = 0
        if self.shift_left then
            shift_amount_self = math.abs((hitbox.x - self.width) - self.x)
        elseif self.shift_right then
            shift_amount_self = math.abs((hitbox.x + hitbox.width) - self.x)
        elseif self.shift_up then
            shift_amount_self = math.abs((hitbox.y - self.height) - self.y)
        elseif self.shift_down then
            shift_amount_self = math.abs((hitbox.y + hitbox.height) - self.y)
        end

        if hitbox.shift_left then
            shift_amount_other = math.abs((self.x - hitbox.width) - hitbox.x)
        elseif hitbox.shift_right then
            shift_amount_other = math.abs((self.x + self.width) - hitbox.x)
        elseif hitbox.shift_up then
            shift_amount_other = math.abs((self.y - hitbox.height) - hitbox.y)
        elseif hitbox.shift_down then
            shift_amount_other = math.abs((self.y + self.height) - hitbox.y)
        end

        -- if the shift amount of self is lower the shift member of self takes precedence
        if shift_amount_self < shift_amount_other then
            if self.shift_left then
                intersects_lrtb[2] = true
            elseif self.shift_right then
                intersects_lrtb[1] = true
            elseif self.shift_up then
                intersects_lrtb[4] = true
            elseif self.shift_down then
                intersects_lrtb[3] = true
            end
        -- if the shift amount of self is higher the shift member of hitbox takes precedence
        else
            if hitbox.shift_left then
                intersects_lrtb[1] = true
            elseif hitbox.shift_right then
                intersects_lrtb[2] = true
            elseif hitbox.shift_up then
                intersects_lrtb[3] = true
            elseif hitbox.shift_down then
                intersects_lrtb[4] = true
            end
        end
    -- only a shift member of self is set
    elseif self.shift_left or self.shift_right or self.shift_up or self.shift_down then
        if self.shift_left then
            intersects_lrtb[2] = true
        elseif self.shift_right then
            intersects_lrtb[1] = true
        elseif self.shift_up then
            intersects_lrtb[4] = true
        elseif self.shift_down then
            intersects_lrtb[3] = true
        end
    -- only a shift member of hitbox is set
    elseif hitbox.shift_left or hitbox.shift_right or hitbox.shift_up or hitbox.shift_down then
        if hitbox.shift_left then
            intersects_lrtb[1] = true
        elseif hitbox.shift_right then
            intersects_lrtb[2] = true
        elseif hitbox.shift_up then
            intersects_lrtb[3] = true
        elseif hitbox.shift_down then
            intersects_lrtb[4] = true
        end
    -- if no shift member is set, calculate the Intersecting edge normally
    else
        intersects_lrtb = self:getIntersectingEdge(hitbox)
    end

    return intersects_lrtb
end
