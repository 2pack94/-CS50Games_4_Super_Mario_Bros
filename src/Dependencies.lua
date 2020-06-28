--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    -- Dependencies --

    A file to organize all of the global dependencies for our project, as
    well as the assets for our game, rather than pollute our main.lua file.
]]

-- libraries
Class = require 'lib/class'
push = require 'lib/push'
Timer = require 'lib/knife.timer'
require 'lib/Rect'
require 'lib/StateMachine'
require 'lib/TableUtil'

-- utility
require 'src/constants'
require 'src/Util'

-- game states
require 'src/states/BaseState'
require 'src/states/game/PlayState'
require 'src/states/game/StartState'

-- entity states
require 'src/states/entity/player/PlayerFallingState'
require 'src/states/entity/player/PlayerIdleState'
require 'src/states/entity/player/PlayerJumpState'
require 'src/states/entity/player/PlayerWalkingState'
require 'src/states/entity/player/PlayerDeathState'

require 'src/states/entity/snail/SnailChasingState'
require 'src/states/entity/snail/SnailIdleState'
require 'src/states/entity/snail/SnailMovingState'

-- general
require 'src/Animation'
require 'src/Entity'
require 'src/GameObject'
require 'src/JumpBlock'
require 'src/FlagPole'
require 'src/GameLevel'
require 'src/Player'
require 'src/Snail'
require 'src/Tile'


gSounds = {
    ['jump1'] = love.audio.newSource('sounds/jump1.wav', 'static'),
    ['jump2'] = love.audio.newSource('sounds/jump2.wav', 'static'),
    ['coin1'] = love.audio.newSource('sounds/coin1.wav', 'static'),
    ['coin2'] = love.audio.newSource('sounds/coin2.wav', 'static'),
    ['coin3'] = love.audio.newSource('sounds/coin3.wav', 'static'),
    ['back'] = love.audio.newSource('sounds/back.wav', 'static'),
    ['confirm'] = love.audio.newSource('sounds/confirm.wav', 'static'),
    ['empty-block'] = love.audio.newSource('sounds/empty-block.wav', 'static'),
    ['wall-hit'] = love.audio.newSource('sounds/wall-hit.wav', 'static'),
    ['death'] = love.audio.newSource('sounds/death.wav', 'static'),
    ['game-over'] = love.audio.newSource('sounds/game-over.wav', 'static'),     -- from: https://freesound.org/people/Euphrosyyn/sounds/442127/
    ['kill'] = love.audio.newSource('sounds/kill.wav', 'static'),
    ['music'] = love.audio.newSource('sounds/music.mp3', 'static')      -- from: https://www.dl-sounds.com/royalty-free/superboy/
}

gTextures = {
    ['tiles'] = love.graphics.newImage('graphics/tiles.png'),
    ['toppers'] = love.graphics.newImage('graphics/tile_tops.png'),
    ['plants'] = love.graphics.newImage('graphics/plants.png'),
    ['jump-blocks'] = love.graphics.newImage('graphics/jump_blocks.png'),
    ['flag-poles'] = love.graphics.newImage('graphics/flags.png'),
    ['coins'] = love.graphics.newImage('graphics/coins.png'),
    ['backgrounds'] = love.graphics.newImage('graphics/backgrounds.png'),
    ['pink_alien'] = love.graphics.newImage('graphics/pink_alien.png'),
    ['creatures'] = love.graphics.newImage('graphics/creatures.png')
}

gFrames = {
    ['tiles'] = GenerateQuads(gTextures['tiles'], TILE_SIZE, TILE_SIZE),
    ['toppers'] = GenerateQuads(gTextures['toppers'], TILE_SIZE, TILE_SIZE),
    ['plants'] = GenerateQuads(gTextures['plants'], TILE_SIZE, TILE_SIZE),
    ['jump-blocks'] = GenerateQuads(gTextures['jump-blocks'], TILE_SIZE, TILE_SIZE),
    ['flag-poles'] = GenerateQuads(gTextures['flag-poles'], FLAG_POLE_WIDTH, FLAG_POLE_HEIGHT),
    ['coins'] = GenerateQuads(gTextures['coins'], TILE_SIZE, TILE_SIZE),
    ['backgrounds'] = GenerateQuads(gTextures['backgrounds'], BACKGROUND_WIDTH, BACKGROUND_HEIGHT),
    ['pink_alien'] = GenerateQuads(gTextures['pink_alien'], PLAYER_WIDTH, PLAYER_HEIGHT),
    ['creatures'] = GenerateQuads(gTextures['creatures'], CREATURE_SIZE, CREATURE_SIZE)
}

-- these need to be added after gFrames is initialized because they refer to gFrames itself
gFrames['tilesets'] = GenerateTileSets(gFrames['tiles'],
    NUM_TILE_SETS_HOR, NUM_TILE_SETS_VERT, TILE_SET_NUM_TILES_HOR, TILE_SET_NUM_TILES_VERT)

gFrames['toppersets'] = GenerateTileSets(gFrames['toppers'],
    NUM_TOPPER_SETS_HOR, NUM_TOPPER_SETS_VERT, TOPPER_SET_NUM_TOPPERS_HOR, TOPPER_SET_NUM_TOPPERS_VERT)

gFonts = {
    ['small'] = love.graphics.newFont('fonts/font.ttf', 8),
    ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
    ['large'] = love.graphics.newFont('fonts/font.ttf', 32),
    ['title'] = love.graphics.newFont('fonts/ArcadeAlternate.ttf', 32)
}
