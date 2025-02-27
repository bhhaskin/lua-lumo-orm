-- Example usage of lumo.migrations

local DB = require("lumo.db")
local Migrations = require("lumo.migrations")

-- Connect to a SQLite database
local db = DB.connect("example.sqlite")
Migrations.setDB(db)

-- Define a migration
local migration_name = "create_users_table"
local up_sql = [[
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
    );
]]
local down_sql = "DROP TABLE users;"

-- Apply the migration
local applied = Migrations:apply(migration_name, up_sql)
if applied then
    print("Migration applied:", migration_name)
else
    print("Migration already applied:", migration_name)
end

-- Rollback the migration
local rolled_back = Migrations:rollback(migration_name, down_sql)
if rolled_back then
    print("Migration rolled back:", migration_name)
else
    print("Migration not found:", migration_name)
end

-- Close the database connection
db:close()
