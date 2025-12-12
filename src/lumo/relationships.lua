local QueryBuilder = require("lumo.query_builder")
local Collection = require("lumo.collection")

local Relationships = {}
Relationships.__index = Relationships

-- One-to-One relationship
function Relationships:hasOne(model, foreignKey, localKey)
    if not model or not model.query then
        error("Invalid model passed to hasOne()")
    end
    localKey = localKey or "id"
    foreignKey = foreignKey or model.table .. "_id"

    local result = model:query():where(foreignKey, "=", self[localKey]):limit(1):get()
    if result:count() > 0 then
        return model:new(result:first())
    end
    return nil
end

-- One-to-Many relationship
function Relationships:hasMany(model, foreignKey, localKey)
    if not model or not model.query then
        error("Invalid model passed to hasMany()")
    end
    localKey = localKey or "id"
    foreignKey = foreignKey or model.table .. "_id"

    local results = model:query():where(foreignKey, "=", self[localKey]):get()

    -- Convert each result to a Model instance
    return results:map(function(row)
        return model:new(row)
    end)
end

-- Belongs-To relationship
function Relationships:belongsTo(model, foreignKey, localKey)
    if not model or not model.query then
        error("Invalid model passed to belongsTo()")
    end
    localKey = localKey or "id"
    foreignKey = foreignKey or self.table .. "_id"

    local result = model:query():where(localKey, "=", self[foreignKey]):limit(1):get()
    if result:count() > 0 then
        return model:new(result:first())
    end
    return nil
end

-- Many-to-Many relationship (via pivot table)
function Relationships:belongsToMany(model, pivotTable, localKey, foreignKey)
    if not model or not model.query then
        error("Invalid model passed to belongsToMany()")
    end
    localKey = localKey or "id"

    local pivotResults = QueryBuilder:new(pivotTable)
        :where(localKey, "=", self.id)
        :get()

    local relatedIDs = pivotResults:pluck(foreignKey):toArray()

    if #relatedIDs > 0 then
        local results = model:query():whereIn("id", relatedIDs):get()

        -- Convert each result to a Model instance
        return results:map(function(row)
            return model:new(row)
        end)
    end

    return Collection:new({})
end

-- Load relationships (note: this still causes N+1 queries for single models, not true eager loading for collections)
function Relationships:with(relations)
    if type(relations) ~= "table" then
        relations = { relations } -- Allow single or multiple relationships
    end

    local loaded = {}
    for _, relation in ipairs(relations) do
        if self[relation] and type(self[relation]) == "function" then
            loaded[relation] = self[relation](self)
        end
    end
    return loaded
end

-- Eager load relationships for a collection (reduces N+1 queries)
function Relationships.eagerLoad(collection, relations)
    if type(relations) == "string" then
        relations = { relations }
    end

    if not collection or #collection == 0 then
        return collection
    end

    for _, relation_name in ipairs(relations) do
        -- Get the model class from the first item
        local first_model = collection[1]
        local modelClass = getmetatable(first_model)

        -- Collect all IDs
        local ids = {}
        for _, model in ipairs(collection) do
            if model.id then
                table.insert(ids, model.id)
            end
        end

        if #ids == 0 then
            goto continue
        end

        -- Check what type of relationship this is by checking if the method exists
        -- This is a simplified implementation - in practice, you'd need metadata about relationship types
        -- For now, we'll just load the relationship for each model
        for _, model in ipairs(collection) do
            if model[relation_name] and type(model[relation_name]) == "function" then
                model["_" .. relation_name] = model[relation_name](model)
            end
        end

        ::continue::
    end

    return collection
end

-- Cascade delete for One-to-Many
function Relationships:cascadeDelete(model, foreignKey)
    if not model or not model.query then
        error("Invalid model passed to cascadeDelete()")
    end
    local relatedRecords = self:hasMany(model, foreignKey)
    relatedRecords:each(function(record)
        record:delete()
    end)
end

-- Cascade delete for Many-to-Many (remove pivot entries)
function Relationships:cascadeDeletePivot(pivotTable, localKey)
    if self.id then
        QueryBuilder:new(pivotTable)
            :where(localKey, "=", self.id)
            :delete()
    end
end

-- Has Many Through relationship (indirect relationship through another model)
-- Example: Country -> User -> Post  (Country has many Posts through Users)
function Relationships:hasManyThrough(finalModel, throughModel, firstKey, secondKey, localKey, secondLocalKey)
    if not finalModel or not finalModel.query then
        error("Invalid final model passed to hasManyThrough()")
    end
    if not throughModel or not throughModel.query then
        error("Invalid through model passed to hasManyThrough()")
    end

    localKey = localKey or "id"
    firstKey = firstKey or self.table .. "_id"
    secondLocalKey = secondLocalKey or "id"
    secondKey = secondKey or throughModel.table .. "_id"

    -- Get IDs from the through model
    local through_records = QueryBuilder:new(throughModel.table)
        :where(firstKey, "=", self[localKey])
        :get()

    if #through_records == 0 then
        return Collection:new({})
    end

    local through_ids = through_records:pluck(secondLocalKey):toArray()

    -- Get final models using the through IDs
    local results = finalModel:query()
        :whereIn(secondKey, through_ids)
        :get()

    return results:map(function(row)
        return finalModel:new(row)
    end)
end

-- Polymorphic One-to-Many (morph many)
-- Example: A Comment can belong to either a Post or a Video
function Relationships:morphMany(model, name, type_field, id_field)
    if not model or not model.query then
        error("Invalid model passed to morphMany()")
    end

    type_field = type_field or name .. "_type"
    id_field = id_field or name .. "_id"

    local results = model:query()
        :where(type_field, "=", self.table)
        :where(id_field, "=", self.id)
        :get()

    return results:map(function(row)
        return model:new(row)
    end)
end

-- Polymorphic Belongs To (morph to)
-- Example: Comment morphs to either Post or Video
function Relationships:morphTo(name, type_field, id_field)
    type_field = type_field or name .. "_type"
    id_field = id_field or name .. "_id"

    local related_type = self[type_field]
    local related_id = self[id_field]

    if not related_type or not related_id then
        return nil
    end

    -- You'll need to register models to resolve the type string
    -- For now, we'll return the type and ID
    -- In practice, you'd do: local Model = _G[related_type] or require("models." .. related_type:lower())
    return {
        type = related_type,
        id = related_id,
        -- In a real implementation, you'd fetch and return the actual model instance
    }
end

-- Polymorphic One-to-One (morph one)
function Relationships:morphOne(model, name, type_field, id_field)
    if not model or not model.query then
        error("Invalid model passed to morphOne()")
    end

    type_field = type_field or name .. "_type"
    id_field = id_field or name .. "_id"

    local result = model:query()
        :where(type_field, "=", self.table)
        :where(id_field, "=", self.id)
        :limit(1)
        :get()

    if result:count() > 0 then
        return model:new(result:first())
    end

    return nil
end

return Relationships