SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Loading a PNG image")
    light = LoadImage("images/background.png")
end

function Update()
    --nothing to do here.
end

function Draw()
    DrawImage(light, 0, 0)
end