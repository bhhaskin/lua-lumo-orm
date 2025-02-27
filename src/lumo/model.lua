local QueryBuilder = require("lumo.query_builder")
local Relationships = require("lumo.relationships") -- Import relationships module

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
        return self:new(result[1]) -- Return a new instance with data
    end
    return nil
end

-- Get all records
function Model:all()
    local result = self:query():get()
    local instances = {}
    for _, row in ipairs(result) do
        table.insert(instances, self:new(row))
    end
    return instances
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
    return success == true
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





-- **Use Relationships from `relationships.lua`**
Model.hasOne = Relationships.hasOne
Model.hasMany = Relationships.hasMany
Model.belongsTo = Relationships.belongsTo
Model.belongsToMany = Relationships.belongsToMany
Model.with = Relationships.with
Model.cascadeDelete = Relationships.cascadeDelete
Model.cascadeDeletePivot = Relationships.cascadeDeletePivot

return Model
