SCREEN_WIDTH = 800
SCREEN_HEIGHT = 300

FIRE_X = 16
FIRE_Y = SCREEN_HEIGHT / 2 - 16
BULLET_SPEED = 10

bullet = nil

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Single Shot Bullet Demo")
    bulletImage = LoadImage("images/gme/bullet.png")
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
end

function Update()
    if bullet == nil and IsMouseButtonDown(1) then
        bullet = {}
        bullet.x = FIRE_X
        bullet.y = FIRE_Y
        bullet.xVel = BULLET_SPEED
    end
    
    if bullet ~= nil then
        bullet.x = bullet.x + bullet.xVel
        if bullet.x > SCREEN_WIDTH then
            bullet = nil
        end
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    if bullet ~= nil then
        DrawImage(bulletImage, bullet.x, bullet.y)
    end
    DrawImage(bulletImage, FIRE_X, FIRE_Y)
    DrawText("Click the mouse to fire.", 8, 8, font, 255, 255, 255)
end