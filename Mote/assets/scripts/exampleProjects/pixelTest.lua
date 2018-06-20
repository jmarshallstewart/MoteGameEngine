------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

CIRCLE_RADIUS = 20.0

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, false)
    SetWindowTitle("Pixel Test")
end

function Update()
    --nothing
end

function Draw()
    --background
    for r = 0, SCREEN_HEIGHT - 1 do
        for c = 0, SCREEN_WIDTH - 1 do
            local color_r = (255 - (c * c) - (r * r))
            local color_g = 0
            local color_b = 0
            SetDrawColor(color_r, color_g, color_b, 255)
            DrawPoint(c, r)
            
            --circle
            local dx = c - SCREEN_WIDTH / 2
            local dy = r - SCREEN_HEIGHT / 2
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= CIRCLE_RADIUS then
                if (r + c) % 2 == 0 then
                    SetDrawColor(255, 255, 255, 255)
                    DrawPoint(c, r)
                end
            end
        end
    end
end