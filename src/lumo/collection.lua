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

function Collection:count()
  return #self.items
end

function Collection:isInstanceOf(class)
  return getmetatable(self) == class
end

function Collection:pluck(key)
  local results = {}
  for _, item in ipairs(self.items) do
      if type(item) == "table" and item[key] ~= nil then
          table.insert(results, item[key])
      end
  end
  return results
end

return Collection