function Start()
    SCREEN_WIDTH = 800
    SCREEN_HEIGHT = 600
    GROUND_HEIGHT = SCREEN_HEIGHT - 64
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Walking and Jumping")
    
    player = {}
    player.image = LoadImage("images/gme/player.png")
    player.x = SCREEN_WIDTH / 2 - 16
    player.y = GROUND_HEIGHT
    player.xVel = 0
    player.yVel = 0
    player.xAcc = 0
    player.yAcc = 0
    player.speed = 1
    player.maxSpeed = 8
    player.drag = 0.85 
    player.jumpImpulse = 25
    player.gravity = 0.5
    player.isJumping = false
        
    ground = LoadImage("images/gme/ground.png")
       
    tileSize = 32
end

function Update()
    if IsKeyDown(SDL_SCANCODE_UP) and not player.isJumping then
        player.yVel = -player.jumpImpulse
        player.isJumping = true
    end

    if IsKeyDown(SDL_SCANCODE_LEFT) then
        player.xAcc = -player.speed
    elseif IsKeyDown(SDL_SCANCODE_RIGHT) then
        player.xAcc = player.speed
    else
        player.xAcc = 0
    end
    
    if player.isJumping then
        player.yAcc = player.yAcc - player.gravity
    end
    
    player.xVel = player.xVel + player.xAcc
    player.yVel = player.yVel - player.yAcc
        
    -- remove very small x velocities
    if math.abs(player.xVel) < 0.2 then
        player.xVel = 0
    end
      
    player.x = player.x + player.xVel
    player.y = player.y + player.yVel
   
    -- clamp max x velocity
    if player.xVel > player.maxSpeed then
        player.xVel = player.maxSpeed
    end
   
    -- apply drag
    player.xVel = player.xVel * player.drag
    
    -- lock player to world
    if player.x < 0 then
        player.x = 0
        player.xVel = 0
    end
    
    if player.x > SCREEN_WIDTH - tileSize then
        player.x = SCREEN_WIDTH - tileSize
        player.xVel = 0
    end
    
    if player.y > GROUND_HEIGHT then
        player.y = GROUND_HEIGHT
        player.yVel = 0
        player.yAcc = 0
        player.isJumping = false
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