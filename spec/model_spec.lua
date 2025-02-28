local DB = require("lumo.db")
local Model = require("lumo.model")
local Collection = require("lumo.collection")
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
        db:execute([[CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT, age INTEGER DEFAULT 0);]])
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
        user:update({ email = "alice@new.com" })
        
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

    it("should retrieve all records as a Collection", function()
        User:create({ name = "Alice", email = "alice@example.com" })
        User:create({ name = "Bob", email = "bob@example.com" })

        local users = User:all()
        assert.are.equal(2, users:count())
        assert.is_true(users:isInstanceOf(Collection))
    end)

    it("should increment and decrement a field", function()
        local user = User:create({ name = "Alice", email = "alice@example.com", age = 25 })

        user:increment("age", 5)
        assert.are.equal(30, user.age)

        user:decrement("age", 2)
        assert.are.equal(28, user.age)
    end)

    it("should find or create a record", function()
        local user1 = User:find_or_create({ email = "alice@example.com", name = "Alice" }, "email")
        local user2 = User:find_or_create({ email = "alice@example.com", name = "ShouldNotChange" }, "email")

        assert.are.equal(user1.id, user2.id)
        assert.are.equal("Alice", user2.name)
    end)

    it("should update or create a record", function()
        local user1 = User:update_or_create({ email = "alice@example.com" }, { name = "Alice Updated" })
        local user2 = User:update_or_create({ email = "alice@example.com" }, { name = "Alice Final" })

        assert.are.equal(user1.id, user2.id)
        assert.are.equal("Alice Final", user2.name)
    end)

    it("should use only selected fields", function()
        local user = User:create({ name = "Alice", email = "alice@example.com", age = 30 })
        local selected = user:only("name", "age")

        assert.are.equal("Alice", selected.name)
        assert.are.equal(30, selected.age)
        assert.is_nil(selected.email)
    end)

    it("should fill an existing record with new data", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        user:fill({ email = "alice@new.com", age = 29 })

        assert.are.equal("alice@new.com", user.email)
        assert.are.equal(29, user.age)
    end)

    it("should refresh a record", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        User:update_or_create({ email = "alice@example.com" }, { name = "Alice Updated" })

        user:refresh()
        assert.are.equal("Alice Updated", user.name)
    end)

    it("should check if a record exists", function()
        local user = User:create({ name = "Alice", email = "alice@example.com" })
        assert.is_true(user:exists())

        user:delete()
        assert.is_false(user:exists())
    end)
end)