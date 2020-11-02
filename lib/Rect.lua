--[[
    Author: Richard Tuppack
    Date: 14.06.2020
    2D axis aligned rectangle
]]

Rect = Class{}

--[[
    Construct the rectangle from its coordinates
    default values are 0 for every Parameter
]]
function Rect:init(x, y, width, height)
    self.x = x or 0             -- Left coordinate of the rectangle
    self.y = y or 0             -- Top coordinate of the rectangle
    self.width = width or 0     -- Width of the rectangle
    self.height = height or 0   -- Height of the rectangle
end

--[[
    Check the intersection between two rectangles
    rectangle: input. Rect object. Rectangle to check
    return:
        true if rectangles overlap, false otherwise.
        If the coordinates of the overlapping edges are exactly the same, return false (because in this case the displacement values would also be 0).
]]
function Rect:intersects(rectangle)
    -- check if the left edge of *self is farther to the right than the right edge of rectangle
    -- or if the right edge of *self is farther to the left than the left edge of rectangle
    -- check if the top edge of *self is lower than the bottom edge of rectangle
    -- or if the bottom edge of *self is higher than the top edge of rectangle
    if
        self.x >= rectangle.x + rectangle.width or self.x + self.width <= rectangle.x or
        self.y >= rectangle.y + rectangle.height or self.y + self.height <= rectangle.y
    then
        return false
    end

    return true
end

--[[
    Same as intersects(), but return true also if the overlapping edges are on top of each other
    After rebound(), rectangles still intersect "slightly"
    rectangle: input. Rect object. Rectangle to check
    return:
        true if rectangles overlap, false otherwise.
        true if the coordinates of the overlapping edges are exactly the same.
        false if the rectangles are exactly diagonal to each other (if just two corner points overlap)
]]
function Rect:intersectsSlightly(rectangle)
    if
        self.x > rectangle.x + rectangle.width or self.x + self.width < rectangle.x or
        self.y > rectangle.y + rectangle.height or self.y + self.height < rectangle.y or
        (self.x == rectangle.x + rectangle.width and (self.y == rectangle.y + rectangle.height or self.y + self.height == rectangle.y)) or
        (self.x + self.width == rectangle.x and (self.y == rectangle.y + rectangle.height or self.y + self.height == rectangle.y))
    then
        return false
    end

    return true
end

--[[
    check if a point is inside *self
    point: input. Point object with members x and y
    return:
        true if the point is inside *self, false otherwise.
        If the point is exactly on an edge of *self, return false.
]]
function Rect:contains(point)
    -- check if the point is left or right of *self
    -- check if the point is above or below of *self
    if
        self.x >= point.x or self.x + self.width <= point.x or
        self.y >= point.y or self.y + self.height <= point.y
    then
        return false
    end

    return true
end

--[[
    Same as contains(), but return true also if the point is exactly on an edge of *self
    point: input. Point object with members x and y
    return:
        true if the point is inside *self, or exactly on an edge of *self (even when its on a corner point)
        return false otherwise.
]]
function Rect:containsSlightly(point)
    -- check if the point is left or right of *self
    -- check if the point is above or below of *self
    if
        self.x > point.x or self.x + self.width < point.x or
        self.y > point.y or self.y + self.height < point.y
    then
        return false
    end

    return true
end

--[[
    Check the intersection between two rectangles and return the x, y displacement values
    see: https://github.com/noooway/love2d_arkanoid_tutorial/wiki/Resolving-Collisions
    The displacement is the shift in the position (x, y) of *self necessary to resolve the overlap
    If the center of *self is left to the center of rectangle a negative x displacement is returned, else positive
    If the center of *self is above the center of rectangle a negative y displacement is returned, else positive
    rectangle: input. Rect object. Rectangle to check
    return: 3 values
        1. is_overlap: true if rectangles overlap, false otherwise
        2. shift_x: x displacement for *self
        3. shift_y: y displacement for *self
]]
function Rect:getDisplacement(rectangle)
    local is_overlap = self:intersects(rectangle)
    local shift_x, shift_y = 0, 0
    if is_overlap then
        -- if center of *self is left to the center of rectangle
        if ( self.x + self.width / 2 ) < ( rectangle.x + rectangle.width / 2 ) then
            shift_x = rectangle.x - ( self.x + self.width )         -- distance from left edge rectangle to right edge *self as a negative value
        else
            shift_x = ( rectangle.x + rectangle.width ) - self.x    -- distance from right edge rectangle to left edge *self as a positive value
        end
        -- if center of *self is above the center of rectangle
        if ( self.y + self.height / 2 ) < ( rectangle.y + rectangle.height / 2 ) then
            shift_y = rectangle.y - ( self.y + self.height )            -- distance from top edge rectangle to bottom edge *self as a negative value
        else
            shift_y = ( rectangle.y + rectangle.height ) - self.y       -- distance from bottom edge rectangle to top edge *self as a positive value
        end
    end
    return is_overlap, shift_x, shift_y
