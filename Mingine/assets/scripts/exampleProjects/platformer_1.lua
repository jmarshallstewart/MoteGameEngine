-- This projects ports the excellent tutorial found here to mingine:
--
-- https://codeincomplete.com/posts/tiny-platformer/
--
-- This tutorial is well worth reading. Though it is written in ActionScript,
-- the concepts are portable to any development environment used for making games.
--
-- This project loads a tmx file, but only uses the first layer.
--
-- This project does not rely on the mingine entity system, and instead it
-- implements a separate physics sim more amenable to platforming gameplay.
--
-- The player keeps a redundant copy of tuning constants so that UpdateActor()
-- can be written in anticipation of adding different types of actors later that
-- may have different tuning values so that they behave differently from the player.


--tuning parameters for player input

GRAVITY = 1.2
MAX_SPEED = { x = 3.4375, y = 6.3 }
LINEAR_ACCELERATION = 0.625 -- how fast the player accelerates when walking
FRICTION = 2 
JUMP_IMPULSE = 25
FALLING_FRICTION_SCALE = 0.5
FALLING_ACCELERATION_SCALE = 0.5
SETTLE_TOLERANCE = 0.11 -- higher number indicates max penetration for player to snap to grid when coming to a stop.


-- helper functions

function getCell(x, y)
    return map.tiles[1][(x + (y * map.width)) + 1] -- +1 because of lua array indexing
end

function SetActor(actor, x, y)
    actor.x = x
    actor.y = y
    actor.left = false
    actor.right = false
    actor.jump = false
    actor.jumping = false
    actor.falling = false
    actor.velocity = { x = 0, y = 0 }
    actor.acceleration = { x = 0, y = 0 }
    actor.friction = FRICTION
    actor.linearAcceleration = LINEAR_ACCELERATION
    actor.maxVelocityX = MAX_SPEED.x
    actor.maxVelocityY = MAX_SPEED.y
    actor.jumpImpulse =  JUMP_IMPULSE
end

function UpdatePlayerInput()
    player.left = false
    player.right = false
    player.jump = false

    if IsKeyDown(SDL_SCANCODE_LEFT) then player.left = true end
    if IsKeyDown(SDL_SCANCODE_RIGHT) then player.right = true end
    if IsKeyDown(SDL_SCANCODE_SPACE) then player.jump = true end
end

function UpdateActor(actor)
    local wasLeft = actor.velocity.x < 0
    local wasRight = actor.velocity.x > 0
    local falling = actor.falling
              
    local friction = actor.friction * Pick(falling, FALLING_FRICTION_SCALE, 1.0)
    local acceleration = actor.linearAcceleration * Pick(falling, FALLING_ACCELERATION_SCALE, 1.0)
    
    actor.acceleration.x = 0
    actor.acceleration.y = GRAVITY
    
    if actor.left then actor.acceleration.x = actor.acceleration.x - acceleration
    elseif wasLeft then actor.acceleration.x = actor.acceleration.x + friction end
    
    if actor.right then actor.acceleration.x = actor.acceleration.x + acceleration
    elseif wasRight then actor.acceleration.x = actor.acceleration.x - friction end
    
    --start jumping?
    if actor.jump and not actor.jumping and not falling then
        actor.acceleration.y = actor.acceleration.y - actor.jumpImpulse
        actor.jumping = true
    end
    
    local dt = GetFrameTime() / 100.0
    
    actor.x = actor.x + actor.velocity.x * dt
    actor.y = actor.y + actor.velocity.y * dt
    actor.velocity.x = Clamp(actor.velocity.x + actor.acceleration.x * dt, -actor.maxVelocityX, actor.maxVelocityX)
    actor.velocity.y = Clamp(actor.velocity.y + actor.acceleration.y * dt, -actor.maxVelocityY, actor.maxVelocityY)
    
    --clamp x velocity to prevent jiggle when changing directions
    if (wasLeft and actor.velocity.x > 0) or (wasRight and actor.velocity.x < 0) then 
        actor.velocity.x = 0
    end
    
    local tileX = math.floor(actor.x)
    local tileY = math.floor(actor.y) 
    
    -- how deeply are we penetrating other tiles?
    nx = math.fmod(actor.x, 1)
    ny = math.fmod(actor.y, 1)
    
    local cell = getCell(tileX, tileY)
    local cellRight = getCell(tileX + 1, tileY)
    local cellDown = getCell(tileX, tileY + 1)
    local cellDiag = getCell(tileX + 1, tileY + 1)
    
    if Contains(map.walkable, cell) then cell = nil end
    if Contains(map.walkable, cellRight) then cellRight = nil end
    if Contains(map.walkable, cellDown) then cellDown = nil end
    if Contains(map.walkable, cellDiag) then cellDiag = nil end
            
    if actor.velocity.y > 0 then
        if (cellDown and not cell) or (cellDiag and not cellRight and nx > 0) then
            actor.y = tileY
            actor.velocity.y = 0
            actor.falling = false
            actor.jumping = false
            ny = 0
        end
    elseif actor.velocity.y < 0 then
        if (cell and not cellDown) or (cellRight and not cellDiag and nx > 0) then
            actor.y = tileY + 1
            actor.velocity.y = 0
            cell = cellDown
            cellRight = cellDiag
            ny = 0
        end
    end
    
    if actor.velocity.x > 0 then
        if (cellRight and not cell) or (cellDiag and not cellDown and ny > 0) then
            actor.x = tileX
            actor.velocity.x = 0
        end
    elseif actor.velocity.x < 0 then
        if (cell and not cellRight) or (cellDown and not cellDiag and ny > 0) then
            actor.x = tileX + 1
            actor.velocity.x = 0
        end
    end
       
    actor.falling = not (cellDown or (nx > 0 and cellDiag))
    
    -- let the actor tend to settle aligned to the grid so that it can fit through one-tile holes.
    if actor.velocity.x == 0 and actor.velocity.y == 0 and math.fmod(actor.x, 1) < SETTLE_TOLERANCE then
        actor.x = math.floor(actor.x)
    end
end

function DrawWorld()
    for y = 0, map.height - 1 do
        for x = 0, map.width - 1 do
            local tileImageIndex = map.tiles[1][(x + y * map.width) + 1]
            DrawImageFrame(tileImage, x * map.tileSize, y * map.tileSize, map.tileSize, map.tileSize, tileImageIndex - 1, 0, 1)
        end
    end
end

function DrawPlayer()
    SetDrawColor(255, 255, 255, 255)
    FillRect(player.x * map.tileSize, player.y * map.tileSize, map.tileSize, map.tileSize)
end

-- core functions

function Start()
    LoadTmxFile(assetDirectory .. "maps/platformer.tmx")
    
    -- This example can handle maps with different tile sizes. For example, comment out the previous LoadTmxFile() call and uncomment this:
    -- LoadTmxFile(assetDirectory .. "maps/platformer32.tmx")
    
    map.walkable = {1, 2} --indices of tiles that the player and other actors can walk through.
    
    CreateWindow(map.width * map.tileSize, map.height * map.tileSize)
    SetWindowTitle("Platformer")
    
    tileImage = LoadImage(map.tileAtlas)
    player = {}
    SetActor(player, 10, 22)
end

function Update()
    UpdatePlayerInput()
    UpdateActor(player)
end

function Draw()
    DrawWorld()
    DrawPlayer()
end