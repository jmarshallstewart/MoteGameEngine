-- VECTOR 2D

function CreateVector(x, y)
    local v = {}
    v.x = x
    v.y = y
    return v
end

function CreateZeroVector()
    return CreateVector(0, 0)
end

-- returns a new vector (a lua table w/ x and y properties)
function CloneVector(original)
    return CreateVector(original.x, original.y)
end

function SetVector(v, x, y)
    v.x = x
    v.y = y
end

function MagnitudeSquared(x, y)
    return x * x + y * y
end

function Magnitude(x, y)
    return math.sqrt(x * x + y * y)
end

function Normalize(x, y)
    local magnitude = Magnitude(x, y)
    
    if magnitude == 0 then
        Log("attempted to normalize zero-length vector.")
        return 0, 0
    end
    
    return x / magnitude, y / magnitude
end

function Scale(x, y, scale)
    return x * scale, y * scale
end

function VectorTo(fromX, fromY, toX, toY)
    return toX - fromX, toY - fromY
end

--arguments should both be 2d vectors
function To(from, to)
    return to.x - from.x, to.y - from.y
end

--sets outVector to the direction and magnitude specified in the parameters.
--direction does not need to be normalized for this function.
function Set(outVector, directionX, directionY, magnitude)
    outVector.x, outVector.y = Normalize(directionX, directionY)
    outVector.x, outVector.y = Scale(outVector.x, outVector.y, magnitude)
end

--mad is shorthand for "multiply then add"
--this is useful for adding a scaled vector as an offset from a point
--represented as a vector
--
--parameters:
--vec1 and vec2 are tables that have .x and .y properties. 
--scale is a number.
function Mad(vec1, vec2, scale)
    return vec1.x + vec2.x * scale, vec1.y + vec2.y * scale
end

-- POINTS

function DistanceSquared(x1, y1, x2, y2)
    return MagnitudeSquared(x2 - x1, y2 - y1)
end

function Distance(x1, y1, x2, y2)
    return Magnitude(x2 - x1, y2 - y1)
end

-- CIRCLES

function IsPointInCircle(x, y, circle)
    return Distance(x, y, circle.x, circle.y) <= circle.radius
end

--function CirclesOverlap(circle1, circle2)
--    return Distance(circle1.x, circle1.y, circle2.x, circle2.y) <= circle1.radius + circle2.radius
--end

function CirclesOverlap(x1, y1, radius1, x2, y2, radius2)
    return Distance(x1, y1, x2, y2) <= radius1 + radius1
end

-- BOXES

function IsPointInBox(x, y, box)
    return x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h
end

function BoxesOverlap(box1, box2)
	if box1.x >= box2.x + box2.w then return false end
	if box1.y >= box2.y + box2.h then return false end
	if box2.x >= box1.x + box1.w then return false end
	if box2.y >= box1.y + box1.h then return false end
    
    return true
end

-- CIRCLE-BOX COLLISION

function CircleBoxOverlap(circle, box)
    local closestX;
    local closestY;
    
    if circle.x < box.x then
        closestX = box.x
    elseif circle.x > box.x + box.w then
        closestX = box.x + box.w
    else
        closestX = circle.x
    end
    
    if circle.y < box.y then
        closestY = box.y
    elseif circle.y > box.y + box.h then
        closestY = box.y + box.h
    else
        closestY = circle.y
    end
    
    return Distance(closestX, closestY, circle.x, circle.y) < circle.radius;
end

