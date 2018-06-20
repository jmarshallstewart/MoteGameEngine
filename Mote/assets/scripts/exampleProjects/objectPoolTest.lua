------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

SPAWN_DELAY_MS = 30
MAX_ENTITIES = 1024

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------
function Spawn(e, params)
    local x = math.random(32, SCREEN_WIDTH - 32)
    local y = math.random(32, SCREEN_HEIGHT - 32)
    
    SetEntity(e, params.image, x, y, params.frameWidth, params.frameHeight)
    e.lifeTime = math.random(14000, 69900)
end

function UpdateTestEntity(e)
    e.angle = e.angle + GetFrameTime() / 10
    e.lifeTime = e.lifeTime - GetFrameTime()
end

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------

spawnTimer = 0.0

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Object Pool Test")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 20)
    
    spawnParams = {}
    spawnParams.image = LoadImage("images/gme/ship.png")
    spawnParams.frameWidth = 32
    spawnParams.frameHeight = 32
    
    entityPool = CreateObjectPool(MAX_ENTITIES, AllocEntity)
    entityPool.onGet = Spawn
    entityPool.onFree = ResetEntity
end

function Update()
    spawnTimer = spawnTimer + GetFrameTime()
    
    while spawnTimer >= SPAWN_DELAY_MS and entityPool.hasFree() do
        entityPool.get(spawnParams)
        spawnTimer = spawnTimer - SPAWN_DELAY_MS
    end
    
    entityPool.each(UpdateTestEntity)
    
    local length = #entityPool.activeList
    
    for i = length, 1, -1 do
        if entityPool.activeList[i].lifeTime <= 0 then
            entityPool.free(entityPool.activeList[i])
        end
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    entityPool.each(DrawEntity)
    DrawText("Num Objs: " .. #entityPool.objects, 8, 9, font, 127, 255, 64)
    DrawText("Num Free: " .. #entityPool.freeList, 8, 40, font, 127, 255, 64)
    DrawText("Num Active: " .. #entityPool.activeList, 8, 70, font, 127, 255, 64)
end