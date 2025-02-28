local Collection = require("lumo.collection")

-- Sample data
local users = Collection:new({
    { id = 1, name = "Alice", email = "alice@example.com" },
    { id = 2, name = "Bob", email = "bob@example.com" },
    { id = 3, name = "Charlie", email = "charlie@example.com" },
    { id = 4, name = "Alice", email = "alice2@example.com" }
})

print("Total users:", users:count())

-- Filtering collection: Get users with the name "Alice"
local alices = users:filter(function(user)
    return user.name == "Alice"
end)

print("Users named Alice:", alices:count())
for _, user in ipairs(alices:all()) do
    print(user.id, user.name, user.email)
end

-- Plucking emails
local emails = users:pluck("email")
print("All emails:", table.concat(emails, ", "))

-- Mapping collection: Convert names to uppercase
local uppercased = users:map(function(user)
    user.name = string.upper(user.name)
    return user
end)

print("Uppercased names:")
for _, user in ipairs(uppercased:all()) do
    print(user.id, user.name, user.email)
end