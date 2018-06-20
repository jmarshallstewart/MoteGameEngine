------------------------------------------------------------------------------
-- includes
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Chase the Mouse")
    
    dripImage = LoadImage("images/drip.png")
    agent = CreateEntity(dripImage, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 14, 29)
    agent.speed = 4
end

function Update()
    mouseX, mouseY = GetMousePosition()
    toTarget = {}
    toTarget.x, toTarget.y = VectorTo(agent.x, agent.y, mouseX, mouseY)
    toTarget.x, toTarget.y = Normalize(toTarget.x, toTarget.y)
    
    SetVector(agent.velocity, toTarget.x * agent.speed, toTarget.y * agent.speed)

    UpdateEntity(agent)
end

function Draw()
    ClearScreen(68, 136, 204)
    DrawEntity(agent)
end