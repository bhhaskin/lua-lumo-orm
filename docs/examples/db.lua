-- Example usage of lumo.db

local DB = require("lumo.db")

-- Connect to a SQLite database
local db = DB.connect("example.sqlite")

-- Create a table
local create_table_sql = [[
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
    );
]]
db:execute(create_table_sql)

-- Insert a record
local insert_sql = "INSERT INTO users (name, email) VALUES (?, ?);"
db:execute(insert_sql, "Alice", "alice@example.com")

-- Query records
local results = db:query("SELECT * FROM users;")
for _, user in ipairs(results) do
    print("User:", user.id, user.name, user.email)
end

-- Close the database connection
db:close()
