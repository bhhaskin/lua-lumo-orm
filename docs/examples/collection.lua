local Collection = require("lumo.collection")

-- Sample data
local users = {
    { id = 1, name = "Alice", age = 28 },
    { id = 2, name = "Bob", age = 35 },
    { id = 3, name = "Charlie", age = 24 },
    { id = 4, name = "David", age = 30 }
}

-- Create a collection
local userCollection = Collection:new(users)

print("---- Original Collection ----")
for _, user in ipairs(userCollection:toArray()) do
    print(user.id, user.name, user.age)
end

-- Map: Add a new property
local updatedUsers = userCollection:map(function(user)
    user.isAdult = user.age >= 18
    return user
end)

print("\n---- Users with isAdult field ----")
for _, user in ipairs(updatedUsers:toArray()) do
    print(user.id, user.name, user.age, "isAdult:", user.isAdult)
end

-- Filter: Get users older than 25
local filteredUsers = userCollection:filter(function(user)
    return user.age > 25
end)

print("\n---- Users older than 25 ----")
for _, user in ipairs(filteredUsers:toArray()) do
    print(user.id, user.name, user.age)
end

-- First and Last
print("\nFirst user:", userCollection:first().name)
print("Last user:", userCollection:last().name)

-- Pluck: Extract names
local names = userCollection:pluck("name")
print("\n---- User Names ----")
for _, name in ipairs(names) do
    print(name)
end

-- Sorting by age
local sortedUsers = userCollection:sortBy("age")
print("\n---- Users Sorted by Age ----")
for _, user in ipairs(sortedUsers:toArray()) do
    print(user.id, user.name, user.age)
end

-- Reverse
local reversedUsers = userCollection:reverse()
print("\n---- Users in Reverse Order ----")
for _, user in ipairs(reversedUsers:toArray()) do
    print(user.id, user.name, user.age)
end

-- Reduce: Get total age sum
local totalAge = userCollection:reduce(function(acc, user)
    return acc + user.age
end, 0)
print("\nTotal age of all users:", totalAge)

-- Check if collection contains a user older than 30
local hasOlderUser = userCollection:contains(function(user)
    return user.age > 30
end)
print("\nContains user older than 30?", hasOlderUser)