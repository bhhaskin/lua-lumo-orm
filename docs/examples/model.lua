local DB = require("lumo.db")
local Model = require("lumo.model")

-- Connect to an in-memory SQLite database
local db = DB.connect(":memory:")
Model.setDB(db)

-- Create a test table
db:execute([[
    CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        age INTEGER
    );
]])

-- Define a User model
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

-- **Create a new user**
local user = User:create({ name = "Alice", email = "alice@example.com", age = 25 })
print("Created User:", user.id, user.name, user.email, user.age)

-- **Find a user by ID**
local foundUser = User:find(user.id)
if foundUser then
    print("Found User:", foundUser.id, foundUser.name, foundUser.email)
end

-- **Update a user**
foundUser.email = "alice@newdomain.com"
foundUser:save()
print("Updated Email:", foundUser.email)

-- **Increment age**
foundUser:increment("age", 1)
print("Incremented Age:", foundUser.age)

-- **Retrieve all users as a collection**
local users = User:all()
print("Total Users:", users:count())

-- **Use where queries**
local filteredUsers = User:where("age", ">", 20):get()
print("Users older than 20:", filteredUsers:count())

-- **Find or create a user**
local existingOrNewUser = User:find_or_create({ email = "bob@example.com" }, { name = "Bob", age = 30 })
print("Find or Create User:", existingOrNewUser.id, existingOrNewUser.name)

-- **Update or create a user**
local updatedOrCreatedUser = User:update_or_create({ email = "bob@example.com" }, { age = 35 })
print("Update or Create User:", updatedOrCreatedUser.id, updatedOrCreatedUser.age)

-- **Delete a user**
local deleteSuccess = foundUser:delete()
print("User deleted:", deleteSuccess)

-- **Verify deletion**
local checkUser = User:find(user.id)
if not checkUser then
    print("User successfully deleted.")
end