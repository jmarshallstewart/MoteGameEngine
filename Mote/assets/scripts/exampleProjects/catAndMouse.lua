SCREEN_WIDTH = 1600
SCREEN_HEIGHT = 900

READY_TO_SPAWN = 1
SPAWNED = 2
POST_CAPTURE = 3

MIN_SIZE = 16
MAX_SIZE = 128
MIN_RESPAWN_TIME = 800
MAX_RESPAWN_TIME = 3000

gameState = READY_TO_SPAWN
spawnTimer = 0
score = 0
boxes = {}

function Spawn()
    box = {}
    box.x = math.random(0, SCREEN_WIDTH - MAX_SIZE)
    box.y = math.random(0, SCREEN_HEIGHT - MAX_SIZE)
    box.w = math.random(MIN_SIZE, MAX_SIZE)
    box.h = math.random(MIN_SIZE, MAX_SIZE)
    box.r, box.g, box.b, box.a = GetRandomColor()
    box.outline_r, box.outline_g, box.outline_b, box.outline_a = GetRandomColor()

    boxes[#boxes + 1] = box
end

function UpdateSpawner()
    if gameState == READY_TO_SPAWN then
        Spawn()
        spawnTimer = MIN_RESPAWN_TIME + math.random() * (MAX_RESPAWN_TIME - MIN_RESPAWN_TIME)
        gameState = SPAWNED
    elseif gameState == SPAWNED then
        --do nothing
    elseif gameState == POST_CAPTURE then
        spawnTimer = spawnTimer - GetFrameTime()
        if spawnTimer <= 0 then
            gameState = READY_TO_SPAWN
        end
    else
        Log("No handler for this game state.")
    end
end

function UpdateClicks()
    local mouseX
    local mouseY
    mouseX, mouseY = GetMousePosition()
    
    if IsMouseButtonDown(1) then
        for i = #boxes, 1, -1 do
            local b = boxes[i]
            if IsPointInBox(mouseX, mouseY, b) then
                gameState = POST_CAPTURE
                score = score + 1
                table.remove(boxes, i)
            end
        end
    end
end

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Click the box to earn high score")
    font = LoadFont("fonts/8_bit_pusab.ttf", 24)
end

function Update()
    UpdateSpawner()
    UpdateClicks()
end

function Draw()
    ClearScreen(34, 68, 102)
    
    for k,v in pairs (boxes) do
        SetDrawColor(v.r, v.g, v.b, 0xff)
        FillRect(v.x, v.y, v.w, v.h)
        
        SetDrawColor(v.outline_r, v.outline_g, v.outline_b, 0xff)
        DrawRect(v.x, v.y, v.w, v.h)
    end
    
    DrawText("Score: " .. score, 8, 9, font, 255, 255, 255)
end

-- mods:
-- add sounds for appear and click
-- add music
-- add timer that removes shape if it is not clicked quickly enough
-- 