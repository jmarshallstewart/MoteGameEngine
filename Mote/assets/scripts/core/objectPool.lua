function CreateObjectPool(size, createFunction)
    local pool = {}
    pool.size = size
    pool.objects = {}
    pool.freeList = {}
    pool.activeList = {}
    
    pool.onCreate = createFunction -- function should return a table to be added to the pool
    pool.onGet = nil
    pool.onFree = nil
        
    for i = 1, size do
        local e = createFunction()
        pool.objects[#pool.objects + 1] = e
        pool.freeList[#pool.freeList + 1] = e
    end
    
    pool.hasFree = function()
        return #pool.freeList > 0
    end
            
    pool.get = function(params)
        if #pool.freeList > 0 then
            local next = pool.freeList[#pool.freeList]
            
            if pool.onGet ~= nil then
                pool.onGet(next, params)
            end
            
            table.remove(pool.freeList, #pool.freeList)
            pool.activeList[#pool.activeList + 1] = next
            return next
        else
            Log("Attempted to create object from empty pool.")
        end
    end
    
    pool.free = function(e)
        if pool.onFree ~= nil then
            pool.onFree(e)
        end
    
        for i = 1, #pool.activeList do
            if pool.activeList[i] == e then
                table.remove(pool.activeList, i)
                break;
            end
        end
                
        pool.freeList[#pool.freeList + 1] = e
    end
            
    pool.each = function(func)
        if func ~= nil then
            for i = 1, #pool.activeList do
                func(pool.activeList[i])
            end
        end
    end
    
    return pool
end