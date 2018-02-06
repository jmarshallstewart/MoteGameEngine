-- constant data
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 450
TILE_SIZE = 32
SHOTS_PER_SECOND = 9
MS_PER_SHOT = 1000 / SHOTS_PER_SECOND
BULLET_SPEED = 17
GRAVITY = 0.02
EXPLOSION_FRAME_TIME = 1000.0 / 60.0
EXPLOSION_FRAME_SIZE = 128
MIN_EXPLOSION_SCALE = 0.2
MAX_EXPLOSION_SCALE = 1.7
NUM_EXPLOSION_FRAMES = 4

--transient data
fireTimer = 0
turret = {}
bullets = {}
explosions = {}

function Fire()
    fireTimer = fireTimer + MS_PER_SHOT
    
    bullet = {}
    bullet.x = turret.x
    bullet.y = turret.y
    bullet.width = 32
    bullet.height = 32
    local angle = math.rad(turret.angle)
    bullet.xVel = math.cos(angle) 
    bullet.yVel = math.sin(angle)
    bullet.xVel, bullet.yVel = Scale(bullet.xVel, bullet.yVel, BULLET_SPEED)
    bullet.xAcc = 0
    bullet.yAcc = 0
    bullet.angle = turret.angle
    
    bullets[#bullets + 1] = bullet
end

function GetRandomExplosionColor()
    local choice = math.random(1, 3)
    
    if choice == 1 then
        return 255, 255, 51
    elseif choice == 2 then
        return 255, 153, 51
    elseif choice == 3 then
        return 255, 51, 51
    else
        Log("No color for this explosion choice.")
    end
end

function CreateExplosion(x, y)
    explosion = {}
    explosion.x = x
    explosion.y = y
    explosion.frame = 1
    explosion.frameTimer = EXPLOSION_FRAME_TIME
    explosion.angle = math.random() * 360.0
    explosion.scale = MIN_EXPLOSION_SCALE + math.random() * (MAX_EXPLOSION_SCALE - MIN_EXPLOSION_SCALE)
    explosion.r, explosion.g, explosion.b = GetRandomExplosionColor()
    
    explosions[#explosions + 1] = explosion
end

function UpdateTurret()
    local mouseX = -1
    local mouseY = -1
    mouseX, mouseY = GetMousePosition()
    
    local x = 0
    local y = 0
    x, y = VectorTo(turret.x, turret.y, mouseX, mouseY)
    turret.angle = math.deg(math.atan(y, x))

    if fireTimer > 0 then
        fireTimer = fireTimer - GetFrameTime()
        if fireTimer < 0 then
            fireTimer = 0
        end
    end
    
    if fireTimer == 0 and IsMouseButtonDown(1) then
        Fire()
    end
end

function UpdateBullets()
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        
        b.yAcc = b.yAcc + GRAVITY
        b.xVel = b.xVel + b.xAcc
        b.yVel = b.yVel + b.yAcc
        b.x = b.x + b.xVel
        b.y = b.y + b.yVel
        b.angle = math.deg(math.atan(b.yVel, b.xVel))
        
        if b.y > groundHeight - b.width * 0.5 then
            CreateExplosion(b.x, b.y)
            table.remove(bullets, i)
        end
    end
end

function UpdateExplosions()
    for i = #explosions, 1, -1 do
        local e = explosions[i]
        e.frameTimer = e.frameTimer - GetFrameTime()
        
        if e.frameTimer <= 0.0 then
            e.frame = e.frame + 1
            
            if e.frame > NUM_EXPLOSION_FRAMES then
                table.remove(explosions, i)
            else
                e.frameTimer = e.frameTimer + EXPLOSION_FRAME_TIME
            end
        end
    end
end

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, false)
    SetWindowTitle("Bullet Artillery Demo")
    
    bulletImage = LoadImage("images/gme/bullet.png")
    explosionImage = LoadImage("images/gme/explosion.png")
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    ground = LoadImage("images/gme/ground.png")
        
    groundHeight = SCREEN_HEIGHT - TILE_SIZE
    
    turret.width = TILE_SIZE;
    turret.height = TILE_SIZE;
    turret.x = 64;
    turret.y = SCREEN_HEIGHT - 80;
    turret.angle = 0;
end

function Update()
    UpdateTurret()
    UpdateBullets()
    UpdateExplosions()
end

function Draw()
    ClearScreen(68, 136, 204)
    
    --draw bullets
    for k,v in pairs(bullets) do
        DrawImage(bulletImage, v.x - v.width * 0.5, v.y - v.height * 0.5, v.angle)
    end
    
    -- draw turret
    DrawImage(bulletImage, turret.x - turret.width * 0.5, turret.y - turret.height * 0.5, turret.angle)
    
    -- draw ground
    local x = 0
    while x < SCREEN_WIDTH do
        DrawImage(ground, x, SCREEN_HEIGHT - TILE_SIZE)
        x = x + TILE_SIZE
    end
    
    -- draw explosions
    for k,v in pairs (explosions) do
        local half = EXPLOSION_FRAME_SIZE * 0.5 * v.scale
        local size = EXPLOSION_FRAME_SIZE
        DrawImageFrame(explosionImage, v.x - half, v.y - half, size, size, v.frame, v.angle, v.scale, v.r, v.g, v.b)
    end
    
    -- draw text
    DrawText("Click and hold mouse to fire.", 8, 8, font, 255, 255, 255)
    DrawText("Num bullets: " .. #bullets, 8, 32, font, 255, 255, 255)
end