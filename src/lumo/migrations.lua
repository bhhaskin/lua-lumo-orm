local QueryBuilder = require("lumo.query_builder")

local Migrations = {}
Migrations.__index = Migrations
Migrations.db = nil -- Will be set dynamically

-- Set database connection
function Migrations.setDB(db)
    Migrations.db = db
    QueryBuilder.setDB(db)
    Migrations:initialize()
end

-- Create a migrations table to track applied migrations
function Migrations:initialize()
    self.db:execute([[
        CREATE TABLE IF NOT EXISTS migrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]])
end

-- Check if a migration has been applied
function Migrations:hasRun(name)
    local result = QueryBuilder:new("migrations"):where("name", "=", name):get()
    return #result > 0
end

-- Apply a migration
function Migrations:apply(name, up)
    if self:hasRun(name) then
        print("Migration already applied:", name)
        return false
    end

    -- Run the `up` migration (table creation/modification)
    local success, err = self.db:execute(up)
    if not success then
        print("[Migration Error] Failed to apply migration:", name, "Error:", err)
        return false
    end

    -- Record migration as applied
    QueryBuilder:new("migrations"):insert({ name = name })
    print("Migration applied:", name)
    return true
end

-- Rollback a migration
function Migrations:rollback(name, down)
    if not self:hasRun(name) then
        print("Migration not found:", name)
        return false
    end

    -- Run the `down` migration (rollback)
    local success, err = self.db:execute(down)
    if not success then
        print("[Migration Error] Failed to rollback migration:", name, "Error:", err)
        return false
    end

    -- Remove the migration record
    QueryBuilder:new("migrations"):where("name", "=", name):delete()
    print("Migration rolled back:", name)
    return true
end

-- Apply all pending migrations
function Migrations:migrateUp(migrations)
    for _, migration in ipairs(migrations) do
        local success = self:apply(migration.name, migration.up)
        if not success then
            print("[Migration Error] Stopping migration process due to failure.")
            break
        end
    end
end

-- Rollback all applied migrations
function Migrations:migrateDown(migrations)
    for i = #migrations, 1, -1 do
        local success = self:rollback(migrations[i].name, migrations[i].down)
        if not success then
            print("[Migration Error] Stopping rollback due to failure.")
            break
        end
    end
end

-- Create pivot table with configurable foreign keys
function Migrations:createPivotTable(name, column1, refTable1, column2, refTable2)
    local sql = string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            %s INTEGER NOT NULL,
            %s INTEGER NOT NULL,
            PRIMARY KEY (%s, %s),
            FOREIGN KEY (%s) REFERENCES %s(id) ON DELETE CASCADE,
            FOREIGN KEY (%s) REFERENCES %s(id) ON DELETE CASCADE
        );
    ]], name, column1, column2, column1, column2, column1, refTable1, column2, refTable2)

    self.db:execute(sql)
end

return Migrations