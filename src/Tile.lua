--[[
    GD50
    -- Super Mario Bros. Remake --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    This can be either an empty tile or a ground tile.
    Only ground tiles are solid. Ground tiles can have toppers.
    The level ground and platforms are built from Tile objects.
    All Tile objects are inside the Tile table in GameLevel.
]]

Tile = Class{__includes = Rect}

function Tile:init(grid_x, grid_y, frame_id, topper_frame_id, tileset, topperset)
    -- grid coordinates inside the level. represent the index at which the tile is at in the tiles table of the level.
    -- grid coordinates start with 1
    self.grid_x = grid_x
    self.grid_y = grid_y

    self.width = TILE_SIZE
    self.height = TILE_SIZE
    -- pixel coordinates converted from grid coordinates
    self.x = (self.grid_x - 1) * TILE_SIZE
    self.y = (self.grid_y - 1) * TILE_SIZE

    -- always 0. members needed for collision detection
    self.dx, self.dy = 0, 0

    -- index in the tilesets table that picks the subtable for a specific tileset. used in the draw function.
    self.tileset = tileset
    -- specifies the type and texture of the tile. can be nil for an empty tile. index in the tileset subtable to pick a tile from the tileset
    self.frame_id = frame_id
    -- index in the toppersets table that picks the subtable for a specific topperset. used in the draw function.
    self.topperset = topperset
    -- specifies the type and texture of the topper. can be nil for an empty topper (no topper). index in the topperset subtable to pick a topper from the topperset
    self.topper_frame_id = topper_frame_id

    -- Check if this frame ID is whitelisted as collidable in the global COLLIDABLE_TILES table.
    -- if false, no collisions will be calculated with that tile
    self.is_collidable = table.contains(COLLIDABLE_TILES, self.frame_id)
    -- If solid, Entities get rebounded on this Tile in the collision detection function
    self.is_solid = self.is_collidable
end

--[[
    gets called in Entity:checkObjectCollisions() when an Entity collided with the Tile.
    collision_data: input. Entity data before any object collisions.
        contains members: entity: reference to the colliding Entity, hitbox: entity hitbox before any object collisions,
        dx, dy: entity velocity before any object collisions
]]
function Tile:doCollideWithEntity(collision_data)
    -- if the Player jumped into the bottom of the Tile, play a sound
    if self.is_solid and collision_data.entity.id == ENTITY_ID_PLAYER and collision_data.dy < 0 and self:getIntersectingEdgeHitbox(collision_data.hitbox)[4] then
        gSounds['wall-hit']:play()
    end
end

function Tile:render()
    -- draw the Tile
    if self.frame_id then
        love.graphics.draw(gTextures['tiles'], gFrames['tilesets'][self.tileset][self.frame_id], self.x, self.y)
    end
    -- draw a topper on the tile. only a Tile at the top should have a topper
    if self.topper_frame_id then
        love.graphics.draw(gTextures['toppers'], gFrames['toppersets'][self.topperset][self.topper_frame_id], self.x, self.y)
    end

    if IS_DEBUG then
        if self.highlight_is_col then
            love.graphics.setColor(255/255, 0/255, 0/255, 120/255)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
        elseif self.highlight_check_col then
            love.graphics.setColor(255/255, 255/255, 255/255, 120/255)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
        end
        self.highlight_check_col = false
        self.highlight_is_col = false
    end
end
