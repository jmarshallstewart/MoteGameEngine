dofile(scriptDirectory .. "core/steering.lua")

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

ARRIVE_DISTANCE = 14
MAX_ACCELERATION = 1.0 -- how fast can the agent change direction and speed?

--when reading about A*, waypoints and links are nodes and edges.
waypoints = {}
links = {}

--user interface state
isLeftClickDragging = false
selectedWaypoint = nil

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Pathfinding Example")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    local image = LoadImage("images/arrow.png")
    agent = CreateEntity(image, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, 16)
    agent.maxSpeed = 8
    agent.path = {}
    agent.targetWaypoint = 1
end

function Update()

--[[
    --get the next waypoint along the path
    local next = path[targetWaypoint]

    --next waypoint on the path is our seek target. 
    --accelerate toward that.
    local x, y = Seek(agent, next.x, next.y)
    Set(agent.acceleration, x, y, MAX_ACCELERATION)
            
    --the angle of our sprite should match its own velocity    
    TurnTo(agent, agent.velocity)
    UpdateEntity(agent)
    
    --if agent is close enough to the current waypoint, set the next 
    --waypoint as the new target (wrapping back to the first waypoint if needed)
    if Distance(agent.x, agent.y, next.x, next.y) <= ARRIVE_DISTANCE then
        targetWaypoint = targetWaypoint + 1
        if targetWaypoint > #path then
            targetWaypoint = 1
        end
    end
    ]]--
    
    mouseX, mouseY = GetMousePosition()
        
    -- left click
    if IsMouseButtonDown(1) then
        for i = 1, #waypoints do
            if IsPointInCircle(mouseX, mouseY, waypoints[i].x, waypoints[i].y, ARRIVE_DISTANCE) then
                if not isLeftClickDragging then
                    isLeftClickDragging = true
                    startDragWaypoint = i
                end
                return
            end
        end
        
        if not isLeftClickDragging then
            local waypoint = {}
            waypoint.x = mouseX
            waypoint.y = mouseY
            waypoints[#waypoints + 1] = waypoint
        end
    elseif isLeftClickDragging then
        isLeftClickDragging = false
        for i = 1, #waypoints do
            if IsPointInCircle(mouseX, mouseY, waypoints[i].x, waypoints[i].y, ARRIVE_DISTANCE) then
                if i ~= startDragWaypoint then
                    for j = 1, #links do
                        if (links[j].start == startDragWaypoint and links[j].finish == i) or (links[j].start == i and links[j].finish == startDragWaypoint) then
                            table.remove(links, j)
                            return
                        end
                    end
                                        
                    links[#links + 1] = { start = startDragWaypoint, finish = i}
                end
                return
            end
        end
    end
    
    -- right click
    if IsMouseButtonDown(3) then
        if selectedWaypoint == nil then
            for i = 1, #waypoints do
                if IsPointInCircle(mouseX, mouseY, waypoints[i].x, waypoints[i].y, ARRIVE_DISTANCE) then
                    selectedWaypoint = waypoints[i]
                    break;
                end
            end
        else
            selectedWaypoint.x = mouseX
            selectedWaypoint.y = mouseY
        end
    else
        selectedWaypoint = nil
    end
    
    -- delete
    if IsKeyPressed(SDL_SCANCODE_DELETE) then
        for i = 1, #waypoints do
            if IsPointInCircle(mouseX, mouseY, waypoints[i].x, waypoints[i].y, ARRIVE_DISTANCE) then
                --remove links associated with removed waypoint.
                for j = #links, 1, -1 do
                    if (links[j].start == i) or (links[j].finish == i) then
                        table.remove(links, j)
                    end
                end
                
                table.remove(waypoints, i)
                
                --lower indices in existing links since waypoints above that index have
                --been re-indexed.
                for k = 1, #links do
                    if links[k].start > i then links[k].start = links[k].start - 1 end                            
                    if links[k].finish > i then links[k].finish = links[k].finish - 1 end
                end
                
                break
            end
        end
    end
end

function Draw()
    ClearScreen(68, 136, 204)
       
    -- draw links between waypoints
    SetDrawColor(255, 255, 255, 255)
    for i = 1, #links do
        local startX = waypoints[links[i].start].x
        local startY = waypoints[links[i].start].y
        local finishX = waypoints[links[i].finish].x
        local finishY = waypoints[links[i].finish].y
        DrawLine(startX, startY, finishX, finishY)
    end
           
    -- draw the waypoints (radius = arrive distance)
    SetDrawColor(33, 0, 255, 255)
    for i = 1, #waypoints do
        DrawCircle(waypoints[i].x, waypoints[i].y, ARRIVE_DISTANCE)
    end
    
    -- draw path
    SetDrawColor(255, 0, 255, 255)
    for i = 1, #agent.path do
        DrawCircle(agent.path[i].x, agent.path[i].y, ARRIVE_DISTANCE)
    end
            
    -- draw pathfinding agent.
    DrawEntity(agent)
end