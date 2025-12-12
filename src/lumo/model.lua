local QueryBuilder = require("lumo.query_builder")
local Relationships = require("lumo.relationships")
local Collection = require("lumo.collection")

local Model = {}
Model.__index = Model
Model.db = nil -- Will be set dynamically

-- Model configuration defaults
Model.timestamps = false -- Set to true to auto-manage created_at/updated_at
Model.softDelete = false -- Set to true to enable soft deletes
Model.casts = {} -- Attribute casting definitions
Model.fillable = {} -- Mass-assignment whitelist
Model.guarded = {} -- Mass-assignment blacklist

-- Set the database connection (called in lumo.lua)
function Model.setDB(db)
    Model.db = db
    QueryBuilder.setDB(db) -- Ensure QueryBuilder uses the same connection
end

-- Get current timestamp
function Model:timestamp()
    return os.time()
end

-- Apply attribute casting
function Model:castAttribute(key, value)
    local modelClass = getmetatable(self)
    if not modelClass.casts or not modelClass.casts[key] then
        return value
    end

    local cast_type = modelClass.casts[key]

    if cast_type == "integer" or cast_type == "int" then
        return tonumber(value) or 0
    elseif cast_type == "number" or cast_type == "float" then
        return tonumber(value) or 0.0
    elseif cast_type == "boolean" or cast_type == "bool" then
        if type(value) == "number" then
            return value ~= 0
        elseif type(value) == "string" then
            return value == "true" or value == "1"
        end
        return value and true or false
    elseif cast_type == "string" then
        return tostring(value)
    elseif cast_type == "json" then
        -- Lua doesn't have built-in JSON, so we'll store as string
        -- Users can add their own JSON library
        return value
    elseif cast_type == "datetime" or cast_type == "timestamp" then
        return tonumber(value) or os.time()
    end

    return value
end

-- Fire model event hooks
function Model:fireEvent(event, ...)
    local modelClass = getmetatable(self)
    local hookName = event
    if modelClass[hookName] and type(modelClass[hookName]) == "function" then
        return modelClass[hookName](self, ...)
    end
    return true
end

-- Constructor (Create a new model instance)
function Model:new(data)
    local instance = setmetatable({}, self)
    for key, value in pairs(data or {}) do
        instance[key] = instance:castAttribute(key, value)
    end
    instance:fireEvent("afterInstantiate")
    return instance
end

-- Fill model with data (respects fillable/guarded)
function Model:fillAttributes(data)
    local modelClass = getmetatable(self)
    for key, value in pairs(data) do
        local canFill = true

        -- Check guarded
        if modelClass.guarded and #modelClass.guarded > 0 then
            for _, guarded_key in ipairs(modelClass.guarded) do
                if guarded_key == key then
                    canFill = false
                    break
                end
            end
        end

        -- Check fillable (if defined, only fillable fields allowed)
        if canFill and modelClass.fillable and #modelClass.fillable > 0 then
            canFill = false
            for _, fillable_key in ipairs(modelClass.fillable) do
                if fillable_key == key then
                    canFill = true
                    break
                end
            end
        end

        if canFill then
            self[key] = self:castAttribute(key, value)
        end
    end
end

-- Get a query builder instance for this model's table
function Model:query()
    local builder = QueryBuilder:new(self.table)
    local modelClass = getmetatable(self)

    -- Automatically exclude soft deleted records
    if modelClass.softDelete then
        builder:whereNull("deleted_at")
    end

    return builder
end

-- Query including soft deleted records
function Model:withTrashed()
    return QueryBuilder:new(self.table)
end

-- Query only soft deleted records
function Model:onlyTrashed()
    local builder = QueryBuilder:new(self.table)
    builder:whereNotNull("deleted_at")
    return builder
end

-- Find a record by ID
function Model:find(id)
    local result = self:query():where("id", "=", id):limit(1):get()
    if result and result:count() > 0 then
        return self:new(result:first()) -- Ensure it's an instance of Model
    end
    return nil
end

-- Save: Insert if new, otherwise update
function Model:save()
    local modelClass = getmetatable(self)

    -- Fire before save event
    if not self:fireEvent("beforeSave") then
        return false
    end

    if self.id then
        -- Only update fields that exist in the table
        local data = {}
        for key, value in pairs(self) do
            if type(value) ~= "function" and key ~= "_dirty" and key ~= "_original" then
                data[key] = value
            end
        end

        -- Add updated_at if timestamps enabled
        if modelClass.timestamps then
            data.updated_at = self:timestamp()
            self.updated_at = data.updated_at
        end

        local success = self:query():where("id", "=", self.id):update(data)
        if success then
            self:fireEvent("afterSave")
        end
        return success
    else
        -- Add timestamps for new records
        if modelClass.timestamps then
            self.created_at = self:timestamp()
            self.updated_at = self:timestamp()
        end

        local id = self:query():insert(self:toTable())
        if id then
            self.id = id
            self:fireEvent("afterSave")
            return true
        end
    end
    return false
