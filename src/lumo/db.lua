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
    if not stmt then
        print("[SQLite Error] Failed to prepare SQL:", sql, self.db:errmsg()) -- Debug log
        return nil
    end

    if stmt:bind_values(...) ~= sqlite3.OK then
        print("[SQLite Error] Failed to bind values:", self.db:errmsg()) -- Debug log
        stmt:finalize()
        return nil
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
        print("[SQLite Error] Failed to execute SQL:", sql, self.db:errmsg()) -- Debug log
        return false, self.db:errmsg()
    end

    if stmt:bind_values(...) ~= sqlite3.OK then
        print("[SQLite Error] Failed to bind values:", self.db:errmsg()) -- Debug log
        stmt:finalize()
        return false, self.db:errmsg()
    end

    local res = stmt:step()
    stmt:finalize()

    return res == sqlite3.DONE
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