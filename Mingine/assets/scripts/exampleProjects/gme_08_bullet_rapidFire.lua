SCREEN_WIDTH = 800
SCREEN_HEIGHT = 300

FIRE_X = 16
FIRE_Y = SCREEN_HEIGHT / 2 - 16
BULLET_SPEED = 10

SHOTS_PER_SECOND = 8
MS_PER_SHOT = 1000 / SHOTS_PER_SECOND

fireTimer = 0
bullets = {}

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Rapid Fire Bullet Demo")
    bulletImage = LoadImage("images/gme/bullet.png")
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
end

function Fire()
    fireTimer = fireTimer + MS_PER_SHOT
    
    bullet = {}
    bullet.x = FIRE_X
    bullet.y = FIRE_Y
    bullet.xVel = BULLET_SPEED
    
    bullets[#bullets + 1] = bullet
end

function Update()
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
        bullets[i].x = bullets[i].x + bullets[i].xVel
        if bullets[i].x > SCREEN_WIDTH then
            table.remove(bullets, i)
        end
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    for k,v in pairs(bullets) do
        DrawImage(bulletImage, v.x, v.y)
    end
    DrawImage(bulletImage, FIRE_X, FIRE_Y)
    DrawText("Click mouse to fire.", 8, 8, font, 255, 255, 255)
    DrawText("Num bullets: " .. #bullets, 8, 32, font, 255, 255, 255)
end