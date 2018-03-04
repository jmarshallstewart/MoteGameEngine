dofile(scriptDirectory .. "core/steering.lua")
dofile(scriptDirectory .. "core/pathfinding.lua")

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

ARRIVE_DISTANCE = 14
MAX_ACCELERATION = 1.0 -- how fast can the agent change direction and speed?

--user interface state
MODE_WAYPOINT_AUTHORING = 1
MODE_AGENT_PATHFINDING_DEMO = 2
isLeftClickDragging = false
selectedWaypoint = nil
mode = MODE_WAYPOINT_AUTHORING
waypointsFilePath = scriptDirectory .. "exampleProjects/graph.txt"

--assumes nodes have x, y position and edges have start and finish indices into nodes list.
function GenerateWaypointGraph(nodes, edges)
    graph = {}
    
    if nodes ~= nil and edges ~= nil then
        for n = 1, #nodes do
            graph[n] = { x = nodes[n].x, y = nodes[n].y, parent = nil, f = 0, g = 0, h = 0, neighbors = {} }
        end
        
        for e = 1, #edges do
            local sNode = graph[edges[e].start]
            local fNode = graph[edges[e].finish]
            local distance = Distance(sNode.x, sNode.y, fNode.x, fNode.y)
            
            -- add two edges: one from start to finish, and another from finish to start.
            sNode.neighbors[#sNode.neighbors + 1] = fNode
            fNode.neighbors[#fNode.neighbors + 1] = sNode
        end
    end
    
    return graph
end

function FindPath(start, finish)
    agent.path = nil
    PathInit(start)
    
    local status = PATHFINDING_STATUS_SEARCHING
    
    while status == PATHFINDING_STATUS_SEARCHING do
        status = StepPath(start, finish, searchSpace)
    end
    
    if status == PATHFINDING_STATUS_PATH_FOUND then
        --reverse the path by traversing the parent
        --points and inserting the next node at the start
        --of the path to the be followed.
        agent.path = {}
        local next = resultPath
        while next ~= nil do
            table.insert(agent.path, 1, next)
            next = next.parent
        end
    else
        Log("Could not find path.")
    end
end

function TryStartPathfinding(goalX, goalY)
    searchSpace = GenerateWaypointGraph(waypoints, links)
    
    local sNodeIndex = GetNearestWaypoint(agent.x, agent.y)
    local fNodeIndex = GetNearestWaypoint(goalX, goalY)
    
    local sNode = searchSpace[sNodeIndex]
    local fNode = searchSpace[fNodeIndex]
        
    FindPath(sNode, fNode)
        
    if agent.path ~= nil then
        agent.targetWaypoint = 1
        agent.isPathing = true
    end
end

-- return the index of the nearest waypoint in the table waypoints
function GetNearestWaypoint(x, y)
    local nearest = nil
    
    if #waypoints > 0 then
        nearest = 1
    end
    
    for i = 2, #waypoints do
        -- we only care about relative distance, so we can skip the sqrt() call we normally
        -- make when calculating distance, hence the call to distanceSquared().
        local distanceSquared = DistanceSquared(x, y, waypoints[i].x, waypoints[i].y)
        
        if distanceSquared < DistanceSquared(x, y, waypoints[nearest].x, waypoints[nearest].y) then
            nearest = i
        end
    end
    
    return nearest
end

function ResetAgent()
    agent.isPathing = false
    agent.path = {}
    agent.velocity.x = 0
    agent.velocity.y = 0
    agent.acceleration.x = 0
    agent.acceleration.y = 0
    agent.targetWaypoint = 1
end

function LoadWaypointsFile()
    local file = io.open(waypointsFilePath, "r")
    local script = file:read("*all")
    local s = load(script)
    s()
    file:close()
end

function WriteWaypointsFile()
    local file = io.open(waypointsFilePath, "w")
            
    if waypoints ~= nil and links ~= nil then
        file:write("waypoints = {\n")
        
        for n = 1, #waypoints do
            file:write("    { x = ", waypoints[n].x, ", y = ", waypoints[n].y, " },\n")
        end
        
        file:write("}\n")
        
        file:write("\nlinks = {\n")
        
        for e = 1, #links do
            file:write("    { start = ", links[e].start, ", finish = ", links[e].finish, "},\n")
        end
        
        file:write("}\n")
        
        file:flush()
        file:close()
    end
end

function UpdateModeWaypointAuthoring()
    local mouseX, mouseY = GetMousePosition()

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
    elseif IsKeyPressed(SDL_SCANCODE_S) then
        WriteWaypointsFile()
    end
end

function UpdateModeAgentDemo()
    
    if agent.isPathing then
        --get the next waypoint along the path
        local next = agent.path[agent.targetWaypoint]

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
            agent.targetWaypoint = agent.targetWaypoint + 1
            if agent.targetWaypoint > #agent.path then
                ResetAgent()
            end
        end
    elseif IsMouseButtonDown(1) then -- left click
        local mouseX, mouseY = GetMousePosition()
        TryStartPathfinding(mouseX, mouseY)
    end
end

function DrawWaypointGraph()
    -- draw links between waypoints
    if links ~= nil then
        SetDrawColor(255, 255, 255, 255)
        for i = 1, #links do
            local startX = waypoints[links[i].start].x
            local startY = waypoints[links[i].start].y
            local finishX = waypoints[links[i].finish].x
            local finishY = waypoints[links[i].finish].y
            
            DrawLine(startX, startY, finishX, finishY)
        end
    end
           
    -- draw the waypoints (radius = arrive distance)
    if waypoints ~= nil then
        SetDrawColor(33, 0, 255, 255)
        for i = 1, #waypoints do
            DrawCircle(waypoints[i].x, waypoints[i].y, ARRIVE_DISTANCE)
        end
    end
end

function DrawModeText()
    local modeName = "unknown"
    
    if mode == MODE_WAYPOINT_AUTHORING then modeName = "Waypoint Authoring"
    elseif mode == MODE_AGENT_PATHFINDING_DEMO then modeName = "Agent Pathfinding" end
    
    DrawText("MODE: " .. modeName, 8, 9, font, 255, 255, 255)
end

-- core functions

function Start()
    CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT)
    SetWindowTitle("Pathfinding Example -- Press TAB to toggle authoring mode.")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    local image = LoadImage("images/arrow.png")
    agent = CreateEntity(image, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, 16)
    agent.maxSpeed = 8
    agent.path = {}
    agent.targetWaypoint = 1
    
    --when reading about A*, waypoints and links are nodes and edges.
    if IsFileReadable(waypointsFilePath) then
        LoadWaypointsFile()
    else
        waypoints = {}
        links = {}
    end
end

function Update()
    --test whether we should switch between modes, otherwise just update the current mode.
    if IsKeyPressed(SDL_SCANCODE_TAB) then
        ResetAgent()
        
        if mode == MODE_WAYPOINT_AUTHORING then 
            mode = MODE_AGENT_PATHFINDING_DEMO
        elseif mode == MODE_AGENT_PATHFINDING_DEMO then 
            mode = MODE_WAYPOINT_AUTHORING 
            searchSpace = nil
        end
    elseif mode == MODE_WAYPOINT_AUTHORING then
        UpdateModeWaypointAuthoring()
    elseif mode == MODE_AGENT_PATHFINDING_DEMO then
        UpdateModeAgentDemo()
    end 
end

function Draw()
    ClearScreen(68, 136, 204)
    
    DrawWaypointGraph()
    
    -- draw path
    if agent.path ~= nil then
        SetDrawColor(255, 0, 255, 255)
        for i = 1, #agent.path do
            DrawCircle(agent.path[i].x, agent.path[i].y, ARRIVE_DISTANCE)
        end
    end
    
    -- draw pathfinding agent.
    DrawEntity(agent)
        
    DrawModeText()
end