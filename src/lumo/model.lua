local QueryBuilder = require("lumo.query_builder")
local Relationships = require("lumo.relationships")
local Collection = require("lumo.collection")

local Model = {}
Model.__index = Model
Model.db = nil -- Will be set dynamically

-- Set the database connection (called in lumo.lua)
function Model.setDB(db)
    Model.db = db
    QueryBuilder.setDB(db) -- Ensure QueryBuilder uses the same connection
end

-- Constructor (Create a new model instance)
function Model:new(data)
    local instance = setmetatable(data or {}, self)
    return instance
end

-- Get a query builder instance for this model's table
function Model:query()
    return QueryBuilder:new(self.table)
end

-- Find a record by ID
function Model:find(id)
    local result = self:query():where("id", "=", id):limit(1):get()
    if #result > 0 then
        return self:new(result[1]) -- Ensure it's an instance of Model
    end
    return nil
end

-- Save: Insert if new, otherwise update
function Model:save()
    if self.id then
        return self:update(self)
    else
        local id = self:query():insert(self)
        if id then
            self.id = id -- Assign ID to the instance
            return true
        end
    end
    return false
end

-- Get all records
function Model:all()
    local result = self:query():get()
    return Collection:new(result) -- Return as Collection
end

function Model:get()
    local result = self.query_instance:get()
    return Collection:new(result) -- Return as Collection
end

-- Insert a new record
function Model:create(data)
    local id = self:query():insert(data)
    return self:find(id) -- Return the newly created record
end

-- Update an existing record
function Model:update(data)
    if not self.id then error("Cannot update a record without an ID") end

    local success = self:query():where("id", "=", self.id):update(data)

    if success then
        for key, value in pairs(data) do
            self[key] = value -- Update instance attributes
        end
    end

    return success
end

-- Delete a record
function Model:delete()
    if not self.id then error("Cannot delete a record without an ID") end

    -- Run cascade delete hooks (if defined in model)
    if self.__cascadeDelete then
        for _, relation in ipairs(self.__cascadeDelete) do
            if type(self[relation]) == "function" then
                local related_records = self[relation](self) -- Fetch related records
                if type(related_records) == "table" then
                    for _, record in ipairs(related_records) do
                        if record and record.delete then
                            record:delete() -- Ensure each related record is deleted
                        end
                    end
                end
            end
        end
    end

    -- Delete the record
    local success = self:query():where("id", "=", self.id):delete()
    return success
end

-- Fluent Query Builder Methods
function Model:where(field, operator, value)
    return self:query():where(field, operator, value)
end

function Model:orderBy(field, direction)
    return self:query():orderBy(field, direction)
end

function Model:limit(count)
    return self:query():limit(count)
end

function Model:first()
    local result = self:query():first()
    if #result > 0 then
        return self:new(result[1]) -- Ensure instance of Model
    end
    return nil
end

function Model:only(...)
    local selected = {}
    for _, key in ipairs({...}) do
        selected[key] = self[key]
    end
    return selected
end

function Model:fill(data)
    for key, value in pairs(data) do
        self[key] = value
    end
end

function Model:upsert(data, uniqueKey)
    uniqueKey = uniqueKey or "id"

    -- Ensure the unique key exists in data
    if not data[uniqueKey] then
        error("Upsert requires a `" .. uniqueKey .. "` field in data.")
    end

    -- Try to find an existing record
    local existing = self:query():where(uniqueKey, "=", data[uniqueKey]):first()

    if existing then
        -- Update existing record
        existing:update(data)
        return existing
    else
        -- Create new record
        return self:create(data)
    end
end

function Model:increment(field, amount)
    amount = amount or 1
    if self.id then
        self[field] = (self[field] or 0) + amount
        self:save()
    end
end

function Model:decrement(field, amount)
    amount = amount or 1
    if self.id then
        self[field] = (self[field] or 0) - amount
        self:save()
    end
end

function Model:toTable()
    local data = {}
    for key, value in pairs(self) do
        if key ~= "_dirty" and key ~= "_original" then
            data[key] = value
        end
    end
    return data
end

function Model:refresh()
    if not self.id then return nil end

    local refreshed = self:query():where("id", "=", self.id):first()
    if refreshed then
        setmetatable(refreshed, getmetatable(self))  -- Ensure it remains a model instance
        for key, value in pairs(refreshed) do
            self[key] = value
        end
    end

    return self
end

function Model:exists()
    return self.id ~= nil and self:query():where("id", "=", self.id):first() ~= nil
end

function Model:find_or_create(data, uniqueKey)
    uniqueKey = uniqueKey or "id"

    local existing = self:query():where(uniqueKey, "=", data[uniqueKey]):first()
    if existing then
        return existing
    else
        return self:create(data)
    end
end

function Model:update_or_create(findData, updateData)
    local query = self:query()

    -- Apply all key-value conditions for search
    for key, value in pairs(findData) do
        query:where(key, "=", value)
    end

    local existing = query:first()

    if existing then
        -- Ensure it is a proper model instance
        if not getmetatable(existing) then
            existing = self:new(existing)  -- Convert result to an instance
        end

        -- Call update on the instance
        existing:update(updateData)
        return existing
    else
        -- Merge findData and updateData to create a new record
        local newData = {}
        for k, v in pairs(findData) do newData[k] = v end
        for k, v in pairs(updateData) do newData[k] = v end

        return self:create(newData)
    end
end

-- **Use Relationships from `relationships.lua`**
Model.hasOne = Relationships.hasOne
Model.hasMany = Relationships.hasMany
Model.belongsTo = Relationships.belongsTo
Model.belongsToMany = Relationships.belongsToMany
Model.with = Relationships.with
Model.cascadeDelete = Relationships.cascadeDelete
Model.cascadeDeletePivot = Relationships.cascadeDeletePivot

return Model
