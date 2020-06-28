--[[
    GD50
    Super Mario Bros. Remake

    -- constants --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    global constants
]]

-- starting window size
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- resolution to emulate with push
VIRTUAL_WIDTH = 384
VIRTUAL_HEIGHT = 216

GAME_TITLE = 'Super Alien Bros.'

-- global tile size
-- the game world consists out of a grid of regular-shaped images called tiles.
-- the tile size for this game is 16 x 16. Most of the game objects are exactly this size.
TILE_SIZE = 16

-- size of the background textures
BACKGROUND_WIDTH = 256      -- the background is periodic to BACKGROUND_WIDTH
BACKGROUND_HEIGHT = 128

-- number of tilesets in the tile-spritesheet horizontally and vertically
NUM_TILE_SETS_HOR = 6
NUM_TILE_SETS_VERT = 10
-- number of tiles in each tileset horizontally and vertically
TILE_SET_NUM_TILES_HOR = 5
TILE_SET_NUM_TILES_VERT = 4

-- number of topper sets in the topper-spritesheet horizontally and vertically
NUM_TOPPER_SETS_HOR = 6
NUM_TOPPER_SETS_VERT = 18
-- number of toppers in each topperset horizontally and vertically
TOPPER_SET_NUM_TOPPERS_HOR = 5
TOPPER_SET_NUM_TOPPERS_VERT = 4

-- gravity in pixel per second per second. Entities are influenced by Gravity
GRAVITY = 370
-- limit the fall speed. Necessary to not break collision detection. It's important that Entities do not sink too much into the ground in the update time of 1 Frame.
-- Other than falling, entities cannot gain high speed, so no other speed component needs to be limited.
MAX_Y_VELOCITY = 350

-- all creatures are tile sized
CREATURE_SIZE = TILE_SIZE

-- points that the player gets when killing an enemy by jumping on it
POINTS_PER_ENEMY = 50

-- entity ID's. Used to differentiate Entities
ENTITY_ID_PLAYER = 1
ENTITY_ID_SNAIL = 2

-- frame ID's. They are used as an index in a corresponding gFrames table to get the desired quad

-- tile frame ID's. Used to determine the tile type. To obtain the texture/ quad for this ID, a tileset table inside the tilesets table is indexed
TILE_FRAME_ID_FULL = 3
TILE_FRAME_ID_ROUNDED_BOTTOM = 1
TILE_FRAME_ID_ROUNDED_LEFT_BOTTOM = 2
TILE_FRAME_ID_ROUNDED_RIGHT_BOTTOM = 4
-- topper frame ID's
TOPPER_FRAME_ID_FLAT = 3

-- table of tile frame ID's that contains the types of tiles that can be collided with
COLLIDABLE_TILES = {
    TILE_FRAME_ID_FULL, TILE_FRAME_ID_ROUNDED_BOTTOM, TILE_FRAME_ID_ROUNDED_LEFT_BOTTOM, TILE_FRAME_ID_ROUNDED_RIGHT_BOTTOM
}

-- instead of generating a level by choosing tile- and toppersets randomly, specify fitting sets in these lists.
-- the lists contain frame ID's of a set (or background).
-- the frame ID's in these tables at the same index belong together. Only a subset of all sets are represented by the ID's, because there are a lot of sets in the spritesheets.
TILESET_FRAME_IDS    = {1, 2, 7,  8,  13, 14, 19, 20, 25, 26, 3, 4, 9, 10, 15, 16, 21, 22, 27, 28, 33, 34, 39, 40, 45, 46, 51, 52, 57, 58}
TOPPERSET_FRAME_IDS  = {5, 6, 11, 12, 17, 18, 23, 24, 29, 30, 1, 2, 7, 8,  13, 14, 19, 20, 25, 26, 3,  4,  9,  10, 15, 16, 21, 22, 27, 28}
BACKGROUND_FRAME_IDS = {1, 1, 1,  1,  1,  1,  1,  1,  1,  1,  3, 3, 3, 3,  3,  3,  3,  3,  3,  3,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2}
-- background frame ID 1: for desert levels
-- background frame ID 2: for grass levels
-- background frame ID 3: for underground levels
-- the background texture does not cover the whole VIRTUAL_HEIGHT. To fill the screen, there are textures needed that are drawn above and below the main background texture.
-- the background frame ID can be used as an index to this table to find the frame ID's of the fitting top/ bottom support textures.
EXTENDED_BACKGROUND_FRAME_IDS = {{top = 4, bottom = 5}, {top = 6, bottom = 7}, {top = 3, bottom = 3}}

-- game object frame ID's

-- the flag pole is the level goal
FLAG_POLE_RED_FRAME_ID = 5

-- plants for decoration
PLANT_FRAME_IDS = {
    -- for desert levels
    {7, 8, 9},
    -- for grass levels
    {1, 2, 5, 6},
    -- for underground levels
    {5, 33, 34}
}

-- jump blocks. they can contain a coin and also can move
JUMP_BLOCK_FRAME_ID_FILLED = 9       -- contains a coin
JUMP_BLOCK_FRAME_ID_EMPTY = 14       -- contains nothing

-- coins are inside jump blocks and spawn when a jump block is hit from below
COIN_FRAME_IDS = {
    1, 2, 3
}
COIN_SCORE_POINTS = {50, 100, 200}

-- entity frame ID's. used in the Animation Class. The Animation Class returns the current frame according to its animation parameters.

-- player
PLAYER_FRAME_ID_IDLE = {1}
PLAYER_FRAME_IDS_WALKING = {10, 11}
PLAYER_FRAME_ID_JUMPING = {3}
PLAYER_FRAME_ID_DEATH = {5}

-- snail
SNAIL_FRAME_IDS_MOVING = {7, 8}
SNAIL_FRAME_ID_IDLE = {6}
