-- This script demonstrates button remapping. The player character in this
-- game can do four things: jump, shoot, crouch, and run. By pressing start,
-- the player is taken to a screen where they can assign which face buttons go
-- with which action.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------

--modes
MODE_PLAY = 0
MODE_INPUT_CONFIG = 1

--states
STATE_WALKING = 0
STATE_RUNNING = 1
STATE_CROUCHING = 2
STATE_JUMPING = 3

BULLET_SPEED = 10
SHOTS_PER_SECOND = 8
MS_PER_SHOT = 1000 / SHOTS_PER_SECOND

CROUCH_SPEED_MULTIPLIER = 0.1
RUN_SPEED_MULTIPLIER = 3.0

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

------------------------------------------------------------------------------
-- global data
------------------------------------------------------------------------------

gameMode = MODE_PLAY
images = {}

fireDirection = 1
fireTimer = 0
bullets = {}

requests = {}
requests.fire = false
requests.run = false
requests.crouch = false
requests.jump = false

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------

function LoadAssets()
	font = LoadFont("fonts/8_bit_pusab.ttf", 16)
	
	images.idle = LoadImage("images/tiles32/idle.png")
	images.left = LoadImage("images/tiles32/left.png")
	images.right = LoadImage("images/tiles32/right.png")
	images.crouch = LoadImage("images/tiles32/crouch.png")
	images.ground = LoadImage("images/tiles32/ground.png")
	images.fireball = LoadImage("images/tiles32/fireball.png")
end

function Fire()
    fireTimer = fireTimer + MS_PER_SHOT
    
    bullet = {}
	bullet.image = images.fireball
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
	    		
    for i = #bullets, 1, -1 do
        bullets[i].x = bullets[i].x + bullets[i].xVel
		
		local w = GetImageWidth(bullets[i].image)
		local h = GetImageHeight(bullets[i].image)
		
        if bullets[i].x > SCREEN_WIDTH + w then
            table.remove(bullets, i)
		elseif bullets[i].x < -w then
			table.remove(bullets, i)
		elseif bullets[i].y > SCREEN_HEIGHT + h then
            table.remove(bullets, i)
		elseif bullets[i].y < -h then
			table.remove(bullets, i)
        end
    end
end

function InitPlayer()
	player = {}
	player.state = STATE_WALKING
    player.image = images.idle
    player.x = SCREEN_WIDTH / 2 - GetImageWidth(images.idle) / 2
    player.y = GROUND_HEIGHT - GetImageHeight(images.idle)
    player.xVel = 0
    player.yVel = 0
    player.xAcc = 0
    player.yAcc = 0
    player.speed = 1
    player.maxSpeed = 8
    player.drag = 0.85 
    player.jumpImpulse = 45
    player.gravity = 0.5
end

function UpdatePlayer()
	requests.jump = ReadControllerButton(0, 0)
	requests.fire = ReadControllerButton(0, 1)
	requests.crouch = ReadControllerButton(0, 2)
	requests.run = ReadControllerButton(0, 3)

	--only switch fire directions if player moves
	if math.abs(player.xVel) > 0 then
		if player.xVel < 0 then
			fireDirection = -1
		else
			fireDirection = 1
		end
	end
	
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
      
    player.x = player.x + player.xVel
    player.y = player.y + player.yVel
   
    -- clamp max x velocity
	local maxSpeed = player.maxSpeed
	
	if player.state == STATE_CROUCHING then
		maxSpeed = maxSpeed * CROUCH_SPEED_MULTIPLIER
	elseif player.state == STATE_RUNNING then
		maxSpeed = maxSpeed * RUN_SPEED_MULTIPLIER
	end
	
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
    
    if player.y > GROUND_HEIGHT - TILE_SIZE then
        player.y = GROUND_HEIGHT - TILE_SIZE
        player.yVel = 0
        player.yAcc = 0
        player.state = STATE_WALKING
    end
	
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
	
	if fireTimer == 0 and requests.fire then
        Fire()
    end
	
	--clear input signals
	requests.fire = false
	requests.run = false
	requests.crouch = false
	requests.jump = false
end

function DrawHud()
	--draw controller warning (optional)
	if not IsControllerAttached(0) then
		DrawText("Please attach a controller.", 16, 16, font, 255, 255, 255)
	else
		DrawText("Press start to configure controls.", 16, 16, font, 255, 255, 255)
	end
end

function DrawBullets()
	for i = 1, #bullets do
		DrawImage(bullets[i].image, bullets[i].x, bullets[i].y, 0, 4.0)
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
	UpdateBullets()
	UpdatePlayer()
end

function Draw()
	ClearScreen(68, 136, 204)
	DrawHud()
	DrawBullets()	
	DrawPlayer()
	DrawGround()
end