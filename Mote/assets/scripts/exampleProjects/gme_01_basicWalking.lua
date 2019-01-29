function Start()
    SCREEN_WIDTH = 800
    SCREEN_HEIGHT = 600
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Basic Walking")

    ground = {}
    ground.image = LoadImage("images/gme/ground.png")
    ground.width = GetImageWidth(ground.image)
    ground.height = GetImageHeight(ground.image)
    
    player = {}
    player.image = LoadImage("images/gme/player.png")
    player.width = GetImageWidth(player.image)
    player.height = GetImageHeight(player.image)
    player.x = SCREEN_WIDTH / 2 - player.width / 2
    player.y = SCREEN_HEIGHT - ground.height - player.height
    player.speed = 8
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
    
    if player.x > SCREEN_WIDTH - player.width then
        player.x = SCREEN_WIDTH - player.width
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    
    DrawImage(player.image, player.x, player.y)
    
    local x = 0
    while x < SCREEN_WIDTH do
        DrawImage(ground.image, x, SCREEN_HEIGHT - ground.height)
        x = x + ground.width
    end
end