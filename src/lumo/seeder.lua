local Seeder = {}
Seeder.__index = Seeder

-- Registry of seeders
Seeder.seeders = {}

-- Register a seeder function
function Seeder.register(name, seedFn)
    if type(seedFn) ~= "function" then
        error("Seeder must be a function")
    end
    Seeder.seeders[name] = seedFn
end

-- Run all registered seeders
function Seeder:run()
    print("Running database seeders...")

    for name, seedFn in pairs(Seeder.seeders) do
        print("  Running seeder: " .. name)
        local success, err = pcall(seedFn)
        if not success then
            print("  [ERROR] Seeder '" .. name .. "' failed: " .. tostring(err))
        else
            print("  [OK] Seeder '" .. name .. "' completed successfully")
        end
    end

    print("Seeding complete!")
end

-- Run a specific seeder by name
function Seeder:runSeeder(name)
    if not Seeder.seeders[name] then
        error("Seeder '" .. name .. "' not found")
    end

    print("Running seeder: " .. name)
    local success, err = pcall(Seeder.seeders[name])
    if not success then
        print("[ERROR] Seeder failed: " .. tostring(err))
        return false
    end

    print("[OK] Seeder completed successfully")
    return true
end

-- Helper: Generate fake data
Seeder.fake = {
    -- Generate a random name
    name = function()
        local first_names = {"Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"}
        local last_names = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"}
        return first_names[math.random(#first_names)] .. " " .. last_names[math.random(#last_names)]
    end,

    -- Generate a random email
    email = function()
        local names = {"john", "jane", "alice", "bob", "charlie", "diana"}
        local domains = {"example.com", "test.com", "demo.com", "sample.org"}
        return names[math.random(#names)] .. math.random(100, 999) .. "@" .. domains[math.random(#domains)]
    end,

    -- Generate a random number between min and max
    number = function(min, max)
        min = min or 1
        max = max or 100
        return math.random(min, max)
    end,

    -- Generate a random boolean
    boolean = function()
        return math.random() > 0.5
    end,

    -- Generate lorem ipsum text
    text = function(words)
        words = words or 10
        local lorem = {"lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
                      "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore"}
        local result = {}
        for i = 1, words do
            table.insert(result, lorem[math.random(#lorem)])
        end
        return table.concat(result, " ")
    end,

    -- Pick a random element from a table
    choice = function(options)
        if type(options) ~= "table" or #options == 0 then
            error("choice() requires a non-empty table")
        end
        return options[math.random(#options)]
    end
}

return Seeder
