local Lumo = require("lumo")
Lumo.connect("database.sqlite")

local Migrations = require("lumo.migrations")

-- Load migration files
local migrations = {
    -- require("lumo.migrations.user_migration"), -- Add more here
}

-- CLI
local action = arg[1]

if action == "up" then
    Migrations:migrateUp(migrations)
elseif action == "down" then
    Migrations:migrateDown(migrations)
else
    print("Usage: lua migrate.lua up | down")
end