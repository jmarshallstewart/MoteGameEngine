SCREEN_WIDTH = 800
SCREEN_HEIGHT = 450

SHOTS_PER_SECOND = 7
MS_PER_SHOT = 1000 / SHOTS_PER_SECOND
BULLET_SPEED = 8

fireTimer = 0
turret = {}
bullets = {}

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Bullet Aiming Demo")
    bulletImage = LoadImage("images/gme/bullet.png")
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    turret.width = 32;
    turret.height = 32;
    turret.x = 64;
    turret.y = SCREEN_HEIGHT / 2;
    turret.angle = 0;
end

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
    bullet.angle = turret.angle
    
    bullets[#bullets + 1] = bullet
end

function Update()
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
    
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.xVel
        b.y = b.y + b.yVel
        if b.x > SCREEN_WIDTH or b.x < -b.width or b.y < -b.height or b.y > SCREEN_HEIGHT then
            table.remove(bullets, i)
        end
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    for k,v in pairs(bullets) do
        DrawImage(bulletImage, v.x - v.width * 0.5, v.y - v.height * 0.5, v.angle)
    end
    DrawImage(bulletImage, turret.x - turret.width * 0.5, turret.y - turret.height * 0.5, turret.angle)
    DrawText("Click and hold mouse to fire.", 8, 8, font, 255, 255, 255)
    DrawText("Num bullets: " .. #bullets, 8, 32, font, 255, 255, 255)
end