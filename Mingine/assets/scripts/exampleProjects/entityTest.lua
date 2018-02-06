--constants
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

--core functions
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Entity Test")
    
    playerImage = LoadImage("images/gme/blurred-circle.png")
    player = CreateEntity(playerImage, SCREEN_WIDTH / 2, 96, 256, 256)
    SetEntityScale(player, 0.35)
end

function Update()
    player.acceleration.y = player.acceleration.y + 0.076
    UpdateEntity(player)
end

function Draw()
    ClearScreen(68, 136, 204)
    
    DrawEntity(player)
    
    -- draw bounding box of entity
    local box = GetEntityRect(player)
    SetDrawColor(0xff, 0, 0xff, 0xff)
    DrawRect(box.x, box.y, box.w, box.h)
end