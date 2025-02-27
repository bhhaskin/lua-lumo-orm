local DB = require("lumo.db")
local Lumo = require("lumo")
local busted = require("busted")

describe("Lumo ORM", function()
    local db

    before_each(function()
        db = DB.connect(":memory:") -- Use in-memory SQLite database
        Lumo.connect(":memory:") -- Ensure Lumo connects to the database
    end)

    after_each(function()
        if db then
            db:close()
            db = nil
        end
    end)

    it("should connect to a database", function()
        assert.is_not_nil(Lumo.db)
    end)

    it("should provide access to QueryBuilder", function()
        local query = Lumo.query("users")
        assert.is_not_nil(query)
        assert.are.equal("users", query.table)
    end)

    it("should execute raw SQL queries", function()
        Lumo.db:execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);")
        Lumo.db:execute("INSERT INTO test (name) VALUES ('Alice');")
        
        local result = Lumo.db:query("SELECT * FROM test;")
        assert.is_not_nil(result[1])
        assert.are.equal("Alice", result[1].name)
    end)
end)
