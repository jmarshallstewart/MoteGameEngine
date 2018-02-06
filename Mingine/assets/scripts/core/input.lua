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

function getMoveInput()
    local x = GetInputX()
    local y = GetInputY()
    
    if x == 0 and y == 0 then
        return 0, 0
    end
    
    return Normalize(x, y)
end

function getLookInput()
    local x = controller_0_axis_3 / 32768
    local y = controller_0_axis_4 / 32768
    
    if x == 0 and y == 0 then
        return 0, 0
    end
    
    return Normalize(x, y)
end

function GetInputX()
    if IsKeyDown(SDL_SCANCODE_LEFT) or controller_0_hat == 8 then
        return -1.0
    elseif IsKeyDown(SDL_SCANCODE_RIGHT) or controller_0_hat == 2 then
        return 1.0
    elseif math.abs(controller_0_axis_0) > 0 then
        return controller_0_axis_0 / 32768
    else
        return 0.0
    end
end

function GetInputY()
    if IsKeyDown(SDL_SCANCODE_UP) or controller_0_hat == 1 then
        return -1.0
    elseif IsKeyDown(SDL_SCANCODE_DOWN) or controller_0_hat == 4 then
        return 1.0
    elseif math.abs(controller_0_axis_1) > 0 then
        return controller_0_axis_1 / 32768
    else
        return 0.0
    end
end