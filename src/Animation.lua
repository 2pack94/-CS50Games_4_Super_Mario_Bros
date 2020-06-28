--[[
    GD50
    Super Mario Bros. Remake

    -- Animation Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Animation Helper Class. Switches between the textures (frames) according to the update interval to create an Animation Effect.
]]

Animation = Class{}

function Animation:init(frames, interval)
    self.frames = frames or {1}         -- table of frame ID's
    self.interval = interval or 1       -- frame changing period in seconds
    self.timer = 0                      -- to count the display time of the current frame
    self.current_frame = 1              -- index into self.frames to get the current active frame
end

-- increment the timer and update self.current_frame if the timer has reached the update interval
function Animation:update(dt)
    -- no need to update if animation is only one frame
    if #self.frames > 1 then
        self.timer = self.timer + dt

        if self.timer > self.interval then
            self.timer = self.timer % self.interval

            self.current_frame = (self.current_frame % #self.frames) + 1
        end
    end
end

-- return the current frame ID. Can be used in the love.graphics.draw() function
function Animation:getCurrentFrame()
    return self.frames[self.current_frame]
end
