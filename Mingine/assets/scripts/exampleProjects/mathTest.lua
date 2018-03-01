-- this script is something like a unit test of various math
-- functions. As new math functions are added to gameMath.lua,
-- tests can be added here.
--
-- @TODO: tests for all functions
-- @TODO: add an assert or other pass/fail mechanism for automatic testing.
--
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Math Test")
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    x = Clamp(50, 0, 100)
    y = Clamp(-67, 50, 250)
    z = Clamp(33, 2, 20)
end

function Update()
    -- nothing
end

function Draw()
    ClearScreen(68, 136, 204)
    DrawText("x: " .. x .. " y: " .. y .. " z: " .. z, 8, 9, font, 255, 255, 255)
end