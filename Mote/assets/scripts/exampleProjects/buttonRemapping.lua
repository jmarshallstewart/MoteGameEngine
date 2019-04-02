-- This script demonstrates button remapping. The player character in this
-- game can do four things: jump, shoot, crouch, and run. By pressing start,
-- the player is taken to a screen where they can assign which face buttons go
-- with which action.

-- This example assumes controllers with XINPUT aka XBOX 360 button mappings.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------

--game modes
MODE_PLAY = 0
MODE_INPUT_CONFIG = 1

--player states
STATE_WALKING = 0
STATE_RUNNING = 1
STATE_CROUCHING = 2
STATE_JUMPING = 3

--bullet tweaks
BULLET_SCALE = 4.0
BULLET_SPEED = 10
SHOTS_PER_SECOND = 8
MS_PER_SHOT = 1000 / SHOTS_PER_SECOND

--movement tweaks
CROUCH_SPEED_MULTIPLIER = 0.1
RUN_SPEED_MULTIPLIER = 3.0

--hardware constants
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
NUM_CONFIGURABLE_BUTTONS = 4
START_BUTTON_ID = 7

------------------------------------------------------------------------------
-- global data
------------------------------------------------------------------------------

--ux management state
gameMode = MODE_PLAY
startWasPressed = false
selectionChanged = false
buttonChanged = false
buttonConfigSelectedOption = 0

--container for images
images = {}

--fire management state
fireDirection = 1
fireTimer = 0
bullets = {}

--action request state
requests = {}
requests.fire = false
requests.run = false
requests.crouch = false
requests.jump = false

------------------------------------------------------------------------------
-- commands
------------------------------------------------------------------------------

doFire = {}
function doFire.execute()
    requests.fire = true
end

doRun = {}
function doRun.execute()
    requests.run = true
end

doCrouch = {}
function doCrouch.execute()
    requests.crouch = true
end

doJump = {}
function doJump.execute()
    requests.jump = true
end

commands = {}
commands[0] = doJump
commands[1] = doFire
commands[2] = doCrouch
commands[3] = doRun

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------

function ReadPlayerInput()
    for i = 0, NUM_CONFIGURABLE_BUTTONS - 1 do
        if ReadControllerButton(0, i) then
            commands[i].execute()
        end
    end
end

function FindButton(command)
    for i = 0, NUM_CONFIGURABLE_BUTTONS - 1 do
        if commands[i] == command then
            return i
        end
    end
    
    --provides visual cue in button config
    --menu that a command is not mapped.
    return -1
end

--toggle between game and config menu when START button pressed.
--(but ignore multiple requests to toggle until START button has been released.)
function UpdatePause()
    local startPressed = ReadControllerButton(0, START_BUTTON_ID)
    if not startWasPressed and startPressed then
        if gameMode == MODE_PLAY then gameMode = MODE_INPUT_CONFIG
        elseif gameMode == MODE_INPUT_CONFIG then gameMode = MODE_PLAY end
    end
    
    startWasPressed = startPressed
end

--Load fonts and images used in this example.
function LoadAssets()
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    bigFont = LoadFont("fonts/8_bit_pusab.ttf", 64)
    
    images.idle = LoadImage("images/tiles32/idle.png")
    images.left = LoadImage("images/tiles32/left.png")
    images.right = LoadImage("images/tiles32/right.png")
    images.crouch = LoadImage("images/tiles32/crouch.png")
    images.ground = LoadImage("images/tiles32/ground.png")
    images.fireball = LoadImage("images/tiles32/fireball.png")
end

