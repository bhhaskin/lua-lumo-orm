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

-- Retrieve all users (returns a Collection)
local users = User:all()
print("Total Users:", #users)

-- Collections support array-like access and iteration
for i, u in ipairs(users) do
    print(u.id, u.name, u.email)
end

-- Collection methods for functional programming
local names = users:map(function(u) return u.name end)
local emails = users:pluck("email")
local sorted = users:sortBy("name", true)

print("Names:", table.concat(names:toArray(), ", "))
print("First user:", users:first().name)
print("Last user:", users:last().name)

-- Advanced queries with collections
local admins = User:where("role", "=", "admin")
    :orWhere("role", "=", "moderator")
    :get()

local activeUsers = User:whereIn("status", {"active", "premium"}):get()

-- Transactions
Lumo.db:transaction(function()
    User:create({ name = "Bob", email = "bob@example.com" })
    User:create({ name = "Carol", email = "carol@example.com" })
    -- If any fails, both are rolled back
end)

-- Delete a user
local deleted = found_user:delete()
print("Delete Successful:", deleted)

-- Close the database connection
Lumo.db:close()
