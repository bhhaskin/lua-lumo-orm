-- Example usage of lumo.model

local DB = require("lumo.db")
local Model = require("lumo.model")

-- Connect to a SQLite database
local db = DB.connect("example.sqlite")
Model.setDB(db)

-- Define a User model
local User = setmetatable({}, Model)
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
db:execute(create_table_sql)

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

-- Delete a user
local deleted = found_user:delete()
print("Delete Successful:", deleted)

-- Close the database connection
db:close()
