dofile(assetDirectory .. "maps/bigMap.lua")

FRAME_DURATION_MS = 700
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

player = {}
player.x = 0
player.y = 0
player.frame = 0
player.animTimer = 0       

-- camera positioning
offsetX = 0  
offsetY = 0   

function DrawMap(map)
    for i=1,map.width * map.height do
        local x = (i - 1) % map.width * map.tileSize - offsetX * map.tileSize
        local y = math.floor((i - 1) / map.width) * map.tileSize - offsetY * map.tileSize
        if x < SCREEN_WIDTH and x >= 0 and y < SCREEN_HEIGHT and y >= 0 then
            DrawImageFrame(spriteSheet, x, y, map.tileSize, map.tileSize, map.tiles[i] - 1)
        end
    end
end

function ClampToWorld(map)
    -- clamp player position to world
    if player.x < 0 then player.x = 0 end
    if player.x > map.width - 1 then player.x = map.width - 1 end
    if player.y < 0 then player.y = 0 end
    if player.y > map.height - 1 then player.y = map.height - 1 end
    
    -- clamp offsets
    if player.x < (SCREEN_WIDTH / map.tileSize / 2) + 1 then offsetX = 0 end
    if player.x > map.width - math.floor(SCREEN_WIDTH / map.tileSize / 2) then offsetX = map.width - math.floor(SCREEN_WIDTH / map.tileSize) end 
    if player.y < (SCREEN_HEIGHT / map.tileSize / 2) + 1 then offsetY = 0 end
    if player.y > map.height - math.floor(SCREEN_HEIGHT / map.tileSize / 2) then offsetY = map.height - math.floor(SCREEN_HEIGHT / map.tileSize) end 
end
            
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, true)
    SetWindowTitle("Tiled Map Loader")
    
    spriteSheet = LoadImage(bigMap.spriteSheet)
    playerImage = LoadImage("images/dragon.png")
    font = LoadFont("fonts/Deutsch.ttf", 32)
end

function Update()
    -- update player animation
    player.animTimer = player.animTimer + GetFrameTime();
    
    if player.animTimer >= FRAME_DURATION_MS then
        player.animTimer = player.animTimer - FRAME_DURATION_MS
        if player.frame == 0 then player.frame = 1
        elseif player.frame == 1 then player.frame = 0 end
    end
    
    -- handle user input
    if IsKeyDown(SDL_SCANCODE_LEFT) then
        player.x = player.x - 1
        offsetX = offsetX - 1
    end
    
    if IsKeyDown(SDL_SCANCODE_RIGHT) then
        player.x = player.x + 1
        offsetX = offsetX + 1
    end
    
    if IsKeyDown(SDL_SCANCODE_UP) then
        player.y = player.y - 1
        offsetY = offsetY - 1
    end
    
    if IsKeyDown(SDL_SCANCODE_DOWN) then
        player.y = player.y + 1
        offsetY = offsetY + 1
    end
    
    -- keep player inside the bounds of the world
    ClampToWorld(bigMap)
end

function Draw()
    -- draw world
    DrawMap(bigMap)
    
    -- draw player
    local x = (player.x - offsetX) * bigMap.tileSize
    local y = (player.y - offsetY) * bigMap.tileSize
    DrawImageFrame(playerImage, x, y, bigMap.tileSize, bigMap.tileSize, player.frame)
    
    -- draw debug text
    local text = "x: " .. player.x .. " y: " .. player.y .. " offsetX: " .. offsetX .. " offsetY: " .. offsetY
    DrawText(text, 16, 16, font, 225, 128, 0)
end
