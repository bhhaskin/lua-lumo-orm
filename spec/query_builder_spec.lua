local DB = require("lumo.db")
local QueryBuilder = require("lumo.query_builder")
local busted = require("busted")

describe("Query Builder", function()
    local db

    before_each(function()
        db = DB.connect(":memory:") -- Create a fresh database before each test
        db:execute([[DROP TABLE IF EXISTS users;]])
        db:execute([[CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);]])
        QueryBuilder.setDB(db)
    end)

    after_each(function()
        if db then
            db:close()
            db = nil
        end
    end)

    it("should insert a record", function()
        local id = QueryBuilder:new("users"):insert({ name = "Alice", email = "alice@example.com" })
        assert.is_not_nil(id)
        assert.are.equal(1, id) -- Should be first inserted row
    end)

    it("should retrieve a record", function()
        QueryBuilder:new("users"):insert({ name = "Alice", email = "alice@example.com" })
        local user = QueryBuilder:new("users"):where("name", "=", "Alice"):first()
        assert.is_not_nil(user)
        assert.are.equal("Alice", user.name)
        assert.are.equal("alice@example.com", user.email)
    end)

    it("should update a record", function()
        QueryBuilder:new("users"):insert({ name = "Alice", email = "alice@example.com" })
        local updated = QueryBuilder:new("users"):where("name", "=", "Alice"):update({ email = "alice@new.com" })
        assert.is_true(updated)

        local user = QueryBuilder:new("users"):where("name", "=", "Alice"):first()
        assert.are.equal("alice@new.com", user.email)
    end)

    it("should delete a record", function()
        QueryBuilder:new("users"):insert({ name = "Alice", email = "alice@example.com" })
        local deleted = QueryBuilder:new("users"):where("name", "=", "Alice"):delete()
        assert.is_true(deleted)

        local user = QueryBuilder:new("users"):where("name", "=", "Alice"):first()
        assert.is_nil(user)
    end)

    it("should retrieve multiple records", function()
        QueryBuilder:new("users"):insert({ name = "Alice", email = "alice@example.com" })
        QueryBuilder:new("users"):insert({ name = "Bob", email = "bob@example.com" })

        local users = QueryBuilder:new("users"):get()
        assert.are.equal(2, #users)
    end)
end)