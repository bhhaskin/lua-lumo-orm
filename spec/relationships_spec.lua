local DB = require("lumo.db")
local Model = require("lumo.model")
local busted = require("busted")

-- Define test models
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

local Post = setmetatable({}, Model)
Post.__index = Post
Post.table = "posts"

describe("Model Relationships", function()
    local db

    before_each(function()
        db = DB.connect(":memory:")
        db:execute([[DROP TABLE IF EXISTS users;]])
        db:execute([[DROP TABLE IF EXISTS posts;]])
        db:execute([[CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);]])
        db:execute([[CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT, user_id INTEGER, FOREIGN KEY(user_id) REFERENCES users(id));]])
        Model.setDB(db)

        -- Define relationships inside `before_each`
        function User:posts()
            return self:hasMany(Post, "user_id")
        end

        function Post:user()
            return self:belongsTo(User, "user_id")
        end

        -- Define cascade delete behavior for User
        User.__cascadeDelete = { "posts" }
    end)

    after_each(function()
        if db then
            db:close()
            db = nil
        end
    end)

    it("should retrieve a user's posts", function()
        local user = User:create({ name = "Alice" })
        Post:create({ title = "First Post", user_id = user.id })
        Post:create({ title = "Second Post", user_id = user.id })

        local posts = user:posts()
        assert.are.equal(2, #posts)
        assert.are.equal("First Post", posts[1].title)
        assert.are.equal("Second Post", posts[2].title)
    end)

    it("should retrieve the user of a post", function()
        local user = User:create({ name = "Alice" })
        local post = Post:create({ title = "First Post", user_id = user.id })

        local post_user = post:user()
        assert.is_not_nil(post_user)
        assert.are.equal("Alice", post_user.name)
    end)

    it("should cascade delete a user's posts", function()
        local user = User:create({ name = "Alice" })
        local post1 = Post:create({ title = "First Post", user_id = user.id })
        local post2 = Post:create({ title = "Second Post", user_id = user.id })

        -- Ensure posts exist before deletion
        local posts_before = user:posts()
        assert.are.equal(2, #posts_before)

        -- Delete the user (should cascade delete posts)
        local success = user:delete()
        assert.is_true(success)

        -- Ensure posts are deleted
        local posts_after = Post:all()
        assert.are.equal(0, #posts_after)
    end)
end)