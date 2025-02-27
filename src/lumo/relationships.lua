local QueryBuilder = require("lumo.query_builder")

local Relationships = {}
Relationships.__index = Relationships

-- One-to-One relationship (with eager loading)
function Relationships:hasOne(model, foreignKey, localKey)
    if not model or not model.query then
        error("Invalid model passed to hasOne()")
    end
    localKey = localKey or "id"
    return model:query():where(foreignKey, "=", self[localKey]):limit(1):get()[1]
end

-- One-to-Many relationship (with eager loading)
function Relationships:hasMany(model, foreignKey, localKey)
    if not model or not model.query then
        error("Invalid model passed to hasMany()")
    end
    localKey = localKey or "id"
    return model:query():where(foreignKey, "=", self[localKey]):get()
end

-- Belongs-To relationship (with eager loading)
function Relationships:belongsTo(model, foreignKey, localKey)
    if not model or not model.query then
        error("Invalid model passed to belongsTo()")
    end
    localKey = localKey or "id"
    return model:query():where(localKey, "=", self[foreignKey]):limit(1):get()[1]
end

-- Many-to-Many relationship (via pivot table with eager loading)
function Relationships:belongsToMany(model, pivotTable, localKey, foreignKey)
    if not model or not model.query then
        error("Invalid model passed to belongsToMany()")
    end
    localKey = localKey or "id"

    local results = QueryBuilder:new(pivotTable)
        :where(localKey, "=", self.id)
        :get()
    
    local relatedIDs = {}
    for _, row in ipairs(results) do
        table.insert(relatedIDs, row[foreignKey])
    end

    if #relatedIDs > 0 then
        return model:query():where("id", "IN", "(" .. table.concat(relatedIDs, ",") .. ")"):get()
    end
    return {}
end

-- Eager load relationships to avoid N+1 queries
function Relationships:with(relations)
    if type(relations) ~= "table" then
        relations = { relations } -- Allow single or multiple relationships
    end

    for _, relation in ipairs(relations) do
        if self[relation] and type(self[relation]) == "function" then
            self[relation .. "_loaded"] = self[relation](self)
        end
    end

    return self
end

-- Cascade delete for One-to-Many
function Relationships:cascadeDelete(model, foreignKey)
    if not model or not model.query then
        error("Invalid model passed to cascadeDelete()")
    end
    local relatedRecords = self:hasMany(model, foreignKey)
    for _, record in ipairs(relatedRecords) do
        record:delete() -- Delete each related record
    end
end

-- Cascade delete for Many-to-Many (remove pivot entries)
function Relationships:cascadeDeletePivot(pivotTable, localKey)
    QueryBuilder:new(pivotTable)
        :where(localKey, "=", self.id)
        :delete()
end

return Relationships