end

--[[
    Rebound *self by its displacement values (update position)
    see: https://github.com/noooway/love2d_arkanoid_tutorial/wiki/Resolving-Collisions
    Displacement values can be obtained from Rect:getDisplacement()
    Set the bigger shift amount to 0. Rebound *self only with the smaller shift value (smallest effort to resolve overlap).
    shift_x, shift_y: input. x and y shift values.
    rectangle: input. optional/ can be nil. Rect object. rectangle at which *self gets rebounded.
    If rectangle specified: Use a more precise rebounding.
    Rebounding by adding the shift value to the position may not be good enough, because of the insufficient precision of float operations.
    return: shift_x, shift_y after the bigger shift amount got set to 0. This tells in which direction the shift was performed.
]]
function Rect:rebound(shift_x, shift_y, rectangle)
    -- set the bigger shift amount to 0. if they are the same, set the y shift to 0.
    if math.abs(shift_x) > math.abs(shift_y) then
        shift_x = 0
    else
        shift_y = 0
    end
    -- if shift not 0, rebound *self
    if rectangle then
        if shift_x > 0 then
            self.x = rectangle.x + rectangle.width
        elseif shift_x < 0 then
            self.x = rectangle.x - self.width
        elseif shift_y > 0 then
            self.y = rectangle.y + rectangle.height
        elseif shift_y < 0 then
            self.y = rectangle.y - self.height
        end
    else
        if shift_x ~= 0 then
            self.x = self.x + shift_x
        elseif shift_y ~= 0 then
            self.y = self.y + shift_y
        end
    end

    return shift_x, shift_y
end

--[[
    check which edge of *self is intersecting with rectangle. The intersecting edge is calculated based on the x, y shift values.
    rectangle: input. Rect object. Rectangle to check
    return:
        table that contains boolean values that specify which edge is overlapping in this order: left, right, top, bottom
        If the coordinates of the overlapping edges are exactly the same, the returned table will not contain true
]]
function Rect:getIntersectingEdge(rectangle)
    local intersects_lrtb = {false, false, false, false}
    local is_overlap, shift_x, shift_y = self:getDisplacement(rectangle)
    if not is_overlap then
        return intersects_lrtb
    end
    -- the direction in which *self would get rebounded on the rectangle contains the information which edge is the intersecting one
    if math.abs(shift_x) > math.abs(shift_y) then
        shift_x = 0
    else
        shift_y = 0
    end
    if shift_x > 0 then
        intersects_lrtb[1] = true
    elseif shift_x < 0 then
        intersects_lrtb[2] = true
    elseif shift_y > 0 then
        intersects_lrtb[3] = true
    elseif shift_y < 0 then
        intersects_lrtb[4] = true
    end

    return intersects_lrtb
end

--[[
    Same as getIntersectingEdge(), but return true also if the overlapping edges are on top of each other
    After rebound(), rectangles still intersect "slightly"
    return: the returned table will have one element with the following value:
        true if rectangles overlap, false otherwise.
        true if the coordinates of the overlapping edges are exactly the same.
        false if the rectangles are exactly diagonal to each other (if just two corner points overlap)
]]
function Rect:getSlightlyIntersectingEdge(rectangle)
    local intersects_slightly_lrtb = {false, false, false, false}
    -- this also filters out the cases where two corner points overlap
    if not self:intersectsSlightly(rectangle) then
        return intersects_slightly_lrtb
    end

    if self.x == rectangle.x + rectangle.width then
        intersects_slightly_lrtb[1] = true
    elseif self.x + self.width == rectangle.x then
        intersects_slightly_lrtb[2] = true
    elseif self.y == rectangle.y + rectangle.height then
        intersects_slightly_lrtb[3] = true
    elseif self.y + self.height == rectangle.y then
        intersects_slightly_lrtb[4] = true
    else
        intersects_slightly_lrtb = self:getIntersectingEdge(rectangle)
    end

    return intersects_slightly_lrtb
end
