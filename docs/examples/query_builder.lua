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

-- Query with multiple conditions
local users = QueryBuilder:new("users")
    :where("name", "LIKE", "%Alice%")
    :where("id", ">", 5)
    :orderBy("name", "ASC")
    :get()

print("Found users:", #users)
for i, user in ipairs(users) do
    print(user.id, user.name, user.email)
end

-- OR conditions
local users_or = QueryBuilder:new("users")
    :where("id", "=", 1)
    :orWhere("id", "=", 2)
    :get()

print("Users with OR condition:", #users_or)

-- IN queries
local specific_users = QueryBuilder:new("users")
    :whereIn("id", {user_id, 2, 3})
    :get()

print("Users with IN clause:", #specific_users)

-- Update a user
local updated = QueryBuilder:new("users"):where("id", "=", user_id):update({ name = "Alice Updated" })
print("Update Successful:", updated)

-- Delete a user
local deleted = QueryBuilder:new("users"):where("id", "=", user_id):delete()
print("Delete Successful:", deleted)

-- Close the database connection
db:close()
