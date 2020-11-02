--[[
    GD50
    -- Super Mario Bros. Remake --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Game objects are non living things that are not tiles.
    All game objects are inside the objects table in GameLevel.
    Base Class for all objects.
]]

GameObject = Class{__includes = Rect}

function GameObject:init(def)
    -- position
    self.x = def.x or 0
    self.y = def.y or 0
    -- dimensions
    self.width = def.width or TILE_SIZE
    self.height = def.height or TILE_SIZE
    -- velocity
    self.dx = 0
    self.dy = 0
    -- key string of the gFrames table. Specifies the Spritesheet
    self.texture = def.texture
    -- specifies the type and texture. index in the gFrames table to pick a quad/ texture from the spritesheet
    self.frame_id = def.frame_id or 1
    -- if false, no collisions will be calculated with that object.
    self.is_collidable = def.is_collidable or false
    -- If solid, Entities get rebounded on this object in the collision detection function
    self.is_solid = def.is_solid or false
    -- specify this for objects that need a level reference
    self.level = def.level or nil
    -- if true, the object will get removed from the table in GameLevel
    self.is_remove = false
end

-- function prototypes. If needed, override within child class
--[[
    gets called in Entity:checkObjectCollisions() when an Entity collided with the object.
    collision_data: input. Entity data before any object collisions.
        contains members: entity: reference to the colliding Entity, hitbox: entity hitbox before any object collisions,
        dx, dy: entity velocity before any object collisions
]]
function GameObject:doCollideWithEntity(collision_data) end
-- used to set the velocity of the object to 0 and also stop tween Timers that cause movement
function GameObject:stopMovement() end

function GameObject:update(dt) end

function GameObject:render()
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.frame_id], math.floor(self.x), math.floor(self.y))

    if IS_DEBUG then
        if self.highlight_is_col then
            love.graphics.setColor(255/255, 0/255, 0/255, 120/255)
            love.graphics.rectangle("fill", math.floor(self.x), math.floor(self.y), self.width, self.height)
            love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
        end
        self.highlight_is_col = false
    end
end
