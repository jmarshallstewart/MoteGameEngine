SPACING = 24
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    font = LoadImage("images/CodePage437.png")
end

function Update()
    if IsKeyDown(SDL_SCANCODE_SPACE) then
        Quit()
    end
end

function Draw()
    local x = 0
    local y = 0
    for i = 1,256 do
        DrawImageFrame(font, x, y, 9, 16, i - 1)
        x = x + SPACING
        if x > SCREEN_WIDTH - SPACING then
            x = 0
            y = y + SPACING
        end
    end
end