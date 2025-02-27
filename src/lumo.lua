local DB = require("lumo.db")
local Model = require("lumo.model")
local QueryBuilder = require("lumo.query_builder")
local Migrations = require("lumo.migrations")

local Lumo = {
   _VERSION = '0.1-0',
   db = nil -- Store database connection
}

function Lumo.connect(db_path)
    Lumo.db = DB.connect(db_path) -- Store DB connection in Lumo.db
    Model.setDB(Lumo.db)
    QueryBuilder.setDB(Lumo.db)
    Migrations.setDB(Lumo.db)
    return Lumo.db
end

-- Provide access to QueryBuilder
function Lumo.query(table)
    if not Lumo.db then error("Database not connected. Call Lumo.connect() first.") end
    return QueryBuilder:new(table)
end

Lumo.Model = Model
Lumo.QueryBuilder = QueryBuilder
Lumo.Migrations = Migrations

return Lumo