--This sample is a work in progress. The space game example has
--a functioning menu flow that can serve as an example.

------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

titleText = "Start Screen"
hintText = "Press SPACE BAR to start"
    
titleTextLength = string.len(titleText)
hintTextLength = string.len(hintText)
    
bigFontSize = 120
fontSize = 20

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Game States Project")
        
    bigFont = LoadFont("fonts/8_bit_pusab.ttf", bigFontSize)
    font = LoadFont("fonts/8_bit_pusab.ttf", fontSize)
end

function Update()
    if IsKeyPressed(SDL_SCANCODE_SPACE) then
        --do file some other state.
    end
end

function Draw()
    ClearScreen(68, 136, 204)
    DrawText(titleText, (SCREEN_WIDTH / 2) - ((titleTextLength * bigFontSize) / 2), SCREEN_HEIGHT / 3, bigFont, 255, 255, 255);
    DrawText(hintText, (SCREEN_WIDTH / 2) - ((hintTextLength * fontSize) / 2), 900, font, 255, 255, 255);
end