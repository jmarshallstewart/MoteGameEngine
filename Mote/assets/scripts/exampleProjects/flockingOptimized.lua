-- This script demonstrates flocking behaviors for AI agents.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------

SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080


--[[ 
    Ratio of Flock Size and MAX_FLOCK_PER_FRAME

    1000:68
    1250:58
    1600:38
    2000:28 (But at this point, almost nothing makes sense)
 ]]

FLOCK_SIZE = 1000
MAX_FLOCK_PER_FRAME = 68

MAX_ALIGNMENT_DISTANCE = 100
MAX_COHESION_DISTANCE = 600
MAX_SEPARATION_DISTANCE = 20    -- 20(around 1000 Flocks); 10(around 1600 Flocks); 5(around 2000 Flocks);
MAX_SPEED = 10.0

USER_BEHAVIOR_WEIGHT = 0.35
SEPARATION_WEIGHT = 0.33         -- 0.33(around 1000 Flocks); 0.3(around 1600 Flocks); 0.25(around 2000 Flocks);
ALIGNMENT_WEIGHT = 0.3
COHESION_WEIGHT = 0.15

boids = {}
boidStart = -1
boidStop = -1

flockTopLeft = {
    x = SCREEN_WIDTH,
    y = SCREEN_HEIGHT
}
flockBottomRight = {
    x = 0,
    y = 0
}

frameCounter = 0
frameExecInterval = 1

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------

function SpawnFlock()
    mouseX, mouseY = GetMousePosition()

    for i = 1, FLOCK_SIZE do
        local x = math.random(0, SCREEN_WIDTH)
        local y = math.random(0, SCREEN_HEIGHT)
        local boid = CreateEntity(boidImage, x, y, 32, 16)
        boid.drag = 0.95
        boid.maxSpeed = MAX_SPEED
        boid.acceleration.x, boid.acceleration.y = Normalize(VectorTo(boid.x, boid.y, mouseX, mouseY))
        boid.targetAngle = 0
        
        boids[#boids + 1] = boid
    end
end

------------------------------------------------------------------------------
-- steering behaviors
--
-- functions related to movement of AI agents in a game.
-- each of these functions returns a normalized 2D vector that 
-- represents a steering force.
--
------------------------------------------------------------------------------

function Seek(agent, targetX, targetY)
    local x, y = VectorTo(agent.x, agent.y, targetX, targetY)
    x, y = Normalize(x, y)
    
    return x, y
end

function Flee(agent, targetX, targetY)
    local x, y = VectorTo(targetX, targetY, agent.x, agent.y)
    x, y = Normalize(x, y)
    
    return x, y
end

function Separation(agent, neighbors, distFromNeighbors)
    local vX, vY = 0, 0
    
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if (n ~= agent) and (distFromNeighbors[i] <= MAX_SEPARATION_DISTANCE) then
            vX = vX + agent.x - n.x
            vY = vY + agent.y - n.y
        end
    end
    
    if vX ~= 0 or vY ~=0 then
        return Normalize(vX, vY)
    end
    
    return 0, 0
end

function Alignment(agent, neighbors, distFromNeighbors)
    local vX, vY = 0, 0
    
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if (n ~= agent) and (distFromNeighbors[i] <= MAX_ALIGNMENT_DISTANCE) then
            vX = vX + n.velocity.x
            vY = vY + n.velocity.y
        end
    end
    
    if vX ~= 0 or vY ~=0 then
        return Normalize(vX / numNeighbors, vY / numNeighbors)
    end
    
    return 0, 0
end

function Cohesion(agent, neighbors, distFromNeighbors)
    local centerX, centerY = 0, 0
        
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if (n ~= agent) and (distFromNeighbors[i] <= MAX_COHESION_DISTANCE) then
            centerX = centerX + n.x
            centerY = centerY + n.y
        end
    end
    
    centerX = centerX / numNeighbors
    centerY = centerY / numNeighbors

    -- centerX = (flockTopLeft.x + flockBottomRight.x)/2;
    -- centerY = (flockTopLeft.y + flockBottomRight.y)/2;
       
    return Normalize( VectorTo(agent.x, agent.y, centerX, centerY) )
end

------------------------------------------------------------------------------
-- required mote functions
------------------------------------------------------------------------------

-- called once, at the start of the game
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Mote Flocking Demo")
    
    boidImage = LoadImage("images/gme/bullet.png")
    SpawnFlock()
end

-- called at a fixed interval (16 ms) to update the state of the game world.
function Update()
    mouseX, mouseY = GetMousePosition()
    
    numNeighbors = #boids
    
    if numNeighbors == 0 then
        return
    end

    local bX, bY, aX, aY, cX, cY, sX, sY = 0, 0, 0, 0, 0, 0, 0, 0   

    if boidStart < 1 or boidStart > numNeighbors then
        boidStart = 1
    end

    boidStop = boidStart + MAX_FLOCK_PER_FRAME
    
    if boidStop > numNeighbors then
        boidStop = numNeighbors
    end

    if frameCounter == 0 then
        local distTemp = {}
        
        for i = boidStart, boidStop do 
            local agent = boids[i]
            distTemp[i] = {}

            for j = 1, numNeighbors do
                local n = boids[j]
                if (n ~= agent) then 
                    distTemp[i][j] = Distance(n.x, n.y, agent.x, agent.y)
                end
            end
        end

        for i = boidStart, boidStop do
            local boid = boids[i]
                    
            bX, bY = Seek(boid, mouseX, mouseY)
            aX, aY = Alignment(boid, boids, distTemp[i])
            cX, cY = Cohesion(boid, boids, distTemp[i])
            sX, sY = Separation(boid, boids, distTemp[i])
            
            boid.acceleration.x = bX * USER_BEHAVIOR_WEIGHT + aX * ALIGNMENT_WEIGHT + cX * COHESION_WEIGHT + sX * SEPARATION_WEIGHT
            boid.acceleration.y = bY * USER_BEHAVIOR_WEIGHT + aY * ALIGNMENT_WEIGHT + cY * COHESION_WEIGHT + sY * SEPARATION_WEIGHT
            boid.acceleration.x, boid.acceleration.y = Normalize(boid.acceleration.x, boid.acceleration.y)
        end

        boidStart = boidStop + 1

        for i = 1, numNeighbors do 
            local boid = boids[i];
            TurnTo(boid, boid.velocity)
        end
    end

    frameCounter = frameCounter + 1
    if frameCounter>frameExecInterval then
        frameCounter = 0
    end

    for i = 1, numNeighbors do 
        local boid = boids[i];
        
        UpdateEntity(boid)

        flockTopLeft.x = math.min(boid.x, flockTopLeft.x)
        flockTopLeft.y = math.min(boid.y, flockTopLeft.y)
        
        flockBottomRight.x = math.max(boid.x, flockBottomRight.x)
        flockBottomRight.y = math.max(boid.y, flockBottomRight.y)
    end
end

-- called for each new frame drawn to the screen.
function Draw()
    ClearScreen(68, 136, 204)
    
    for i = 1, #boids do
        DrawEntity(boids[i])
    end
end