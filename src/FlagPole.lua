--[[
    GD50
    -- Super Mario Bros. Remake --

    FlagPole is the goal of the level. When the Player reaches it, the level is finished.
]]

FLAG_POLE_WIDTH = TILE_SIZE
FLAG_POLE_HEIGHT = 3 * TILE_SIZE

FlagPole = Class{__includes = GameObject}

function FlagPole:init(x, y)
    -- init parent
    GameObject.init(self, {
        x = x, y = y,
        width = FLAG_POLE_WIDTH, height = FLAG_POLE_HEIGHT,
        texture = 'flag-poles', frame_id = FLAG_POLE_RED_FRAME_ID,
        is_collidable = true, is_solid = false
    })
end

-- overrides GameObject:doCollideWithEntity()
function FlagPole:doCollideWithEntity(collision_data)
    if collision_data.entity.id == ENTITY_ID_PLAYER then
        collision_data.entity.finished_level = true
    end
end
