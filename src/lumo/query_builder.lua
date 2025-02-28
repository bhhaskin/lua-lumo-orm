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
    instance.order_by = nil
    instance.limit_count = nil
    return instance
end

-- Add WHERE conditions
function QueryBuilder:where(field, operator, value)
    table.insert(self.conditions, field .. " " .. operator .. " ?")
    table.insert(self.params, value)
    return self
end

-- Add ORDER BY clause
function QueryBuilder:orderBy(field, direction)
    self.order_by = "ORDER BY " .. field .. " " .. (direction or "ASC")
    return self
end

-- Add LIMIT clause
function QueryBuilder:limit(count)
    self.limit_count = "LIMIT " .. count
    return self
end

-- Execute the SELECT query
function QueryBuilder:get()
    local sql = "SELECT * FROM " .. self.table

    if #self.conditions > 0 then
        sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
    end

    if self.order_by then
        sql = sql .. " " .. self.order_by
    end

    if self.limit_count then
        sql = sql .. " " .. self.limit_count
    end

    return self.db:query(sql, table.unpack(self.params))
end

-- Get the first record
function QueryBuilder:first()
    self:limit(1)
    local results = self:get()
    return results and results[1] or nil
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
    if success then
        return self.db:lastInsertId()
    end
    return nil
end

-- Update existing records and return success
function QueryBuilder:update(data)
    if #self.conditions == 0 then
        error("UPDATE queries must have a WHERE condition to prevent full table updates.")
    end

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
    if #self.conditions == 0 then
        error("DELETE queries must have a WHERE condition to prevent full table deletion.")
    end

    local sql = "DELETE FROM " .. self.table

    if #self.conditions > 0 then
        sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
    end

    return self.db:execute(sql, table.unpack(self.params))
end

return QueryBuilder