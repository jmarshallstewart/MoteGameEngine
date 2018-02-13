-- This script demonstrates flocking behaviors for AI agents.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------

SCREEN_WIDTH = 1600
SCREEN_HEIGHT = 900

FLOCK_SIZE = 100
MAX_ALIGNMENT_DISTANCE = 40
MAX_COHESION_DISTANCE = 600
MAX_SEPARATION_DISTANCE = 30
MAX_SPEED = 8.0

USER_BEHAVIOR_WEIGHT = 0.15
SEPARATION_WEIGHT = 0.45
ALIGNMENT_WEIGHT = 0.3
COHESION_WEIGHT = 0.1

boids = {}

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------

function SpawnFlock()
    for i = 1, FLOCK_SIZE do
        local x = math.random(0, SCREEN_WIDTH);
        local y = math.random(0, SCREEN_HEIGHT);
        local boid = CreateEntity(boidImage, x, y, 32, 16)
        boid.drag = 0.95
        boid.maxSpeed = MAX_SPEED
        
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

function Separation(agent, neighbors)
    local vX, vY = 0, 0
    
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if (n ~= agent) and (Distance(n.x, n.y, agent.x, agent.y) <= MAX_SEPARATION_DISTANCE) then
            vX = vX + agent.x - n.x
            vY = vY + agent.y - n.y
        end
    end
    
    if vX ~= 0 and vY ~=0 then
        return Normalize(vX, vY)
    end
    
    return 0, 0
end

function Alignment(agent, neighbors)
    local vX, vY = 0, 0
    
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if (n ~= agent) and (Distance(n.x, n.y, agent.x, agent.y) <= MAX_ALIGNMENT_DISTANCE) then
            vX = vX + n.velocity.x
            vY = vY + n.velocity.y
        end
    end
    
    if vX ~= 0 and vY ~=0 then
        return Normalize(vX / numNeighbors, vY / numNeighbors)
    end
    
    return 0, 0
end

function Cohesion(agent, neighbors)
    local centerX, centerY = 0, 0
        
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if (n ~= agent) and (Distance(n.x, n.y, agent.x, agent.y) <= MAX_COHESION_DISTANCE) then
            centerX = centerX + n.x
            centerY = centerY + n.y
        end
    end
    
    centerX = centerX / numNeighbors
    centerY = centerY / numNeighbors
       
    return Normalize( VectorTo(agent.x, agent.y, centerX, centerY) )
end

------------------------------------------------------------------------------
-- required mingine functions
------------------------------------------------------------------------------

-- called once, at the start of the game
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Mingine Flocking Demo")
    
    boidImage = LoadImage("images/arrow.png")
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
    
    for i = 1, numNeighbors do
        local boid = boids[i]
                
        bX, bY = Seek(boid, mouseX, mouseY)
        aX, aY = Alignment(boid, boids)
        cX, cY = Cohesion(boid, boids)
        sX, sY = Separation(boid, boids)
        
        boid.acceleration.x = bX * USER_BEHAVIOR_WEIGHT + aX * ALIGNMENT_WEIGHT + cX * COHESION_WEIGHT + sX * SEPARATION_WEIGHT
        boid.acceleration.y = bY * USER_BEHAVIOR_WEIGHT + aY * ALIGNMENT_WEIGHT + cY * COHESION_WEIGHT + sY * SEPARATION_WEIGHT
        boid.acceleration.x, boid.acceleration.y = Normalize(boid.acceleration.x, boid.acceleration.y)
        
        TurnTo(boid, boid.velocity)
        UpdateEntity(boid)
    end
end

-- called for each new frame drawn to the screen.
function Draw()
    ClearScreen(68, 136, 204)
    
    for i = 1, #boids do
        DrawEntity(boids[i])
    end
end