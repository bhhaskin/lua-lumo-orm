local DB = require("lumo.db")
local Migrations = require("lumo.migrations")
local busted = require("busted")

describe("Migrations", function()
    local db

    before_each(function()
        db = DB.connect(":memory:") -- Use in-memory SQLite database
        Migrations.setDB(db) -- Ensure Migrations has a database connection
    end)

    after_each(function()
        if db then
            db:close()
            db = nil
        end
    end)

    it("should initialize the migrations table", function()
        local result = db:query("SELECT name FROM sqlite_master WHERE type='table' AND name='migrations';")
        assert.is_not_nil(result[1])
        assert.are.equal("migrations", result[1].name)
    end)

    it("should apply a migration", function()
        local migration_name = "create_users_table"
        local up_sql = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);"

        local applied = Migrations:apply(migration_name, up_sql)
        assert.is_true(applied)

        local result = db:query("SELECT name FROM sqlite_master WHERE type='table' AND name='users';")
        assert.is_not_nil(result[1])
        assert.are.equal("users", result[1].name)
    end)

    it("should not apply the same migration twice", function()
        local migration_name = "create_users_table"
        local up_sql = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);"

        Migrations:apply(migration_name, up_sql)
        local reapplied = Migrations:apply(migration_name, up_sql)

        assert.is_false(reapplied)
    end)

    it("should rollback a migration", function()
        local migration_name = "create_users_table"
        local up_sql = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);"
        local down_sql = "DROP TABLE users;"

        Migrations:apply(migration_name, up_sql)
        local rolled_back = Migrations:rollback(migration_name, down_sql)
        assert.is_true(rolled_back)

        local result = db:query("SELECT name FROM sqlite_master WHERE type='table' AND name='users';")
        assert.are.equal(0, #result)
    end)
end)