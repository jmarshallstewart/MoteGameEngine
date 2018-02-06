------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------

controller_0_button_0 = 0
controller_0_button_1 = 0
controller_0_button_2 = 0
controller_0_button_3 = 0
controller_0_button_4 = 0
controller_0_button_5 = 0
controller_0_button_6 = 0
controller_0_button_7 = 0
controller_0_button_8 = 0
controller_0_button_9 = 0
controller_0_button_10 = 0

controller_0_hat = 0

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------


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

function Draw()
    ClearScreen(68, 136, 204)
    
    local spacing = 35
    local xOffset = 8
    local axisOffset = xOffset + 250
    local buttonOffset = xOffset
    local yOffset = 9
    
    DrawText("Axis 0: " .. controller_0_axis_0 / 32768, axisOffset, yOffset, font, 255, 255, 255);
    DrawText("Axis 1: " .. controller_0_axis_1 / 32768, axisOffset, yOffset + spacing, font, 255, 255, 255);
    DrawText("Axis 2: " .. controller_0_axis_2 / 32768, axisOffset, yOffset + spacing * 2, font, 255, 255, 255);
    DrawText("Axis 3: " .. controller_0_axis_3 / 32768, axisOffset, yOffset + spacing * 3, font, 255, 255, 255);
    DrawText("Axis 4: " .. controller_0_axis_4 / 32768, axisOffset, yOffset + spacing * 4, font, 255, 255, 255);
    DrawText("Axis 5: " .. controller_0_axis_5 / 32768, axisOffset, yOffset + spacing * 5, font, 255, 255, 255);
    
    DrawText("Button 0: " .. controller_0_button_0, buttonOffset, yOffset + spacing * 0, font, 255, 255, 255);
    DrawText("Button 1: " .. controller_0_button_1, buttonOffset, yOffset + spacing * 1, font, 255, 255, 255);
    DrawText("Button 2: " .. controller_0_button_2, buttonOffset, yOffset + spacing * 2, font, 255, 255, 255);
    DrawText("Button 3: " .. controller_0_button_3, buttonOffset, yOffset + spacing * 3, font, 255, 255, 255);
    DrawText("Button 4: " .. controller_0_button_4, buttonOffset, yOffset + spacing * 4, font, 255, 255, 255);
    DrawText("Button 5: " .. controller_0_button_5, buttonOffset, yOffset + spacing * 5, font, 255, 255, 255);
    DrawText("Button 6: " .. controller_0_button_6, buttonOffset, yOffset + spacing * 6, font, 255, 255, 255);
    DrawText("Button 7: " .. controller_0_button_7, buttonOffset, yOffset + spacing * 7, font, 255, 255, 255);
    DrawText("Button 8: " .. controller_0_button_8, buttonOffset, yOffset + spacing * 8, font, 255, 255, 255);
    DrawText("Button 9: " .. controller_0_button_9, buttonOffset, yOffset + spacing * 9, font, 255, 255, 255);
    DrawText("Button 10: " .. controller_0_button_10, buttonOffset, yOffset + spacing * 10, font, 255, 255, 255);
    
    DrawText("Hat: " .. controller_0_hat, buttonOffset, yOffset + spacing * 12, font, 255, 255, 255);
end