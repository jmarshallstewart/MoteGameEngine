--Instead of processing tmx at runtime, you can save the result of the export (the string produced by
--readTmx() is a valid lua script) and later do:
--dofile(assetDirectory .. "maps/someMap.lua")

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080
SCALE = 5
TILE_SIZE = 16
TILE_PIXEL_SIZE = TILE_SIZE * SCALE 
TEXT_STEP = 32
TEXT_START = 8
REVERT_TO_IDLE_DURATION = 2000

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------
currentMap = nil
textY = TEXT_START
timeElapsedSinceMove = 0

-- camera positioning
offsetX = 0  
offsetY = 0

tileAtlas = nil 
player = nil  

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------
function DrawMap(map)
    for layer = 1,#map.tiles do
        for i= 1,map.width * map.height do
            local x = (i - 1) % map.width * map.tileSize - offsetX * map.tileSize
            local y = math.floor((i - 1) / map.width) * map.tileSize - offsetY * map.tileSize
            x = x * SCALE
            y = y * SCALE
            if x < SCREEN_WIDTH and x >= 0 and y < SCREEN_HEIGHT and y >= 0 then
                local index = map.tiles[layer][i] - 1
                if index > 0 then
                    DrawImageFrame(tileAtlas, x, y, map.tileSize, map.tileSize, index, 0, SCALE)
                end
            end
        end
    end
end

function TryMove(rowMod, colMod)
    if IsWalkable(player.row + rowMod, player.col + colMod) then
        player.x = player.x + colMod * TILE_PIXEL_SIZE
        player.y = player.y + rowMod * TILE_PIXEL_SIZE
        player.row = player.row + rowMod
        player.col = player.col + colMod
    end
    
    timeElapsedSinceMove = 0
end

function UpdatePlayerMovement()
    if IsKeyPressed(SDL_SCANCODE_UP) then TryMove(-1, 0); player.currentAnimation = "north" end
    if IsKeyPressed(SDL_SCANCODE_DOWN) then TryMove(1, 0); player.currentAnimation = "south" end
    if IsKeyPressed(SDL_SCANCODE_LEFT) then TryMove(0, -1); player.currentAnimation = "west" end
    if IsKeyPressed(SDL_SCANCODE_RIGHT) then TryMove(0, 1); player.currentAnimation = "east" end
end

function LockPlayerToWorld()
    if player.x < 0.5 * TILE_PIXEL_SIZE then
        player.x = 0.5 * TILE_PIXEL_SIZE
    end
    
    if player.y < 0.5 * TILE_PIXEL_SIZE then
        player.y = 0.5 * TILE_PIXEL_SIZE
    end
    
    if player.x > currentMap.width * TILE_PIXEL_SIZE - 0.5 * TILE_PIXEL_SIZE then
        player.x = currentMap.width * TILE_PIXEL_SIZE - 0.5 * TILE_PIXEL_SIZE
    end
    
    if player.y > currentMap.height * TILE_PIXEL_SIZE - 0.5 * TILE_PIXEL_SIZE then
        player.y = currentMap.height * TILE_PIXEL_SIZE - 0.5 * TILE_PIXEL_SIZE
    end
end

function IsOnMap(row, col)
    return row >= 1 and col >= 1 and row <= currentMap.height and col <= currentMap.width
end

function IsWalkable(row, col)
    return IsOnMap(row, col) and currentMap.walkabilityGrid[col + row * currentMap.width + 1] == 1
end

function SetUpCharacterAnimations()
    player.currentAnimation = "idle"
    player.frame = 1
            
    player.animations = {}
    AddAnimationFrame(player, "north", 6)
    AddAnimationFrame(player, "north", 7)
    AddAnimationFrame(player, "south", 0)
    AddAnimationFrame(player, "south", 1)
    AddAnimationFrame(player, "east", 2)
    AddAnimationFrame(player, "east", 3)
    AddAnimationFrame(player, "west", 4)
    AddAnimationFrame(player, "west", 5) 
    AddAnimationFrame(player, "idle", 8)
    AddAnimationFrame(player, "idle", 9)      
end

function AddTextLine(s)
    DrawText(s, currentMap.width * TILE_PIXEL_SIZE + 16, textY, font, 255, 255, 255)
    textY = textY + TEXT_STEP
end

function AddColorTextLine(s, r, g, b)
    DrawText(s, currentMap.width * TILE_PIXEL_SIZE + 16, textY, font, r, g, b)
    textY = textY + TEXT_STEP
end

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, true)
    SetWindowTitle("Turn-Based RPG TMX Loader")
        
    font = LoadFont("fonts/8_bit_pusab.ttf", 18)  
    playerImage = LoadImage("images/samurai16.png")
    
    player = CreateEntity(playerImage, 1.5 * TILE_PIXEL_SIZE, 1.5 * TILE_PIXEL_SIZE, TILE_SIZE, TILE_SIZE)
    SetEntityScale(player, SCALE)
    player.row = 1
    player.col = 1
           
    LoadTmxFile(assetDirectory .. "maps/first.tmx")
    currentMap = map
    tileAtlas = LoadImage(currentMap.tileAtlas)

    SetUpCharacterAnimations()
end

function Update()
    UpdateEntity(player)
    UpdatePlayerMovement()
    LockPlayerToWorld()
    
    timeElapsedSinceMove = timeElapsedSinceMove + GetFrameTime()
    
    if timeElapsedSinceMove > REVERT_TO_IDLE_DURATION and player.currentAnimation ~= "idle" then
        player.currentAnimation = "idle"
        player.frame = 1
    end
end

function Draw()
    ClearScreen(0, 0, 0)
    DrawMap(currentMap)
    DrawEntity(player)
    
    textY = TEXT_START
    AddColorTextLine("Your Name", 0, 255, 0)
    AddColorTextLine("Level 2 Ranger", 0, 255, 0)
    AddColorTextLine("HP: 500/500", 0, 255, 0)
    AddColorTextLine("Mana: 200/200", 0, 255, 0)
    AddColorTextLine("Strength: 17", 0, 127, 255)
    AddColorTextLine("Defense: 14", 0, 127, 255)
    AddColorTextLine("Skill: 35%", 0, 127, 255)
    AddColorTextLine("Dodge: 14%", 0, 127, 255)
    AddColorTextLine("Crit: 2%", 0, 127, 255)
    AddColorTextLine("EXP: 16323\\18000", 255, 255, 0)
    AddColorTextLine("Gold: 123", 255, 255, 0)
    AddColorTextLine("Food: 52", 255, 255, 0)
    AddTextLine(string.format("Row: %i", player.row))
    AddTextLine(string.format("Col: %i", player.col))
    AddColorTextLine("Use arrow keys to move", 255, 0, 255)
end