--add a new bullet to the world, originating from the player.
function Fire()
    fireTimer = fireTimer + MS_PER_SHOT
    
    bullet = {}
    bullet.image = images.fireball
    --adjust for size of player and size of bullet
    bullet.x = player.x + TILE_SIZE / 2 - GetImageWidth(bullet.image) / 2
    bullet.y = player.y + TILE_SIZE / 4 - GetImageHeight(bullet.image) / 2
    bullet.xVel = BULLET_SPEED * fireDirection
    
    bullets[#bullets + 1] = bullet
end

function UpdateBullets()
    if fireTimer > 0 then
        fireTimer = fireTimer - GetFrameTime()
        if fireTimer < 0 then
            fireTimer = 0
        end
    end
                
    --move all bullets, and destroy bullets that have left the screen.          
    for i = #bullets, 1, -1 do
        bullets[i].x = bullets[i].x + bullets[i].xVel
        
        local w = GetImageWidth(bullets[i].image)
        local h = GetImageHeight(bullets[i].image)
        
        if     bullets[i].x > SCREEN_WIDTH + w 
            or bullets[i].x < -w
            or bullets[i].y > SCREEN_HEIGHT + h
            or bullets[i].y < -h then
            table.remove(bullets, i)
        end
    end
end

function InitPlayer()
    player = {}
    player.state = STATE_WALKING
    player.x = SCREEN_WIDTH / 2 - TILE_SIZE / 2
    player.y = GROUND_HEIGHT - TILE_SIZE
    player.xVel = 0
    player.yVel = 0
    player.xAcc = 0
    player.yAcc = 0
    player.speed = 1
    player.maxSpeed = 8
    player.drag = 0.85 
    player.jumpImpulse = 25
    player.gravity = 0.05
end

--only switch fire directions if player moves
function UpdatePlayerFireDirection()
    if math.abs(player.xVel) > 0 then
        if player.xVel < 0 then
            fireDirection = -1
        else
            fireDirection = 1
        end
    end
end

--handles moving and jumping for the player
function UpdatePlayerMovement()
    if requests.jump and player.state ~= STATE_JUMPING then
        player.yVel = -player.jumpImpulse
        player.state = STATE_JUMPING
    end

    local axis0 = GetInputX(0)
    
    if math.abs(axis0) > 0 then
        player.xAcc = player.speed
        
        if axis0 < 0 then
            player.xAcc = -player.xAcc
        end
        
        if player.state == STATE_RUNNING then
            player.xAcc = player.xAcc * RUN_SPEED_MULTIPLIER
        end
    else
        player.xAcc = 0
    end
    
    if player.state == STATE_JUMPING then
        player.yAcc = player.yAcc - player.gravity
    end
    
    player.xVel = player.xVel + player.xAcc
    player.yVel = player.yVel - player.yAcc
        
    -- remove very small x velocities
    if math.abs(player.xVel) < 0.2 then
        player.xVel = 0
    end
      
    --update player's position based on their velocity
    player.x = player.x + player.xVel
    player.y = player.y + player.yVel
   
    -- adjust speed for crouching and running players.
    local maxSpeed = player.maxSpeed
    
    if player.state == STATE_CROUCHING then
        maxSpeed = maxSpeed * CROUCH_SPEED_MULTIPLIER
    elseif player.state == STATE_RUNNING then
        maxSpeed = maxSpeed * RUN_SPEED_MULTIPLIER
    end
    
    -- clamp max x velocity
    if player.xVel > maxSpeed then
        player.xVel = maxSpeed
    elseif player.xVel < -maxSpeed then
        player.xVel = -maxSpeed
    end
   
    -- apply drag
    player.xVel = player.xVel * player.drag
    
    -- lock player to world
    if player.x < 0 then
        player.x = 0
        player.xVel = 0
    end
    
    if player.x > SCREEN_WIDTH - TILE_SIZE then
        player.x = SCREEN_WIDTH - TILE_SIZE
        player.xVel = 0
    end
    
    --check for jumping players that have landed on the ground.
    if player.y > GROUND_HEIGHT - TILE_SIZE then
        player.y = GROUND_HEIGHT - TILE_SIZE
        player.yVel = 0
        player.yAcc = 0
        player.state = STATE_WALKING
    end
end

--update running and crouching
function UpdateLocomotionState()
    if player.state ~= STATE_JUMPING and requests.run then
        player.state = STATE_RUNNING
    end
    
    if player.state == STATE_RUNNING and not requests.run then
        player.state = STATE_WALKING
    end
    
    if player.state ~= STATE_JUMPING and requests.crouch then
        player.state = STATE_CROUCHING
    end
    
    if player.state == STATE_CROUCHING and not requests.crouch then
        player.state = STATE_WALKING
    end
end

--reset all requests. Player input may
--set some of these to true during the next Update()
function ClearActionRequests()
    requests.fire = false
    requests.run = false
    requests.crouch = false
    requests.jump = false
end

function UpdatePlayer()
    ReadPlayerInput()
    UpdatePlayerFireDirection()
    UpdatePlayerMovement()
    UpdateLocomotionState()
        
    --updating firing
    if fireTimer == 0 and requests.fire then
        Fire()
    end
    
    ClearActionRequests()
end

function DrawHud()
    if not IsControllerAttached(0) then
        DrawText("Please attach a controller.", 16, 16, font, 255, 255, 255)
    else
        DrawText("Press start to configure controls.", 16, 16, font, 255, 255, 255)
    end
end

function DrawBullets()
    for i = 1, #bullets do
        DrawImage(bullets[i].image, bullets[i].x, bullets[i].y, 0, BULLET_SCALE)
    end
end

function DrawPlayer()
    local playerImage = nil
    
    if player.state == STATE_CROUCHING then
        playerImage = images.crouch
    elseif player.state == STATE_RUNNING then
        if player.xVel == 0 then
            playerImage = images.idle
        elseif player.xVel > 0 then
            playerImage = images.right
        else
            playerImage = images.left
        end
    else
        playerImage = images.idle
    end
    
    DrawImage(playerImage, player.x, player.y)
end

function DrawGround()
    local x = 0
    while x < SCREEN_WIDTH do
        DrawImage(images.ground, x, GROUND_HEIGHT)
        x = x + TILE_SIZE
    end
end

--handles input for the button config menu.
--user can select the action (fire, jump, etc.) by pressing up or down.
--pressing a face button (or whatever is mapped to 0-N on the controller) will 
--  assign the selected action to that button.
function UpdateButtonMapper()
    --change selected action in menu if user presses up or down
    local inputY = GetInputY(0)
    
    if not selectionChanged then
        if inputY < 0 then
            buttonConfigSelectedOption = buttonConfigSelectedOption - 1
        elseif inputY > 0 then
            buttonConfigSelectedOption = buttonConfigSelectedOption + 1
        end
        
        --wrap list
        if buttonConfigSelectedOption >= NUM_CONFIGURABLE_BUTTONS then
            buttonConfigSelectedOption = 0
        elseif buttonConfigSelectedOption < 0 then
            buttonConfigSelectedOption = NUM_CONFIGURABLE_BUTTONS - 1
        end
    end
    
    selectionChanged = math.abs(inputY) > 0
    
    -- if user presses a (debounced) face button, assign the
    -- currently selected action to that button.
    if not buttonChanged then
        for i = 0, 3 do
            if ReadControllerButton(0, i) then
                local handler = nil
                --this happens to be the order of the actions in the menu
                if buttonConfigSelectedOption == 0 then handler = doFire
                elseif buttonConfigSelectedOption == 1 then handler = doJump
                elseif buttonConfigSelectedOption == 2 then handler = doRun
                elseif buttonConfigSelectedOption == 3 then handler = doCrouch end
                
                local oldButton = FindButton(handler)
                local oldHandler = commands[i]
                
                --early out if button is trying to swap with itself.
                if i == oldButton then break end
                
                --swap button handlers
                commands[i] = handler
                commands[oldButton] = oldHandler
                
                buttonChanged = true
            end
        end
    else --must release all face buttons before user can reassign again
        local anyButtonPressed = false
        for i = 0, NUM_CONFIGURABLE_BUTTONS - 1 do
            if ReadControllerButton(0, i) then
                anyButtonPressed = true
            end
        end
        
        if not anyButtonPressed then
            buttonChanged = false
        end
    end
end

function DrawButtonMapper(x, y, leading)
    --instructions
    DrawText("Press a face button to assign the selected command.", 16, 16, font, 127, 127, 127)
    DrawText("Press Start to exit.", 16, 48, font, 127, 127, 127)
    
    --button mapper
    DrawText("Fire:   " .. FindButton(doFire), x, y + leading * 0, bigFont, 255, 255, 255)
    DrawText("Jump:   " .. FindButton(doJump), x, y + leading * 1, bigFont, 255, 255, 255)
    DrawText("Run:    " .. FindButton(doRun), x, y + leading * 2, bigFont, 255, 255, 255)
    DrawText("Crouch: " .. FindButton(doCrouch), x, y + leading * 3, bigFont, 255, 255, 255)
    
    --highlight selected option
    local rectX = x
    local rectY = y + leading * buttonConfigSelectedOption
    local rectW = 530
    local rectH = 120
    
    SetDrawColor(255, 255, 128, 255)
    DrawRect(rectX, rectY, rectW, rectH)
    
    SetDrawColor(255, 255, 64, 64)
    FillRect(rectX, rectY, rectW, rectH)
end

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Button Remapping Demo")
    
    LoadAssets()
        
    TILE_SIZE = GetImageHeight(images.ground)
    GROUND_HEIGHT = SCREEN_HEIGHT - TILE_SIZE
    
    InitPlayer()
end

function Update()
    UpdatePause()
    
    if gameMode == MODE_PLAY then
        UpdateBullets()
        UpdatePlayer()
    elseif gameMode == MODE_INPUT_CONFIG then
        UpdateButtonMapper()
    end
end

function Draw()
    if gameMode == MODE_PLAY then
        ClearScreen(68, 136, 204)
        DrawHud()
        DrawBullets()   
        DrawPlayer()
        DrawGround()
    elseif gameMode == MODE_INPUT_CONFIG then
        ClearScreen(0, 0, 0)
        DrawButtonMapper(80, 96, 120)
    end
end