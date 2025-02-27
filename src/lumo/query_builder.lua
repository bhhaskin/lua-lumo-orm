local QueryBuilder = {}
QueryBuilder.__index = QueryBuilder
QueryBuilder.db = nil -- Will be set dynamically

-- Set the database connection
function QueryBuilder.setDB(db)
    QueryBuilder.db = db
end

-- Constructor
function QueryBuilder:new(table)
    local instance = setmetatable({}, self)
    instance.table = table
    instance.conditions = {}
    instance.params = {}
    return instance
end

-- Add WHERE conditions
function QueryBuilder:where(field, operator, value)
    table.insert(self.conditions, field .. " " .. operator .. " ?")
    table.insert(self.params, value)
    return self
end

-- Execute the query
function QueryBuilder:get()
    local sql = "SELECT * FROM " .. self.table

    if #self.conditions > 0 then
        sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
    end

    return self.db:query(sql, table.unpack(self.params))
end

-- Insert a new record
function QueryBuilder:insert(data)
    local columns, placeholders, values = {}, {}, {}

    for column, value in pairs(data) do
        table.insert(columns, column)
        table.insert(values, value)
        table.insert(placeholders, "?")
    end

    local sql = string.format(
        "INSERT INTO %s (%s) VALUES (%s)",
        self.table,
        table.concat(columns, ", "),
        table.concat(placeholders, ", ")
    )

    local success = self.db:execute(sql, table.unpack(values))
    return success and self.db:lastInsertId() or nil
end

-- Update existing records and return success
function QueryBuilder:update(data)
    local updates, values = {}, {}

    for column, value in pairs(data) do
        table.insert(updates, column .. " = ?")
        table.insert(values, value)
    end

    local sql = string.format("UPDATE %s SET %s", self.table, table.concat(updates, ", "))

    if #self.conditions > 0 then
        sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
        for _, param in ipairs(self.params) do
            table.insert(values, param)
        end
    end

    return self.db:execute(sql, table.unpack(values))
end

-- Delete records and return success
function QueryBuilder:delete()
    local sql = "DELETE FROM " .. self.table

    if #self.conditions > 0 then
        sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
    end

    return self.db:execute(sql, table.unpack(self.params))
end

-- Get first record from query
function QueryBuilder:first()
    local results = self:get()
    return results and results[1] or nil
end

function QueryBuilder:limit(count)
    self.limit_count = "LIMIT " .. count
    return self
end


return QueryBuilder
