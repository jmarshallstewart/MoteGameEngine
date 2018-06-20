------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1600
SCREEN_HEIGHT = 900

SCALE = 7

LOGICAL_WIDTH = math.floor(1920 / SCALE)
LOGICAL_HEIGHT = math.floor(1080 / SCALE)

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, true)
    SetWindowTitle("Pixel Scale Test")
    
    SetDrawLogicalSize(LOGICAL_WIDTH, LOGICAL_HEIGHT)
end

function Update()
    --nothing
end

function Draw()
    SetDrawScale(SCALE, SCALE)

    for r = 0, LOGICAL_HEIGHT - 1 do
        for c = 0, LOGICAL_WIDTH - 1 do
            	local color_r = (255 - (c * c) - (r * r))
                local color_g = 0
                local color_b = (255 - (c * c) - (r * r))
                SetDrawColor(color_r, color_g, color_b, 255)
                DrawPoint(c, r)
        end
    end
end