function Start()
    SCREEN_WIDTH = 800
    SCREEN_HEIGHT = 600
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Walking With Acceleration")
    
    player = {}
    player.image = LoadImage("images/gme/player.png")
    player.x = SCREEN_WIDTH / 2 - 16
    player.y = SCREEN_HEIGHT - 64
    player.xVel = 0
    player.xAcc = 0
    player.speed = 0.5
    player.maxSpeed = 16
        
    ground = LoadImage("images/gme/ground.png")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 15)
    
    tileSize = 32
end

function Update()
    if IsKeyDown(SDL_SCANCODE_LEFT) then
        player.xAcc = -player.speed
    elseif IsKeyDown(SDL_SCANCODE_RIGHT) then
        player.xAcc = player.speed
    else
        player.xAcc = 0
        player.xVel = 0
    end
    
    player.xVel = player.xVel + player.xAcc
    player.x = player.x + player.xVel
    
    -- clamp max velocity
    if player.xVel > player.maxSpeed then
        player.xVel = player.maxSpeed
    end
    
    if player.xVel < -player.maxSpeed then
        player.xVel = -player.maxSpeed
    end
    
    -- lock player to world
    if player.x < 0 then
        player.x = 0
        player.xVel = 0
    end
    
    if player.x > SCREEN_WIDTH - tileSize then
        player.x = SCREEN_WIDTH - tileSize
        player.xVel = 0
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
    
    --DrawText("ACC: " .. player.xAcc, 8, 9, font, 255, 255, 255);
    DrawText("VEL: " .. player.xVel, 8, 9, font, 255, 255, 255);
end