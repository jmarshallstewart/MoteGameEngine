------------------------------------------------------------------------------
-- includes
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 96
BAR_X = 16
BAR_Y = 16
BAR_WIDTH = 992
BAR_HEIGHT = 64

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------
timeToComplete = 7 * 1000
timer = 0

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Progress Bar Example")
end

function Update()
    timer = timer + GetFrameTime()
    
    --reset bar when the space key is pressed.
    if IsKeyPressed(SDL_SCANCODE_SPACE) then
        timer = 0
    end
end

function Draw()
    ClearScreen(5, 5, 5)
    
    local complete = math.min(timer / timeToComplete, 1)
    
    --background
    SetDrawColor(127, 127, 127, 255)
    FillRect(BAR_X, BAR_Y, BAR_WIDTH, BAR_HEIGHT)
    
    --foreground
    SetDrawColor(255, 64, 127, 255)
    FillRect(BAR_X, BAR_Y, BAR_WIDTH * complete, BAR_HEIGHT)
end