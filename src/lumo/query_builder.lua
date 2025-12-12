local Collection = require("lumo.collection")

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
    instance.condition_operators = {} -- Track AND/OR between conditions
    instance.params = {}
    instance.select_columns = nil -- Specific columns to select
    instance.is_distinct = false
    instance.join_clauses = {}
    instance.group_by_columns = nil
    instance.having_conditions = {}
    instance.having_params = {}
    instance.order_by = nil
    instance.limit_count = nil
    instance.offset_count = nil
    return instance
end

-- Add WHERE conditions
function QueryBuilder:where(field, operator, value)
    if #self.conditions > 0 then
        table.insert(self.condition_operators, "AND")
    end
    table.insert(self.conditions, field .. " " .. operator .. " ?")
    table.insert(self.params, value)
    return self
end

-- Add OR WHERE conditions
function QueryBuilder:orWhere(field, operator, value)
    if #self.conditions > 0 then
        table.insert(self.condition_operators, "OR")
    end
    table.insert(self.conditions, field .. " " .. operator .. " ?")
    table.insert(self.params, value)
    return self
end

-- Add WHERE IN condition
function QueryBuilder:whereIn(field, values)
    if type(values) ~= "table" or #values == 0 then
        error("whereIn requires a non-empty table of values")
    end

    if #self.conditions > 0 then
        table.insert(self.condition_operators, "AND")
    end

    local placeholders = {}
    for _, value in ipairs(values) do
        table.insert(placeholders, "?")
        table.insert(self.params, value)
    end

    table.insert(self.conditions, field .. " IN (" .. table.concat(placeholders, ", ") .. ")")
    return self
end

-- Add WHERE NOT condition
function QueryBuilder:whereNot(field, operator, value)
    if #self.conditions > 0 then
        table.insert(self.condition_operators, "AND")
    end
    table.insert(self.conditions, "NOT (" .. field .. " " .. operator .. " ?)")
    table.insert(self.params, value)
    return self
end

-- Add WHERE NULL condition
function QueryBuilder:whereNull(field)
    if #self.conditions > 0 then
        table.insert(self.condition_operators, "AND")
    end
    table.insert(self.conditions, field .. " IS NULL")
    return self
end

-- Add WHERE NOT NULL condition
function QueryBuilder:whereNotNull(field)
    if #self.conditions > 0 then
        table.insert(self.condition_operators, "AND")
    end
    table.insert(self.conditions, field .. " IS NOT NULL")
    return self
end

-- Add raw WHERE condition
function QueryBuilder:whereRaw(sql, ...)
    if #self.conditions > 0 then
        table.insert(self.condition_operators, "AND")
    end
    table.insert(self.conditions, sql)
    for _, param in ipairs({...}) do
        table.insert(self.params, param)
    end
    return self
end

-- Select specific columns
function QueryBuilder:select(...)
    local columns = {...}
    if #columns == 0 then
        self.select_columns = nil
    else
        self.select_columns = table.concat(columns, ", ")
    end
    return self
end

-- Add DISTINCT
function QueryBuilder:distinct()
    self.is_distinct = true
    return self
end

-- Add JOIN clause
function QueryBuilder:join(table, first, operator, second, join_type)
    join_type = join_type or "INNER JOIN"
    table.insert(self.join_clauses, {
        type = join_type,
        table = table,
        first = first,
        operator = operator,
        second = second
    })
    return self
end

-- Add LEFT JOIN
function QueryBuilder:leftJoin(table, first, operator, second)
    return self:join(table, first, operator, second, "LEFT JOIN")
end

-- Add RIGHT JOIN
function QueryBuilder:rightJoin(table, first, operator, second)
    return self:join(table, first, operator, second, "RIGHT JOIN")
end

-- Add GROUP BY clause
function QueryBuilder:groupBy(...)
    local columns = {...}
    self.group_by_columns = table.concat(columns, ", ")
    return self
end

-- Add HAVING clause
function QueryBuilder:having(field, operator, value)
    table.insert(self.having_conditions, field .. " " .. operator .. " ?")
    table.insert(self.having_params, value)
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

-- Add OFFSET clause
function QueryBuilder:offset(count)
    self.offset_count = "OFFSET " .. count
    return self
end

-- Build WHERE clause with proper AND/OR operators
function QueryBuilder:buildWhereClause()
    if #self.conditions == 0 then
        return ""
    end

    local where_parts = {}
    for i, condition in ipairs(self.conditions) do
        if i == 1 then
            table.insert(where_parts, condition)
        else
            local operator = self.condition_operators[i - 1] or "AND"
            table.insert(where_parts, operator .. " " .. condition)
        end
    end

    return " WHERE " .. table.concat(where_parts, " ")
end

