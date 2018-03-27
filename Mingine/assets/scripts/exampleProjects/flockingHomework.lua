-- This script demonstrates flocking behaviors for AI agents.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------

SCREEN_WIDTH = 1600
SCREEN_HEIGHT = 900

FLOCK_SIZE = 400
MAX_ALIGNMENT_DISTANCE = 30
MAX_COHESION_DISTANCE = 60
MAX_SEPARATION_DISTANCE = 20
MAX_SPEED = 8.0

bird = 1

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

function updateBird()

end

function CES(agent, neighbors)
    local cX, cY = 0, 0
    local aX, aY = 0, 0
    local sX, sY = 0, 0
    local distance = 0
    
    local bX, bY = VectorTo(agent.x, agent.y, mouseX, mouseY)
    bX, bY = Normalize(bX, bY)
    
    for i = 1, numNeighbors do
        local n = neighbors[i]
        if n ~= agent then
                if i < 500 then
                    distance = Distance(n.x, n.y, agent.x, agent.y)
                    if n.y < 451 then
                        if n.x < 801 then
                            if (agent.x < 401) and (agent.y < 451) then
                                if  distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                            if (agent.x > 400) and (agent.y < 451) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                        else
                            if (agent.x < 1201) and (agent.y < 451) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                            if (agent.x > 1200) and (agent.y < 451) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                        end
                    else
                        if n.x < 801 then
                            if (agent.x < 401) and (agent.y > 450) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                            if (agent.x > 400) and (agent.y > 450) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                        else
                            if (agent.x < 1201) and (agent.y > 450) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                            if (agent.x > 1200) and (agent.y > 450) then
                                if distance <= MAX_COHESION_DISTANCE then
                                    cX = cX + n.x
                                    cY = cY + n.y
                                    if distance <= MAX_ALIGNMENT_DISTANCE then
                                        aX = aX + n.velocity.x
                                        aY = aY + n.velocity.y
                                        sX = sX + agent.x - n.x
                                        sY = sY + agent.y - n.y
                                    end
                                end
                            end
                        end
                    end
                end
        end
    end
    
    if cX ~= 0 and cY ~=0 then
        cX, cY = Normalize(cX /numNeighbors, cY / numNeighbors)
    end
    if aX ~= 0 and aY ~=0 then
        aX, aY = Normalize(sX / numNeighbors, sY / numNeighbors)
    end
    if sX ~= 0 and sY ~=0 then
        sX, sY = Normalize(sX, sY)
    end

    
    return Normalize(bX * USER_BEHAVIOR_WEIGHT + aX * ALIGNMENT_WEIGHT + cX * COHESION_WEIGHT + sX * SEPARATION_WEIGHT, bY * USER_BEHAVIOR_WEIGHT + aY * ALIGNMENT_WEIGHT + cY * COHESION_WEIGHT + sY * SEPARATION_WEIGHT)
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
                      
        boid.acceleration.x, boid.acceleration.y = CES(boid, boids)

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