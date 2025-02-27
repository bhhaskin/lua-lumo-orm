local DB = require("lumo.db")
local Model = require("lumo.model")
local QueryBuilder = require("lumo.query_builder")
local Migrations = require("lumo.migrations")

local Lumo = {
   _VERSION = '0.1-0'
}

function Lumo.connect(db_path)
    local db = DB.connect(db_path)
    Model.setDB(db)
    QueryBuilder.setDB(db)
    Migrations.setDB(db)
    return db
end

Lumo.Model = Model
Lumo.QueryBuilder = QueryBuilder
Lumo.Migrations = Migrations

return Lumo