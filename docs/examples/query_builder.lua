-- Example usage of lumo.query_builder

local DB = require("lumo.db")
local QueryBuilder = require("lumo.query_builder")

-- Connect to a SQLite database
local db = DB.connect("example.sqlite")
QueryBuilder.setDB(db)

-- Create a table
local create_table_sql = [[
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
    );
]]
db:execute(create_table_sql)

-- Insert a record using QueryBuilder
local user_id = QueryBuilder:new("users"):insert({ name = "Alice", email = "alice@example.com" })
print("Inserted User ID:", user_id)

-- Retrieve a user
local user = QueryBuilder:new("users"):where("id", "=", user_id):first()
if user then
    print("User Found:", user.id, user.name, user.email)
end

-- Update a user
local updated = QueryBuilder:new("users"):where("id", "=", user_id):update({ name = "Alice Updated" })
print("Update Successful:", updated)

-- Delete a user
local deleted = QueryBuilder:new("users"):where("id", "=", user_id):delete()
print("Delete Successful:", deleted)

-- Close the database connection
db:close()
