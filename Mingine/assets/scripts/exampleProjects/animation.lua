MAX_SPRITE_FRAME = 11
FRAME_DELAY = 1000 / 12
SCREEN_WIDTH = 512
SCREEN_HEIGHT = 512

backgroundX = 0
frame = 0
frameTimer = FRAME_DELAY
scale = 4
size = 64 --width and height of the actor image
half = (size/2 * scale)

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Animation Demo")
      
    actor = LoadImage("images/eris_anim.png")
    background = LoadImage("images/eris_background.png")
end

function Update()
    backgroundX = backgroundX - 6
    if backgroundX <= -SCREEN_WIDTH then backgroundX = backgroundX + SCREEN_WIDTH end
    
    frameTimer = frameTimer - GetFrameTime();
    
    if frameTimer <= 0 then
        frame = frame + 1
        if frame > MAX_SPRITE_FRAME then frame = 0 end
        frameTimer = frameTimer + FRAME_DELAY
    end
end

function Draw()
    ClearScreen(0, 0, 0)
    DrawImage(background, backgroundX, 0, 0, scale)
    DrawImage(background, backgroundX + SCREEN_WIDTH, 0, 0, scale)
    DrawImageFrame(actor, SCREEN_WIDTH / 2 - half, SCREEN_HEIGHT / 2 - half, size, size, frame, 0, scale)
end