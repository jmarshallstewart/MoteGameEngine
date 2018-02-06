------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

SCALE = 7

LOGICAL_WIDTH = math.floor(1920 / SCALE)
LOGICAL_HEIGHT = math.floor(1080 / SCALE)

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Pixel Scale Test")
    
    SetDrawLogicalSize(LOGICAL_WIDTH, LOGICAL_HEIGHT)
end

function Update()
    --nothing
end

function Draw()
    scaleX, scaleY = GetDrawScale()
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
    
    SetDrawScale(1, 1)
end