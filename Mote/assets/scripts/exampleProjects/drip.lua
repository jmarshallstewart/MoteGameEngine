-- CONSTANT GAME DATA
DROP_START_Y = -30
MAX_SPEED = 1.0
DROPS_PER_UPDATE = 7
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)

-- TRANSIENT GAME DATA
drops = {}
numDrops = 0
maxDrops = 3000

-- ASSETS
dropImage = LoadImage("images/drip.png")
font = LoadFont("fonts/Deutsch.ttf", 32)

-- FUNCTIONS
function ResetDrop(index)
    drops[index].x = math.random(0, SCREEN_WIDTH)
    drops[index].y = DROP_START_Y
    drops[index].speed = math.random() * MAX_SPEED + 1.0
end

function Start()
    SetWindowTitle("Drip")
end

function Update()
    if numDrops < maxDrops then
        for i = numDrops + 1, numDrops + DROPS_PER_UPDATE do
            drops[i] = {}
            ResetDrop(i)
            numDrops = numDrops + 1
            if numDrops >= maxDrops then
                break
            end
        end  
    end
    
    for i=1,numDrops do
        drops[i].y = drops[i].y + drops[i].speed
    end  
end

function Draw()
    ClearScreen(0)
    for i=1,numDrops do
        DrawImage(dropImage, drops[i].x, drops[i].y)
        
        if drops[i].y > SCREEN_HEIGHT then
            ResetDrop(i)
        end
    end 
    
    DrawText("Num Drops: " .. numDrops, 16, 16, font, 225, 128, 0)
end
