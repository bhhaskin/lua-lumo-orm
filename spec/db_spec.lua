local DB = require("lumo.db")
local busted = require("busted")

describe("Database Connection", function()
    local db

    before_each(function()
        db = DB.connect(":memory:") -- Create a fresh database before each test
        db:execute([[CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);]]) -- Create new table
    end)

    after_each(function()
        if db then
            db:close() -- Close database after each test
            db = nil
        end
    end)

    it("should connect to an in-memory SQLite database", function()
        assert.is_not_nil(db)
    end)

    describe("Database Queries", function()

        it("should insert a record", function()
            local result = db:execute("INSERT INTO test (name) VALUES (?);", "Alice")
            assert.is_true(result)
        end)

        it("should retrieve inserted records", function()
            db:execute("INSERT INTO test (name) VALUES (?);", "Alice")

            local rows = db:query("SELECT * FROM test;")
            assert.is_not_nil(rows)
            assert.are.equal(1, #rows)
            assert.are.equal("Alice", rows[1].name)
        end)

        it("should delete a record", function()
            db:execute("INSERT INTO test (name) VALUES (?);", "Alice")

            local result = db:execute("DELETE FROM test WHERE name = ?;", "Alice")
            assert.is_true(result)

            local rows = db:query("SELECT * FROM test;")
            assert.are.equal(0, #rows)
        end)

        it("should retrieve the last inserted ID", function()
            db:execute("INSERT INTO test (name) VALUES (?);", "Alice")
            local last_id = db:lastInsertId()
            
            assert.is_not_nil(last_id)
            assert.are.equal(1, last_id) -- First record should have ID 1
            
            db:execute("INSERT INTO test (name) VALUES (?);", "Bob")
            local last_id_2 = db:lastInsertId()
            
            assert.is_not_nil(last_id_2)
            assert.are.equal(2, last_id_2) -- Second record should have ID 2
        end)
    end)
end)
