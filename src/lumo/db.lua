local sqlite3 = require("lsqlite3complete")

local DB = {}
DB.__index = DB

function DB.connect(path)
    local instance = setmetatable({}, DB)
    instance.db = sqlite3.open(path)
    return instance
end

function DB:close()
    if self.db then
        self.db:close()
        self.db = nil
    end
end

-- Run a query and return rows
function DB:query(sql, ...)
    local stmt = self.db:prepare(sql)
    if not stmt then return nil end

    stmt:bind_values(...)
    
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
    if not stmt then return false end

    stmt:bind_values(...)
    local res = stmt:step()
    stmt:finalize()

    return res == sqlite3.DONE
end

-- Get the last inserted ID
function DB:lastInsertId()
    return self.db:last_insert_rowid()
end

return DB
