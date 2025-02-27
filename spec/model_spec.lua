local DB = require("lumo.db")
local Model = require("lumo.model")
local busted = require("busted")

-- Define a test model
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

describe("Model", function()
    local db

    before_each(function()
        db = DB.connect(":memory:") -- Use in-memory SQLite database
        db:execute([[DROP TABLE IF EXISTS users;]])
        db:execute([[CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);]])
        Model.setDB(db) -- Ensure models have a database connection
    end)

    after_each(function()
        if db then
            db:close()
            db = nil
        end
    end)

    it("should insert a record", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        assert.is_not_nil(user)
        assert.is_not_nil(user.id)
        assert.are.equal("Alice", user.name)
        assert.are.equal("alice@example.com", user.email)
    end)

    it("should retrieve a record by ID", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        local found = User:find(user.id)
        assert.is_not_nil(found)
        assert.are.equal("Alice", found.name)
        assert.are.equal("alice@example.com", found.email)
    end)

    it("should update a record", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        local success = user:update({ email = "alice@new.com" })
        assert.is_true(success)
        
        local updated = User:find(user.id)
        assert.is_not_nil(updated)
        assert.are.equal("alice@new.com", updated.email)
    end)

    it("should delete a record", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        local success = user:delete()
        assert.is_true(success)
        
        local deleted = User:find(user.id)
        assert.is_nil(deleted)
    end)
    
    it("should retrieve all records", function()
        User:create({ name = "Alice", email = "alice@example.com" })
        User:create({ name = "Bob", email = "bob@example.com" })

        local users = User:all()
        assert.are.equal(2, #users)
    end)
end)
