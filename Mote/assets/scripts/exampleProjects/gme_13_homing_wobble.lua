------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080
SPEED = 10
TURN_RATE = 4
WOBBLE_LIMIT = 15
WOBBLE_SPEED = 11

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------
angleToTarget = 0

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, true)
    SetWindowTitle("Homing Missile with Wobble")
    
    missileImage = LoadImage("images/gme/bullet.png")
    missile = CreateEntity(missileImage, SCREEN_WIDTH / 2, SCREEN_HEIGHT - 32, 32, 32)
    missile.wobble = 0;
        
    font = LoadFont("fonts/8_bit_pusab.ttf", 15)
end

time = 0

function Update()
    missile.wobble = math.sin(os.clock() * WOBBLE_SPEED) * WOBBLE_LIMIT 

    mouseX, mouseY = GetMousePosition()
    x, y = VectorTo(missile.x, missile.y, mouseX, mouseY)
    angleToTarget = math.deg(math.atan(y, x)) + missile.wobble
        
    if missile.angle ~= angleToTarget then
        delta = angleToTarget - missile.angle
        
        -- wrap to smaller angle
        if delta > 180 then
            delta = delta - 360
        end
        
        if delta < -180 then
            delta = delta + 360
        end
        
        -- apply delta clamped by turn rate
        if delta > 0 then
            missile.angle = missile.angle + TURN_RATE
        else
            missile.angle = missile.angle - TURN_RATE
        end
        
        -- slam to target if close
        if math.abs(delta) < TURN_RATE then
            e.angle = angleToTarget
        end
    end
            
    missile.velocity.x = math.cos(math.rad(e.angle)) * SPEED
    missile.velocity.y = math.sin(math.rad(e.angle)) * SPEED
        
    UpdateEntity(missile)
end

function Draw()
    ClearScreen(68, 136, 204)
    DrawEntity(missile)
    DrawText("wobble: " .. missile.wobble, 8, 9, font, 255, 255, 255);
end