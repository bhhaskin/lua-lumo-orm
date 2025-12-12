local sqlite3 = require("lsqlite3complete")

local DB = {}
DB.__index = DB

function DB.connect(path)
    local instance = setmetatable({}, DB)
    instance.db = sqlite3.open(path)
    instance.in_transaction = false
    return instance
end

function DB:close()
    if self.db then
        self.db:close()
        self.db = nil
    end
end

-- Begin a transaction
function DB:beginTransaction()
    if self.in_transaction then
        error("Transaction already in progress")
    end
    local success = self:execute("BEGIN TRANSACTION")
    if success then
        self.in_transaction = true
    end
    return success
end

-- Commit a transaction
function DB:commit()
    if not self.in_transaction then
        error("No transaction in progress")
    end
    local success = self:execute("COMMIT")
    if success then
        self.in_transaction = false
    end
    return success
end

-- Rollback a transaction
function DB:rollback()
    if not self.in_transaction then
        error("No transaction in progress")
    end
    local success = self:execute("ROLLBACK")
    if success then
        self.in_transaction = false
    end
    return success
end

-- Execute a function within a transaction
function DB:transaction(fn)
    local success, err = pcall(function()
        self:beginTransaction()
        fn()
        self:commit()
    end)

    if not success then
        if self.in_transaction then
            self:rollback()
        end
        error(err)
    end

    return true
end

-- Run a query and return rows
function DB:query(sql, ...)
    local stmt = self.db:prepare(sql)
    if not stmt then
        error("[SQLite Error] Failed to prepare SQL: " .. sql .. " - " .. self.db:errmsg())
    end

    if stmt:bind_values(...) ~= sqlite3.OK then
        local err = self.db:errmsg()
        stmt:finalize()
        error("[SQLite Error] Failed to bind values: " .. err)
    end

    local results = {}
    for row in stmt:nrows() do
        table.insert(results, row)
    end

    stmt:finalize()
    return results
end

-- Execute a statement (for INSERT, UPDATE, DELETE)
function DB:execute(sql, ...)
    local stmt = self.db:prepare(sql)
    if not stmt then
        error("[SQLite Error] Failed to execute SQL: " .. sql .. " - " .. self.db:errmsg())
    end

    if stmt:bind_values(...) ~= sqlite3.OK then
        local err = self.db:errmsg()
        stmt:finalize()
        error("[SQLite Error] Failed to bind values: " .. err)
    end

    local res = stmt:step()
    stmt:finalize()

    if res ~= sqlite3.DONE then
        error("[SQLite Error] Statement execution failed: " .. self.db:errmsg())
    end

    return true
end

-- Get the last inserted ID
function DB:lastInsertId()
    if not self.db then
        print("[SQLite Error] Attempted to get last insert ID on a closed database")
        return nil
    end
    return self.db:last_insert_rowid()
end

return DB