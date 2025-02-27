local Lumo = require("lumo")
Lumo.connect("database.sqlite")

local Seeder = require("lumo.seeder")

print("Running database seeder...")
Seeder:run()
print("Seeding finished.")