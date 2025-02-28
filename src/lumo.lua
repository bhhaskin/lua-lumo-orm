local DB = require("lumo.db")
local Model = require("lumo.model")
local QueryBuilder = require("lumo.query_builder")
local Migrations = require("lumo.migrations")

local Lumo = {
   _VERSION = '1.0-0',
   db = nil, -- Store database connection
   _db_path = nil -- Store database path for reconnecting
}

function Lumo.connect(db_path)
    local db, err = DB.connect(db_path)
    if not db then
        error("Failed to connect to the database: " .. (err or "Unknown error"))
    end
    Lumo.db = db
    Lumo._db_path = db_path -- Store path for reconnection
    Model.setDB(db)
    QueryBuilder.setDB(db)
    Migrations.setDB(db)
    return db
end

function Lumo.close()
    if Lumo.db then
        Lumo.db:close()
        Lumo.db = nil
    end
end

function Lumo.getDB()
    if not Lumo.db then
        error("Database not connected. Call Lumo.connect() first.")
    end
    return Lumo.db
end

function Lumo.query(table)
    if not Lumo.db then
        error("Database not connected. Call Lumo.connect() first.")
    end
    return QueryBuilder:new(table)
end

Lumo.Model = Model
Lumo.QueryBuilder = QueryBuilder
Lumo.Migrations = Migrations

return Lumo