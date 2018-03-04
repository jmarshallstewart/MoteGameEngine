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

-- returns true if table t has a value for the given key
--function Contains(t, key)
--    return t[key] ~= nil
--end

function Contains(t, value)
    for k,v in pairs(t) do
        if v == value then
            return true
        end
    end
    
    return false
end

function Pick(condition, trueReturnValue, falseReturnFalse)
    if condition == true then
        return trueReturnValue
    else
        return falseReturnFalse
    end
end

-- see: https://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
function IsFileReadable(fileName)
    local file = io.open(fileName, "r")
    if file ~= nil then
        io.close(file)
        return true
    else
        return false
    end
end