end

-- Get all records
function Model:all()
    return self:query():get() -- Already returns a Collection
end

function Model:get()
    return self:query():get() -- Already returns a Collection
end

-- Insert a new record
function Model:create(data)
    local modelClass = getmetatable(self)

    -- Create a new instance to fire events
    local instance = self:new(data)

    -- Fire before create event
    if not instance:fireEvent("beforeCreate") then
        return nil
    end

    -- Add timestamps if enabled
    if modelClass.timestamps then
        data.created_at = instance:timestamp()
        data.updated_at = instance:timestamp()
    end

    local id = instance:query():insert(data)

    if id then
        local created = self:find(id)
        created:fireEvent("afterCreate")
        return created
    end

    return nil
end

-- Update an existing record
function Model:update(data)
    if not self.id then error("Cannot update a record without an ID") end

    local modelClass = getmetatable(self)

    -- Fire before update event
    if not self:fireEvent("beforeUpdate", data) then
        return false
    end

    -- Add updated_at timestamp if enabled
    if modelClass.timestamps then
        data.updated_at = self:timestamp()
    end

    local success = self:query():where("id", "=", self.id):update(data)

    if success then
        for key, value in pairs(data) do
            self[key] = self:castAttribute(key, value)
        end
        self:fireEvent("afterUpdate")
    end

    return success
end

-- Delete a record
function Model:delete()
    if not self.id then error("Cannot delete a record without an ID") end

    local modelClass = getmetatable(self)

    -- Fire before delete event
    if not self:fireEvent("beforeDelete") then
        return false
    end

    -- Soft delete if enabled
    if modelClass.softDelete then
        local data = { deleted_at = self:timestamp() }
        local success = QueryBuilder:new(self.table):where("id", "=", self.id):update(data)
        if success then
            self.deleted_at = data.deleted_at
            self:fireEvent("afterDelete")
        end
        return success
    end

    -- Handle cascade deletes if defined
    if modelClass.__cascadeDelete then
        for _, relationName in ipairs(modelClass.__cascadeDelete) do
            if self[relationName] and type(self[relationName]) == "function" then
                local relatedRecords = self[relationName](self)
                -- Check if it's a Collection or single record
                if relatedRecords then
                    if type(relatedRecords.each) == "function" then
                        -- It's a Collection from hasMany
                        relatedRecords:each(function(record)
                            if record.delete then
                                record:delete()
                            end
                        end)
                    elseif type(relatedRecords.delete) == "function" then
                        -- It's a single record from hasOne
                        relatedRecords:delete()
                    end
                end
            end
        end
    end

    local success = QueryBuilder:new(self.table):where("id", "=", self.id):delete()
    if success then
        self:fireEvent("afterDelete")
    end
    return success
end

-- Force delete (permanently delete even if soft delete enabled)
function Model:forceDelete()
    if not self.id then error("Cannot delete a record without an ID") end

    local modelClass = getmetatable(self)

    -- Handle cascade deletes
    if modelClass.__cascadeDelete then
        for _, relationName in ipairs(modelClass.__cascadeDelete) do
            if self[relationName] and type(self[relationName]) == "function" then
                local relatedRecords = self[relationName](self)
                if relatedRecords then
                    if type(relatedRecords.each) == "function" then
                        relatedRecords:each(function(record)
                            if record.forceDelete then
                                record:forceDelete()
                            elseif record.delete then
                                record:delete()
                            end
                        end)
                    elseif type(relatedRecords.delete) == "function" then
                        relatedRecords:forceDelete()
                    end
                end
            end
        end
    end

    return QueryBuilder:new(self.table):where("id", "=", self.id):delete()
end

-- Restore a soft deleted record
function Model:restore()
    if not self.id then error("Cannot restore a record without an ID") end

    local modelClass = getmetatable(self)

    if not modelClass.softDelete then
        error("Cannot restore: soft delete is not enabled for this model")
    end

    local data = { deleted_at = nil }
    local success = QueryBuilder:new(self.table):where("id", "=", self.id):update(data)

    if success then
        self.deleted_at = nil
    end

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
    if result then
        return self:new(result) -- Ensure instance of Model
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
    if not data[uniqueKey] then
        error("Upsert requires a `" .. uniqueKey .. "` field in data.")
    end
    local existing = self:query():where(uniqueKey, "=", data[uniqueKey]):first()
    if existing then
        existing:update(data)
        return existing
    else
        return self:create(data)
    end
