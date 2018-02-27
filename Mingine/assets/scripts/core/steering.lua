------------------------------------------------------------------------------
--
-- steering behaviors
--
-- functions related to movement of AI agents in a game.
-- each of these functions returns a normalized 2D vector that 
-- represents a steering force.
--
------------------------------------------------------------------------------

MAX_ALIGNMENT_DISTANCE = 40
MAX_COHESION_DISTANCE = 600
MAX_SEPARATION_DISTANCE = 30

WANDER_CIRCLE_OFFSET = 50
WANDER_CIRCLE_RADIUS = 30
WANDER_ANGLE_DELTA_MAX = 0.2

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

function Wander(agent)
    local toCircle = {}
    Set(toCircle, agent.velocity.x, agent.velocity.y, WANDER_CIRCLE_OFFSET) 
   
    agent.wanderAngle = agent.wanderAngle + math.random() * WANDER_ANGLE_DELTA_MAX - WANDER_ANGLE_DELTA_MAX * 0.5
    
    local toPointOnCircle = {}
    Set(toPointOnCircle, math.cos(agent.wanderAngle), math.sin(agent.wanderAngle), WANDER_CIRCLE_RADIUS)
    
    local targetX = agent.x + toCircle.x + toPointOnCircle.x
    local targetY = agent.y + toCircle.y + toPointOnCircle.y
    
    return Seek(agent, targetX, targetY)
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