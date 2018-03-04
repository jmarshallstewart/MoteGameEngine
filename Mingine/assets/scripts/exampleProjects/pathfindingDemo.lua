--[[
This example is a waypoint editor with a PIE ("play in editor") mode. This tool allows the user to
author a graph of waypoints and the connections between them. The user can save their work and
reload it to continue editing in another session. The PIE mode creates a single agent that will
use the waypoint graph to find paths to wherever the user clicks. 

The demo has two modes: one for laying down a graph of waypoints, and another
for testing the graph by having an agent find and execute paths.

*********************************
Waypoint Authoring Mode Controls:

Left mouse click: if it would not overlap an existing waypoint, add a new waypoint at the click position.

Right mouse click and drag: drag to reposition existing waypoints. Waypoint will be moved to 
the cursor position at which the right mouse button was released.

Left mouse click and drag: If drag starts over a waypoint and ends over a different waypoint,
add a two-way connection between the waypoints. Left click and dragging over two connected waypoints removes
their connection.

delete key: if the mouse cursor is positioned over a waypoint, that waypoint will be deleted along with
any connections to that waypoint.

s key: Pressing the s key will save the current waypoint graph to the file specified 
in the lua variable waypointsFilePath, below. This is a silent operation with
no feedback to the user as to whether the save was successful. This demo will also
load waypoint data on start-up if the file is present at waypointsFilePath.

********************************
Agent Pathfinding Demo Controls:

Left click: Agent will use the waypoint graph as a search space to find a path
to the position of the cursor when the left mouse button was clicked. The agent
will begin its path at the nearest waypoint, and end its movement when it reaches
the waypoint nearest to the click position. If the agent cannot find a path, nothing
happens.

]]--

dofile(scriptDirectory .. "core/steering.lua")
dofile(scriptDirectory .. "core/pathfinding.lua")

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

ARRIVE_DISTANCE = 14
MAX_ACCELERATION = 1.0 -- how fast can the agent change direction and speed?

--user interface state
MODE_WAYPOINT_AUTHORING = 1
MODE_AGENT_PATHFINDING_DEMO = 2
prevLeftMouseButtonDown = false
isLeftClickDragging = false
selectedWaypoint = nil
mode = MODE_WAYPOINT_AUTHORING
waypointsFilePath = assetDirectory .. "/waypoints/" .. "pathfindingDemoGraph.lua"

-- helper functions:

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

function CreateWaypointAt(x, y)
    local waypoint = { x = x, y = y}
    waypoints[#waypoints + 1] = waypoint
end

function RemoveWaypointAt(x, y)
    for i = 1, #waypoints do
        if IsOnWaypoint(x, y, waypoints[i]) then
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

-- load waypoints from the save file, or create
-- a fresh empty list if the save file does not
-- exist.
function InitializeWaypoints()
    if IsFileReadable(waypointsFilePath) then
        LoadWaypointsFile()
    else
        --when reading about A* or graphs in general, waypoints and links
        --are referred to as nodes and edges.
        waypoints = {}
        links = {}
    end
end

function IsOnWaypoint(x, y, waypoint)
    return IsPointInCircle(x, y, waypoint.x, waypoint.y, ARRIVE_DISTANCE)
end

-- agent functions:

function ResetAgent()
    agent.isPathing = false
    agent.path = {}
    agent.velocity.x = 0
    agent.velocity.y = 0
    agent.acceleration.x = 0
    agent.acceleration.y = 0
    agent.targetWaypoint = 1
end

-- after the agent has a path, this function is
-- used to make the agent actually follow along that
-- path toward its goal.
function UpdateAgentPathfollowingBehavior()
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

-- save/load waypoint graph file helper functions:

function LoadWaypointsFile()
    local file = io.open(waypointsFilePath, "r")
    local script = file:read("*all")
    load(script)()
    file:close()
end

function SaveWaypointsFile()
    local file = io.open(waypointsFilePath, "w")
        
    -- save waypoints
    file:write("waypoints = {\n")
    
    for n = 1, #waypoints do
        file:write("    { x = ", waypoints[n].x, ", y = ", waypoints[n].y, " },\n")
    end
    
    file:write("}\n")
    
    --save links
    file:write("\nlinks = {\n")
    
    for e = 1, #links do
        file:write("    { start = ", links[e].start, ", finish = ", links[e].finish, "},\n")
    end
    
    file:write("}\n")
            
    file:close()
end

-- per-mode update functions:

-- updates the waypoint authoring mode when that mode is active.
function UpdateModeWaypointAuthoring()
    local mouseX, mouseY = GetMousePosition()

    -- left click
    if IsMouseButtonDown(1) then
        for i = 1, #waypoints do
            if IsOnWaypoint(mouseX, mouseY, waypoints[i]) then
                if not isLeftClickDragging then
                    isLeftClickDragging = true
                    startDragWaypoint = i
                end
                return
            end
        end
        
        if not isLeftClickDragging then
            CreateWaypointAt(mouseX, mouseY)
        end
    elseif isLeftClickDragging then
        isLeftClickDragging = false
        for i = 1, #waypoints do
            if IsOnWaypoint(mouseX, mouseY, waypoints[i]) then
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
                if IsOnWaypoint(mouseX, mouseY, waypoints[i]) then
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
    
    -- handle keyboard input
    if IsKeyPressed(SDL_SCANCODE_DELETE) then
        RemoveWaypointAt(mouseX, mouseY)
    elseif IsKeyPressed(SDL_SCANCODE_S) then
        SaveWaypointsFile()
    end
end

-- updates the PIE mode when that mode is active.
function UpdateModeAgentDemo()
    local leftMousePressed = not prevLeftMouseButtonDown and IsMouseButtonDown(1)
        
    if agent.isPathing and not leftMousePressed then
        UpdateAgentPathfollowingBehavior()
    elseif leftMousePressed then -- left click
        local mouseX, mouseY = GetMousePosition()
        TryStartPathfinding(mouseX, mouseY)
    end
end

-- Draw() helper functions:

function DrawPath(agent)
    if agent.path ~= nil then
        SetDrawColor(255, 0, 255, 255)
        for i = 1, #agent.path do
            DrawCircle(agent.path[i].x, agent.path[i].y, ARRIVE_DISTANCE)
        end
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
    SetWindowTitle("Waypoint Editor -- Press TAB to toggle PIE mode.")
    
    font = LoadFont("fonts/8_bit_pusab.ttf", 16)
    
    -- create pathfollowing agent
    local image = LoadImage("images/arrow.png")
    agent = CreateEntity(image, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, 16)
    agent.maxSpeed = 8
    agent.path = {}
    agent.targetWaypoint = 1
    
    InitializeWaypoints()
end

function Update()
    --test whether we should switch between modes, but otherwise just update the current mode.
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
    
    prevLeftMouseButtonDown = IsMouseButtonDown(1)
end

function Draw()
    ClearScreen(68, 136, 204)
    
    DrawWaypointGraph()
       
    if mode == MODE_AGENT_PATHFINDING_DEMO then
        DrawPath(agent)
        DrawEntity(agent)
    end
        
    DrawModeText()
end