end

function Model:increment(field, amount)
    amount = amount or 1
    if self.id then
        local new_value = (self[field] or 0) + amount
        self:update({ [field] = new_value }) -- Explicit update
    end
end

function Model:decrement(field, amount)
    amount = amount or 1
    if self.id then
        local new_value = (self[field] or 0) - amount
        self:update({ [field] = new_value }) -- Explicit update
    end
end

function Model:toTable()
    local data = {}
    for key, value in pairs(self) do
        if type(value) ~= "function" and key ~= "_dirty" and key ~= "_original" then
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
    for key, value in pairs(findData) do
        query:where(key, "=", value)
    end
    local existing = query:first()
    if existing then
        if not getmetatable(existing) then
            existing = self:new(existing)  -- Convert result to an instance
        end
        existing:update(updateData)
        return existing
    else
        local newData = {}
        for k, v in pairs(findData) do newData[k] = v end
        for k, v in pairs(updateData) do newData[k] = v end
        return self:create(newData)
    end
end

-- Query Scopes: Call scope methods dynamically
-- Define scopes as methods like: function User:scopeActive(query) return query:where("status", "=", "active") end
-- Use scopes like: User:active():get()
function Model:__index(key)
    -- Check if it's a scope method
    local modelClass = getmetatable(self) or self
    local scope_method = "scope" .. key:sub(1, 1):upper() .. key:sub(2)

    if modelClass[scope_method] and type(modelClass[scope_method]) == "function" then
        return function(...)
            local query = self:query()
            return modelClass[scope_method](self, query, ...)
        end
    end

    -- Fall back to normal behavior
    return Model[key] or rawget(self, key)
end

-- Simple validation system
Model.rules = {} -- Validation rules

function Model:validate(data)
    local modelClass = getmetatable(self)

    if not modelClass.rules or type(modelClass.rules) ~= "table" then
        return true, {}
    end

    local errors = {}

    for field, rules_str in pairs(modelClass.rules) do
        local value = data[field]
        local rules = {}

        -- Parse rules string (e.g., "required|min:3|max:255")
        for rule in string.gmatch(rules_str, "[^|]+") do
            table.insert(rules, rule)
        end

        -- Check each rule
        for _, rule in ipairs(rules) do
            if rule == "required" then
                if value == nil or value == "" then
                    table.insert(errors, field .. " is required")
                end
            elseif rule:match("^min:") then
                local min_val = tonumber(rule:match("^min:(%d+)"))
                if value and type(value) == "string" and #value < min_val then
                    table.insert(errors, field .. " must be at least " .. min_val .. " characters")
                elseif value and type(value) == "number" and value < min_val then
                    table.insert(errors, field .. " must be at least " .. min_val)
                end
            elseif rule:match("^max:") then
                local max_val = tonumber(rule:match("^max:(%d+)"))
                if value and type(value) == "string" and #value > max_val then
                    table.insert(errors, field .. " must be at most " .. max_val .. " characters")
                elseif value and type(value) == "number" and value > max_val then
                    table.insert(errors, field .. " must be at most " .. max_val)
                end
            elseif rule == "email" then
                if value and not value:match("^[%w%._%+-]+@[%w%._%+-]+%.%w+$") then
                    table.insert(errors, field .. " must be a valid email address")
                end
            elseif rule == "numeric" then
                if value and not tonumber(value) then
                    table.insert(errors, field .. " must be numeric")
                end
            elseif rule:match("^unique:") then
                local table_name = rule:match("^unique:(%w+)")
                if value then
                    local existing = QueryBuilder:new(table_name)
                        :where(field, "=", value)
                        :first()
                    if existing and (not self.id or existing.id ~= self.id) then
                        table.insert(errors, field .. " must be unique")
                    end
                end
            end
        end
    end

    return #errors == 0, errors
end

-- Validate before creating
local original_create = Model.create
function Model:create(data)
    local valid, errors = self:validate(data)
    if not valid then
        error("Validation failed: " .. table.concat(errors, ", "))
    end
    return original_create(self, data)
end

-- **Use Relationships from `relationships.lua`**
Model.hasOne = Relationships.hasOne
Model.hasMany = Relationships.hasMany
Model.belongsTo = Relationships.belongsTo
Model.belongsToMany = Relationships.belongsToMany
Model.with = Relationships.with
Model.cascadeDelete = Relationships.cascadeDelete
Model.cascadeDeletePivot = Relationships.cascadeDeletePivot
Model.hasManyThrough = Relationships.hasManyThrough
Model.morphMany = Relationships.morphMany
Model.morphOne = Relationships.morphOne
Model.morphTo = Relationships.morphTo

return Model