local Collection = {}
Collection.__index = Collection

-- Create a new collection
function Collection:new(items)
    local instance = setmetatable({ items = items or {} }, self)
    return instance
end

-- Map over items
function Collection:map(callback)
    local results = {}
    for i, item in ipairs(self.items) do
        results[i] = callback(item, i)
    end
    return Collection:new(results)
end

-- Filter items
function Collection:filter(callback)
    local results = {}
    for _, item in ipairs(self.items) do
        if callback(item) then
            table.insert(results, item)
        end
    end
    return Collection:new(results)
end

-- Iterate over each item without returning a new collection
function Collection:each(callback)
    for i, item in ipairs(self.items) do
        callback(item, i)
    end
end

-- Check if any item matches the given condition
function Collection:contains(predicate)
    for _, item in ipairs(self.items) do
        if predicate(item) then
            return true
        end
    end
    return false
end

-- Reduce collection to a single value
function Collection:reduce(callback, initial)
    local accumulator = initial
    for i, item in ipairs(self.items) do
        accumulator = callback(accumulator, item, i)
    end
    return accumulator
end

-- Sort collection based on a key
function Collection:sortBy(key, ascending)
    local results = { unpack(self.items) } -- Copy items
    table.sort(results, function(a, b)
        if ascending == false then
            return a[key] > b[key]
        end
        return a[key] < b[key]
    end)
    return Collection:new(results)
end

-- Reverse the order of the collection
function Collection:reverse()
    local results = {}
    for i = #self.items, 1, -1 do
        table.insert(results, self.items[i])
    end
    return Collection:new(results)
end

-- Get first item
function Collection:first()
    return self.items[1] or nil
end

-- Get last item
function Collection:last()
    return self.items[#self.items] or nil
end

-- Convert to plain Lua table
function Collection:toArray()
    return self.items
end

-- Count items in the collection
function Collection:count()
    return #self.items
end

-- Check if this is an instance of Collection
function Collection:isInstanceOf(class)
    return getmetatable(self) == class
end

-- Extract a single key from each item
function Collection:pluck(key)
    local results = {}
    for _, item in ipairs(self.items) do
        if type(item) == "table" and item[key] ~= nil then
            table.insert(results, item[key])
        end
    end
    return Collection:new(results) -- Now returns a Collection
end

return Collection