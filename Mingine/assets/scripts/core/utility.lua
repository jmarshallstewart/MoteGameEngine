function GetRandomColor()
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    local a = math.random(0, 255)
    return r, g, b, a
end

function BoolToString(value)
    if value == true then
        return "true"
    else
        return "false"
    end
end

-- t is the table to be cleared.
function ClearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end