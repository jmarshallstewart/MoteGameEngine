dofile(scriptDirectory .. "core/steering.lua")

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

ARRIVE_DISTANCE = 16

targetWaypoint = 1
MAX_ACCELERATION = 1.0 -- how fast can the agent change direction and speed?

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Path Following Example")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    local image = LoadImage("images/arrow.png")
    agent = CreateEntity(image, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, 16)
    agent.maxSpeed = 10
    
    path = {}
    path[1] = {x = 64, y = 80}
    path[2] = {x = SCREEN_WIDTH - 64, y = 80}
    path[3] = {x = SCREEN_WIDTH - 300, y = SCREEN_HEIGHT / 2}
    path[4] = {x = SCREEN_WIDTH - 64, y = SCREEN_HEIGHT - 64}
    path[5] = {x = 64, y = SCREEN_HEIGHT - 64}
end

function Update()
    --get the next waypoint along the path
    local next = path[targetWaypoint]

    --next waypoint on the path is our seek target. 
    --accelerate toward that.
    local x, y = Seek(agent, next.x, next.y)
    Set(agent.acceleration, x, y, MAX_ACCELERATION)
            
    --the angle of our sprite should match its own velocity    
    TurnTo(agent, agent.velocity)
    UpdateEntity(agent)
    
    --if agent is close enough to the current waypoint, set the next 
    --waypoint as the new target (wrapping back to the first waypoint if needed)
    if Distance(agent.x, agent.y, next.x, next.y) <= ARRIVE_DISTANCE then
        targetWaypoint = targetWaypoint + 1
        if targetWaypoint > #path then
            targetWaypoint = 1
        end
    end
end

function Draw()
    ClearScreen(68, 136, 204)
            
    --draw the waypoints (radius = arrive distance)
    SetDrawColor(255, 0, 255, 255)
    
    for i = 1, #path do
        DrawCircle(path[i].x, path[i].y, ARRIVE_DISTANCE)
    end
        
    DrawEntity(agent)
    --line over agent represents direction of acceleration
    local accDirX, accDirY = Mad(agent, agent.acceleration, 32)
    DrawLine(agent.x, agent.y, accDirX, accDirY) 
    
    DrawText("Speed: " .. string.format("%.3f", GetSpeed(agent)), 8, 9, font, 255, 255, 255)
end