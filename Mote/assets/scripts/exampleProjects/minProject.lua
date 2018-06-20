-- This script is meant to be a minimal starting point for new Mote projects.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600


------------------------------------------------------------------------------
-- required Mote functions
------------------------------------------------------------------------------

-- called once, at the start of the game
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Minimal Mote Project")
end

-- called at a fixed interval (16 ms) to update the state of the game world.
function Update()
end

-- called for each new frame drawn to the screen.
function Draw()
    ClearScreen(68, 136, 204)
end