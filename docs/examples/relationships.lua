-- Example usage of lumo.relationships

local DB = require("lumo.db")
local Model = require("lumo.model")

-- Connect to a SQLite database
local db = DB.connect("example.sqlite")
Model.setDB(db)

-- Define User model
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

function User:posts()
    return self:hasMany(Post, "user_id")
end

-- Define Post model
local Post = setmetatable({}, Model)
Post.__index = Post
Post.table = "posts"

function Post:user()
    return self:belongsTo(User, "user_id")
end

-- Create tables
local create_users_table = [[
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    );
]]

db:execute(create_users_table)

local create_posts_table = [[
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
]]

db:execute(create_posts_table)

-- Insert a user
local user = User:create({ name = "Alice" })
print("Inserted User:", user.id, user.name)

-- Insert posts for the user
local post1 = Post:create({ title = "First Post", user_id = user.id })
local post2 = Post:create({ title = "Second Post", user_id = user.id })
print("Inserted Posts:", post1.id, post1.title, "|", post2.id, post2.title)

-- Retrieve user's posts
local posts = user:posts()
print("User's Posts:")
for _, post in ipairs(posts) do
    print(post.id, post.title)
end

-- Retrieve post's user
local post_user = post1:user()
print("Post belongs to User:", post_user.id, post_user.name)

-- Close the database connection
db:close()