-- Execute the SELECT query
function QueryBuilder:get()
    -- Build SELECT clause
    local select_part = "SELECT "
    if self.is_distinct then
        select_part = select_part .. "DISTINCT "
    end
    select_part = select_part .. (self.select_columns or "*")

    local sql = select_part .. " FROM " .. self.table

    -- Add JOINs
    for _, join in ipairs(self.join_clauses) do
        sql = sql .. " " .. join.type .. " " .. join.table ..
              " ON " .. join.first .. " " .. join.operator .. " " .. join.second
    end

    -- Add WHERE clause
    sql = sql .. self:buildWhereClause()

    -- Add GROUP BY
    if self.group_by_columns then
        sql = sql .. " GROUP BY " .. self.group_by_columns
    end

    -- Add HAVING
    if #self.having_conditions > 0 then
        sql = sql .. " HAVING " .. table.concat(self.having_conditions, " AND ")
    end

    -- Add ORDER BY
    if self.order_by then
        sql = sql .. " " .. self.order_by
    end

    -- Add LIMIT
    if self.limit_count then
        sql = sql .. " " .. self.limit_count
    end

    -- Add OFFSET
    if self.offset_count then
        sql = sql .. " " .. self.offset_count
    end

    -- Combine params with having params
    local all_params = {}
    for _, p in ipairs(self.params) do
        table.insert(all_params, p)
    end
    for _, p in ipairs(self.having_params) do
        table.insert(all_params, p)
    end

    local results = self.db:query(sql, table.unpack(all_params))
    return Collection:new(results)
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

    sql = sql .. self:buildWhereClause()

    for _, param in ipairs(self.params) do
        table.insert(values, param)
    end

    return self.db:execute(sql, table.unpack(values))
end

-- Delete records and return success
function QueryBuilder:delete()
    if #self.conditions == 0 then
        error("DELETE queries must have a WHERE condition to prevent full table deletion.")
    end

    local sql = "DELETE FROM " .. self.table

    sql = sql .. self:buildWhereClause()

    return self.db:execute(sql, table.unpack(self.params))
end

-- Aggregation functions
function QueryBuilder:count(column)
    column = column or "*"
    local original_select = self.select_columns
    self:select("COUNT(" .. column .. ") as aggregate")
    local result = self:get()
    self.select_columns = original_select
    return result[1] and result[1].aggregate or 0
end

function QueryBuilder:sum(column)
    local original_select = self.select_columns
    self:select("SUM(" .. column .. ") as aggregate")
    local result = self:get()
    self.select_columns = original_select
    return result[1] and result[1].aggregate or 0
end

function QueryBuilder:avg(column)
    local original_select = self.select_columns
    self:select("AVG(" .. column .. ") as aggregate")
    local result = self:get()
    self.select_columns = original_select
    return result[1] and result[1].aggregate or 0
end

function QueryBuilder:min(column)
    local original_select = self.select_columns
    self:select("MIN(" .. column .. ") as aggregate")
    local result = self:get()
    self.select_columns = original_select
    return result[1] and result[1].aggregate or nil
end

function QueryBuilder:max(column)
    local original_select = self.select_columns
    self:select("MAX(" .. column .. ") as aggregate")
    local result = self:get()
    self.select_columns = original_select
    return result[1] and result[1].aggregate or nil
end

-- Check if records exist
function QueryBuilder:exists()
    local count = self:count()
    return count > 0
end

-- Pagination helper - get page with per_page items
function QueryBuilder:forPage(page, per_page)
    page = page or 1
    per_page = per_page or 15
    local offset_val = (page - 1) * per_page
    return self:offset(offset_val):limit(per_page)
end

-- Paginate results with metadata
function QueryBuilder:paginate(per_page, current_page)
    per_page = per_page or 15
    current_page = current_page or 1

    -- Get total count (before applying limit/offset)
    local count_builder = QueryBuilder:new(self.table)
    count_builder.conditions = self.conditions
    count_builder.condition_operators = self.condition_operators
    count_builder.params = self.params
    count_builder.join_clauses = self.join_clauses
    count_builder.group_by_columns = self.group_by_columns
    count_builder.having_conditions = self.having_conditions
    count_builder.having_params = self.having_params

    local total = count_builder:count()
    local last_page = math.ceil(total / per_page)

    -- Get the actual page data
    local data = self:forPage(current_page, per_page):get()

    return {
        data = data,
        total = total,
        per_page = per_page,
        current_page = current_page,
        last_page = last_page,
        from = ((current_page - 1) * per_page) + 1,
        to = math.min(current_page * per_page, total)
    }
end

-- Process large datasets in chunks
function QueryBuilder:chunk(size, callback)
    size = size or 100
    local page = 1

    repeat
        local results = self:forPage(page, size):get()

        if #results == 0 then
            break
        end

        callback(results, page)
        page = page + 1
    until #results < size
end

-- Bulk insert multiple records
function QueryBuilder:insertMany(records)
    if type(records) ~= "table" or #records == 0 then
        error("insertMany requires a non-empty table of records")
    end

    -- Get column names from first record
    local columns = {}
    for column, _ in pairs(records[1]) do
        table.insert(columns, column)
    end
    table.sort(columns) -- Ensure consistent order

    -- Build values for all records
    local all_values = {}
    local value_placeholders = {}

    for _, record in ipairs(records) do
        local record_values = {}
        for _, column in ipairs(columns) do
            table.insert(all_values, record[column])
            table.insert(record_values, "?")
        end
        table.insert(value_placeholders, "(" .. table.concat(record_values, ", ") .. ")")
    end

    local sql = string.format(
        "INSERT INTO %s (%s) VALUES %s",
        self.table,
        table.concat(columns, ", "),
        table.concat(value_placeholders, ", ")
    )

    return self.db:execute(sql, table.unpack(all_values))
end

return QueryBuilder