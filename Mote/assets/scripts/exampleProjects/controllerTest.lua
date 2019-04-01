------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Controller Test")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 20)
end

function Update()
end

--helper function to reduce redundancy among frequent DrawText() calls.
function ShowText(text, x, y)
	DrawText(text, x, y, font, 255, 255, 255);
end

function Draw()
    ClearScreen(68, 136, 204)
    
    local spacing = 35
    local xOffset = 8
    local axisOffset = xOffset + 350
    local buttonOffset = xOffset
    local yOffset = 9
	
	if IsControllerAttached(0) then
		for i = 0,5 do
			local axisValue = ReadControllerAxis(0, i)
			ShowText("Axis " .. i .. ": " .. string.format("%.3f", axisValue), axisOffset, yOffset + spacing * i)
		end
	
		for i = 0,9 do
			local isDown = ReadControllerButton(0, i)
			ShowText("Button " .. i .. ": " .. BoolToString(isDown), buttonOffset, yOffset + spacing * i)
		end		
		
		ShowText("Hat: " .. ReadControllerHat(0), buttonOffset, yOffset + spacing * 12)
    else
		ShowText("Please attach a controller for player 1.", xOffset, yOffset)
	end
end