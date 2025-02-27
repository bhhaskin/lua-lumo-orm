-- Example usage of Lumo ORM

local Lumo = require("lumo")

-- Connect to a SQLite database
Lumo.connect("example.sqlite")

-- Define a User model
local User = setmetatable({}, Lumo.Model)
User.__index = User
User.table = "users"

-- Create a users table
local create_table_sql = [[
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
    );
]]
Lumo.db:execute(create_table_sql)

-- Insert a user
local user = User:create({ name = "Alice", email = "alice@example.com" })
print("Inserted User:", user.id, user.name, user.email)

-- Find a user by ID
local found_user = User:find(user.id)
if found_user then
    print("User Found:", found_user.id, found_user.name, found_user.email)
end

-- Update a user
local success = found_user:update({ name = "Alice Updated" })
print("Update Successful:", success)

-- Retrieve all users
local users = User:all()
print("All Users:")
for _, u in ipairs(users) do
    print(u.id, u.name, u.email)
end

-- Delete a user
local deleted = found_user:delete()
print("Delete Successful:", deleted)

-- Close the database connection
Lumo.db:close()
