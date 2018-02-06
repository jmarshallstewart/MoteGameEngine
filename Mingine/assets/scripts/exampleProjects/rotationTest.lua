SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, false)
    SetWindowTitle("Rotation Test")
    turret = {}
    turret.image = LoadImage("images/gme/bullet.png")
    turret.width = 32;
    turret.height = 32;
    turret.x = SCREEN_WIDTH / 2;
    turret.y = SCREEN_HEIGHT / 2;
    turret.angle = 0;
end

function Update()
    mouseX, mouseY = GetMousePosition()
    local x = 0
    local y = 0
    x, y = VectorTo(turret.x, turret.y, mouseX, mouseY)
    turret.angle = math.deg(math.atan(y, x))
end

function Draw()
    ClearScreen(68, 136, 204)
    SetDrawColor(34, 68, 102, 128)
    DrawLine(turret.x, turret.y, mouseX, mouseY)
    DrawImage(turret.image, turret.x - turret.width * 0.5, turret.y - turret.height * 0.5, turret.angle)
end