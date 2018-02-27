dofile(scriptDirectory .. "core/stateMachine.lua")
dofile(scriptDirectory .. "core/steering.lua")

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

MAX_ACCELERATION = 0.5 -- how fast can the agent change direction and speed?

CHASE_START_DISTANCE = 200
CHASE_END_DISTANCE = 500

--------------------------------------------
-- agent state behaviors
--------------------------------------------
function GetDistanceToMouse(agent)
    mouseX, mouseY = GetMousePosition()
    toMouse = {}
    toMouse.x, toMouse.y = VectorTo(agent.x, agent.y, mouseX, mouseY)
    
    return Magnitude(toMouse.x, toMouse.y)
end

--------------------------------------------
-- agent state behaviors
--------------------------------------------

function WanderEnter(agent)
    agent.r = 255
    agent.g = 255
    agent.b = 255
    
    MAX_ACCELERATION = 0.5
end

function WanderUpdate(agent)
    local x, y = Wander(agent)
    x, y = Normalize(x, y)
    agent.acceleration.x, agent.acceleration.y = Scale(x, y, MAX_ACCELERATION)
        
    TurnTo(agent, agent.velocity)
    UpdateEntity(agent)
    
    -- confine agent to visible screen
    if agent.x > SCREEN_WIDTH then agent.x = 0 end
    if agent.y > SCREEN_HEIGHT then agent.y = 0 end
    if agent.x < 0 then agent.x = SCREEN_WIDTH end
    if agent.y < 0 then agent.y = SCREEN_HEIGHT end
    
    --transitions
    if GetDistanceToMouse(agent) < CHASE_START_DISTANCE then 
        EnterState(agent, chaseState)
    end
end

function WanderExit(agent)
    PlaySound(alertSfx)
end

function ChaseEnter(agent)
    agent.r = 255
    agent.g = 0
    agent.b = 0
    
    MAX_ACCELERATION = 0.8
end

function ChaseUpdate(agent)
    mouseX, mouseY = GetMousePosition()
    local x, y = Seek(agent, mouseX, mouseY)
    x, y = Normalize(x, y)
    agent.acceleration.x, agent.acceleration.y = Scale(x, y, MAX_ACCELERATION)
       
    TurnTo(agent, agent.velocity)
    UpdateEntity(agent)
    
    --transitions
    if GetDistanceToMouse(agent) > CHASE_END_DISTANCE then 
        EnterState(agent, wanderState)
    end
end

function ChaseExit(agent)
    --do nothing
end

--------------------------------------------
-- state objects
--------------------------------------------

wanderState = {}
wanderState.name = "Wander"
wanderState.Enter = WanderEnter
wanderState.Update = WanderUpdate
wanderState.Exit = WanderExit

chaseState = {}
chaseState.name = "Chase"
chaseState.Enter = ChaseEnter
chaseState.Update = ChaseUpdate
chaseState.Exit = ChaseExit

--------------------------------------------
-- mingine hooks
--------------------------------------------

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Agent State Machine Example.")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    alertSfx = LoadSound("sfx/happy.wav")
    
    local image = LoadImage("images/arrow.png")
    agent = CreateEntity(image, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, 16)
    agent.maxSpeed = 10
    agent.wanderAngle = 0
    
    CreateStateMachine(agent, wanderState)
end

function Update()
   UpdateStateMachine(agent)
end

function Draw()
    ClearScreen(68, 136, 204)
            
    SetDrawColor(255, 0, 255, 255)
              
    DrawEntity(agent)
    --line over agent represents direction of acceleration
    local accDirX, accDirY = Mad(agent, agent.acceleration, 32)
    DrawLine(agent.x, agent.y, accDirX, accDirY) 

    DrawText("State: " .. agent.stateMachine.currentState.name, 8, 9, font, 255, 255, 255)
end