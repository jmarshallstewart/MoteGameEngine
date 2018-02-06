function Start()
    SCREEN_WIDTH = 800
    SCREEN_HEIGHT = 600
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Basic Walking")

    player = {}
    player.image = LoadImage("images/gme/player.png")
    player.x = SCREEN_WIDTH / 2 - 16
    player.y = SCREEN_HEIGHT - 64
    player.speed = 8
        
    ground = LoadImage("images/gme/ground.png")
        
    tileSize = 32
end

function Update()
    if IsKeyDown(SDL_SCANCODE_LEFT) then
        player.x = player.x - player.speed
    end
    
    if IsKeyDown(SDL_SCANCODE_RIGHT) then
        player.x = player.x + player.speed
    end
    
    if player.x < 0 then
        player.x = 0
    end
    
    if player.x > SCREEN_WIDTH - tileSize then
        player.x = SCREEN_WIDTH - tileSize
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    
    DrawImage(player.image, player.x, player.y)
    
    local x = 0
    while x < SCREEN_WIDTH do
        DrawImage(ground, x, SCREEN_HEIGHT - tileSize)
        x = x + tileSize
    end
end