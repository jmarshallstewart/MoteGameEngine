-- This script demonstrates how to create a scrolling background.

BACKGROUND_WIDTH = 128
BACKGROUND_HEIGHT = 128
SCROLL_SPEED = 1
SCALE = 3

function Start()
    CreateWindow(BACKGROUND_WIDTH * SCALE, BACKGROUND_HEIGHT * SCALE)
    SetWindowTitle("Scrolling Background")
		
	backgroundImage = LoadImage("images/eris_background.png")
	
	--starting positions of the two background pieces.
	--they will always have a y position of 0.
	x1 = 0
	x2 = BACKGROUND_WIDTH
end

function Update()
	x1 = x1 - SCROLL_SPEED
	if x1 <= -BACKGROUND_WIDTH then x1 = BACKGROUND_WIDTH end
	
	x2 = x2 - SCROLL_SPEED
	if x2 <= -BACKGROUND_WIDTH then x2 = BACKGROUND_WIDTH end
end

function Draw()
	--not needed for scrolling algorithm; just here to make the background larger.
	SetDrawScale(SCALE, SCALE)
	
    DrawImage(backgroundImage, x1, 0)
	DrawImage(backgroundImage, x2, 0)
end