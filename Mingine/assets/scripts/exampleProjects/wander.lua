dofile(scriptDirectory .. "core/steering.lua")

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

MAX_ACCELERATION = 0.5 -- how fast can the agent change direction and speed?

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Wander Steering Behavior")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    local image = LoadImage("images/arrow.png")
    agent = CreateEntity(image, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, 16)
    agent.maxSpeed = 10
    agent.wanderAngle = 0
end

function Update()
    local x, y = Wander(agent)
    x, y = Normalize(x, y)
    agent.acceleration.x, agent.acceleration.y = Scale(x, y, MAX_ACCELERATION)
        
    --the angle of our sprite should match its own velocity    
    TurnTo(agent, agent.velocity)
    UpdateEntity(agent)
    
    -- confine agent to visible screen
    if agent.x > SCREEN_WIDTH then agent.x = 0 end
    if agent.y > SCREEN_HEIGHT then agent.y = 0 end
    if agent.x < 0 then agent.x = SCREEN_WIDTH end
    if agent.y < 0 then agent.y = SCREEN_HEIGHT end
end

function Draw()
    ClearScreen(68, 136, 204)
            
    --draw the waypoints (radius = arrive distance)
    SetDrawColor(255, 0, 255, 255)
              
    DrawEntity(agent)
    --line over agent represents direction of acceleration
    local accDirX, accDirY = Mad(agent, agent.acceleration, 32)
    DrawLine(agent.x, agent.y, accDirX, accDirY) 
    
    DrawText("Speed: " .. string.format("%.3f", GetSpeed(agent)), 8, 9, font, 255, 255, 255)
end