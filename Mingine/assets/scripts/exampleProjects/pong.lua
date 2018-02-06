-- CONSTANT GAME DATA
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)

PADDLE_WIDTH = 30
PADDLE_HEIGHT = 90
BALL_WIDTH = 20
BALL_HEIGHT = 20
BALL_MAX_SPEED = 10

PLAYER_PADDLE_X = PADDLE_WIDTH
ENEMY_PADDLE_X = SCREEN_WIDTH - PADDLE_WIDTH * 2

PLAYER_SPEED = 5
ENEMY_SPEED = 3.5

-- TRANSIENT GAME DATA
playerScore = 0
aiScore = 0
ball = {}
playerPaddle = {}
aiPaddle = {}

-- ASSETS
backgroundImage = LoadImage("images/background.png")
playerPaddleImage = LoadImage("images/playerPaddle.png")
aiPaddleImage = LoadImage("images/enemyPaddle.png")
ballImage = LoadImage("images/ball.png")

scoreFont = LoadFont("fonts/8_bit_pusab.ttf", 24)

ballBounceSound = LoadSound("sfx/bounce.wav")
ballSpawnSound = LoadSound("sfx/spawn.wav")
playerScoreSound = LoadSound("sfx/happy.wav")
aiScoreSound = LoadSound("sfx/sad.wav")

music = LoadMusic("music/level1.ogg")

function ResetGame()
	--Position the player's paddle
	playerPaddle.x = PLAYER_PADDLE_X
	playerPaddle.y = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2
	playerPaddle.w = PADDLE_WIDTH
	playerPaddle.h = PADDLE_HEIGHT

	--Position the enemie's paddle
	aiPaddle.x = ENEMY_PADDLE_X
	aiPaddle.y = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2
	aiPaddle.w = PADDLE_WIDTH
	aiPaddle.h = PADDLE_HEIGHT

	--Position the ball
	ball.x = SCREEN_WIDTH / 2 - BALL_WIDTH / 2
	ball.y = SCREEN_HEIGHT / 2 - BALL_HEIGHT / 2
	ball.w = BALL_WIDTH
	ball.h = BALL_HEIGHT

	--Make the ball X velocity a random value from 1 to BALL_MAX_SPEED
	ball.xVel = math.random(0, 32768) % BALL_MAX_SPEED + 1

	--Make the ball Y velocity a random value from -BALL_MAX_SPEED to BALL_MAX_SPEED
	ball.yVel = (math.random(0, 32768) % BALL_MAX_SPEED * 2 + 1) - BALL_MAX_SPEED

	--Give it a 50% probability of going toward's the player
	if math.random() >= 0.5 then ball.xVel = ball.xVel * -1 end

	--Play the spawn sound
	PlaySound(ballSpawnSound)
end

function UpdatePlayer()
	--Move the paddle when the up/down key is pressed
	if IsKeyDown(SDL_SCANCODE_UP) then
        playerPaddle.y = playerPaddle.y - PLAYER_SPEED
    end
    
    if IsKeyDown(SDL_SCANCODE_DOWN) then
        playerPaddle.y = playerPaddle.y + PLAYER_SPEED
    end
	
	--Make sure the paddle doesn't leave the screen
	if playerPaddle.y < 0 then
		playerPaddle.y = 0
    end

	if playerPaddle.y > SCREEN_HEIGHT - playerPaddle.h then
		playerPaddle.y = SCREEN_HEIGHT - playerPaddle.h
    end
end

function UpdateAI()
	--If the paddle's center higher than the ball's center, move the paddle up
	if (aiPaddle.y + aiPaddle.h / 2) > (ball.y + ball.h / 2) then aiPaddle.y = aiPaddle.y - ENEMY_SPEED end

	--If the paddle's center lower than the ball's center, move the paddle down
	if (aiPaddle.y + aiPaddle.h / 2) < (ball.y + ball.h / 2) then aiPaddle.y = aiPaddle.y + ENEMY_SPEED end

	--Make sure the paddle doesn't leave the screen
	if (aiPaddle.y < 0) then aiPaddle.y = 0 end 

	if (aiPaddle.y > SCREEN_HEIGHT - aiPaddle.h) then aiPaddle.y = SCREEN_HEIGHT - aiPaddle.h end
end

function UpdateBall()
	ball.x = ball.x + ball.xVel
	ball.y = ball.y + ball.yVel

	--If the ball hits the player, make it bounce
	if BoxesOverlap(ball, playerPaddle) then
		ball.xVel = math.random(1, 32768) % BALL_MAX_SPEED + 1
        PlaySound(ballBounceSound)
	end

	--If the ball hits the enemy, make it bounce
	if BoxesOverlap(ball, aiPaddle) then
		ball.xVel = (math.random(1, 32768) % BALL_MAX_SPEED + 1) * -1
		PlaySound(ballBounceSound)
	end

	--Make sure the ball doesn't leave the screen and make it
	--bounce randomly
	if (ball.y < 0) then
		ball.y = 0
		ball.yVel = math.random(1, 32768) % BALL_MAX_SPEED + 1
		PlaySound(ballBounceSound)
	end

	if ball.y > SCREEN_HEIGHT - ball.h then
		ball.y = SCREEN_HEIGHT - ball.h
		ball.yVel = (math.random(1, 32768) % BALL_MAX_SPEED + 1)* -1
		PlaySound(ballBounceSound)
	end

	--If player scores
	if ball.x > SCREEN_WIDTH then
		playerScore = playerScore + 1
		PlaySound(playerScoreSound)
		ResetGame()
	end

	--If enemy scores
	if ball.x < 0 - ball.h then
		aiScore = aiScore + 1
		PlaySound(aiScoreSound)
		ResetGame()
	end
end

function Start()
    SetWindowTitle("Table Tennis")
    math.randomseed( os.time() )
    ResetGame()
    PlayMusic(music)
end

function Update()
	UpdatePlayer()
	UpdateAI()
	UpdateBall()
end

function Draw()
    DrawImage(backgroundImage, 0, 0)
    DrawImage(ballImage, ball.x, ball.y)
    DrawImage(playerPaddleImage, playerPaddle.x, playerPaddle.y)
    DrawImage(aiPaddleImage, aiPaddle.x, aiPaddle.y)
    
    DrawText("Player Score: " .. playerScore, 8, 7, scoreFont, 255, 255, 255);
	DrawText("Enemy Score: " .. aiScore, 8, 36, scoreFont, 255, 255, 255);
end
