------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080
SPEED = 10

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, true)
    SetWindowTitle("Ship Movement")
    
    playerImage = LoadImage("images/gme/ship.png")
    player = CreateEntity(playerImage, SCREEN_WIDTH / 2, 96, 32, 32)
    SetEntityScale(player, 2)
end

function Update()
    if IsKeyDown(SDL_SCANCODE_LEFT) then
        player.acceleration.x = -SPEED
    elseif IsKeyDown(SDL_SCANCODE_RIGHT) then
        player.acceleration.x = SPEED
    elseif IsKeyDown(SDL_SCANCODE_UP) then
        player.acceleration.y = -SPEED
    elseif IsKeyDown(SDL_SCANCODE_DOWN) then
        player.acceleration.y = SPEED
    else
        player.acceleration.x = 0
        player.acceleration.y = 0
    end
    
    UpdateEntity(player)
    
    if player.x < player.width / 2 then player.x = player.width / 2 end
    if player.y < player.height / 2 then player.y = player.height / 2 end
    if player.x > SCREEN_WIDTH - player.width / 2 then player.x = SCREEN_WIDTH - player.width / 2 end
    if player.y > SCREEN_HEIGHT - player.height / 2 then player.y = SCREEN_HEIGHT - player.height / 2 end
end

function Draw()
    ClearScreen(68, 136, 204)
    e.angle = e.angle + 1
    DrawEntity(player)
end