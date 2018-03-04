statusSearching = 0
statusPathFound = 1
statusNoPathFound = 2

-- call this each time you make a new path query,
-- before calling stepPath
function PathInit(startNode)
    openList = { startNode }
    closedList = {}
    resultPath = nil
end

function StepPath(start, goal, searchSpace) 
	if #openList > 0 then
        --find the node with the lowest cost and remove it from the open list.
        table.sort(openList, function(a, b) return a.f < b.f end)
        local currentNode = openList[1]
        table.remove(openList, 1)
                
        --if the current node is the destination, we're done. Return the node.
        if currentNode == goal then
            resultPath = currentNode
            return statusPathFound
        end
        
        --add the lowest cost node to the closed list.
		closedList[#closedList + 1] = currentNode
        
        local parent = currentNode.parent
        
        for n = 1, #currentNode.neighbors do
            local neighbor = currentNode.neighbors[n]
            Log(neighbor.x .. " " .. neighbor.y)
            if not Contains(closedList, neighbor) then
                local gCost = currentNode.g + Distance(currentNode.x, currentNode.y, neighbor.x, neighbor.y)
                
                --if this neighbor node is not on open list, add it to the open list. Set its parent to currentNode.
                if not Contains(openList, neighbor) then
                    neighbor.parent = currentNode
                    neighbor.g = gCost
                    neighbor.h = Distance(neighbor.x, neighbor.y, goal.x, goal.y)
                    neighbor.f = neighbor.g + neighbor.h
                    
                    openList[#openList + 1] = neighbor
                elseif gCost < neighbor.g then
                    neighbor.parent = currentNode
                    neighbor.g = gCost
                    neighbor.f = gCost + neighbor.h
                end
            end
        end
        
        return statusSearching
    end
    
    return statusNoPathFound
end