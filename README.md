# Lumo ORM

Lumo ORM is a lightweight, Active Record-style ORM for Lua, designed to work with SQLite.
It provides an intuitive API for database interactions, including querying, relationships, and migrations.

## Features

### Core Features
- **Active Record-style models** with intuitive API
- **Advanced Query Builder** with chainable methods
- **Transaction support** with automatic rollback
- **Collections** with functional programming methods (map, filter, reduce, etc.)
- **Migrations system** with CLI support
- **Database seeding** with fake data generators
- **LuaRocks-compatible** installation
- **SQLite support** via `lsqlite3complete`

### Query Features
- Complex WHERE conditions (AND, OR, IN, NOT, NULL checks)
- JOINs (INNER, LEFT, RIGHT)
- Aggregations (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY and HAVING clauses
- DISTINCT queries
- Pagination with metadata
- Chunked processing for large datasets
- Raw SQL conditions
- Bulk insert optimization

### Model Features
- **Auto timestamps** (created_at, updated_at)
- **Soft deletes** with restore capability
- **Query scopes** for reusable filters
- **Attribute casting** (integer, boolean, string, json, datetime)
- **Mass assignment protection** (fillable/guarded)
- **Model events/hooks** (before/after create, save, update, delete)
- **Validation system** with built-in rules

### Relationships
- One-to-One (hasOne, belongsTo)
- One-to-Many (hasMany)
- Many-to-Many (belongsToMany)
- Has Many Through (indirect relationships)
- Polymorphic relationships (morphMany, morphOne, morphTo)
- Automatic cascade delete support
- Eager loading to reduce N+1 queries

## Installation

You can install Lumo ORM via LuaRocks:

```sh
luarocks install lua-lumo-orm
```

Or clone the repository manually:

```sh
git clone https://github.com/bhhaskin/lua-lumo-orm.git
cd lua-lumo-orm
luarocks make
```

## Usage

### Connecting to a Database

```lua
local Lumo = require("lumo")
Lumo.connect("database.sqlite")
```

### Defining a Model

```lua
local Model = require("lumo.model")

local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

return User
```

### Querying Data

```lua
local User = require("models.user")

-- Basic queries
local users = User:all() -- Returns a Collection
local user = User:find(1)
local first = User:first()

-- WHERE conditions
local activeUsers = User:where("status", "=", "active")
    :where("age", ">", 18)
    :orderBy("name", "ASC")
    :get()

-- OR conditions
local admins = User:where("role", "=", "admin")
    :orWhere("role", "=", "moderator")
    :get()

-- IN / NOT IN queries
local users = User:whereIn("id", {1, 2, 3, 4, 5}):get()

-- NULL checks
local verified = User:whereNotNull("email_verified_at"):get()
local unverified = User:whereNull("email_verified_at"):get()

-- NOT conditions
local notBanned = User:whereNot("status", "=", "banned"):get()

-- Raw SQL conditions
local users = User:whereRaw("age BETWEEN ? AND ?", 18, 65):get()

-- Select specific columns
local names = User:select("id", "name", "email"):get()

-- Distinct results
local countries = User:select("country"):distinct():get()

-- Working with Collections
for i, user in ipairs(users) do
    print(user.name)
end

-- Collection methods
local names = users:map(function(u) return u.name end)
local adults = users:filter(function(u) return u.age >= 18 end)
local sorted = users:sortBy("name")
local count = users:count()
```

### Creating a Record

```lua
local newUser = User:create({ name = "Alice", email = "alice@example.com" })
print("Created user:", newUser.id)
```

### Updating a Record

```lua
user:update({ name = "Alice Wonderland" })
```

### Deleting a Record

```lua
user:delete()
```

### Working with Relationships

```lua
-- Define a User model with posts relationship
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

function User:posts()
    return self:hasMany(Post, "user_id")
end

-- Define a Post model with user relationship
local Post = setmetatable({}, Model)
Post.__index = Post
Post.table = "posts"

function Post:user()
    return self:belongsTo(User, "user_id")
end

-- Use relationships (returns Model instances)
local user = User:find(1)
local posts = user:posts() -- Returns Collection of Post models

for i, post in ipairs(posts) do
    print(post.title)
    post:update({ title = "Updated Title" })
end

-- Belongs to relationship
local post = Post:find(1)
local author = post:user() -- Returns User model instance
print(author.name)
```

### Cascade Delete

```lua
-- Define cascade behavior
User.__cascadeDelete = { "posts" }

-- When user is deleted, all posts are automatically deleted
local user = User:find(1)
user:delete() -- Automatically deletes all user's posts
```

### Using Transactions

```lua
local Lumo = require("lumo")
Lumo.connect("database.sqlite")

-- Automatic transaction with rollback on error
Lumo.db:transaction(function()
    local user = User:create({ name = "Alice" })
    Post:create({ title = "First Post", user_id = user.id })
    Post:create({ title = "Second Post", user_id = user.id })
    -- If any operation fails, all changes are rolled back
end)

-- Manual transaction control
Lumo.db:beginTransaction()
local user = User:create({ name = "Bob" })
Lumo.db:commit()
-- Or Lumo.db:rollback() to undo changes
```

### Advanced Query Features

#### Aggregations

```lua
-- Count records
local total = User:count()
local activeCount = User:where("status", "=", "active"):count()

-- Sum, Average, Min, Max
local totalViews = Post:sum("views")
local avgAge = User:avg("age")
local youngest = User:min("age")
local oldest = User:max("age")
```

#### JOINs

```lua
-- Inner join
local results = User:query()
    :join("posts", "users.id", "=", "posts.user_id")
    :where("posts.published", "=", true)
    :get()

-- Left join
local results = User:query()
    :leftJoin("posts", "users.id", "=", "posts.user_id")
    :get()
```

#### GROUP BY and HAVING

```lua
-- Group by with having
local results = Post:query()
    :select("user_id", "COUNT(*) as post_count")
    :groupBy("user_id")
    :having("post_count", ">", 5)
    :get()
```

#### Pagination

```lua
-- Get page 2 with 15 items per page
local users = User:forPage(2, 15):get()

-- Paginate with metadata
local paginated = User:query():paginate(15, 1)
print(paginated.total)        -- Total records
print(paginated.current_page) -- Current page
print(paginated.last_page)    -- Total pages
for _, user in ipairs(paginated.data) do
    print(user.name)
end
```

#### Chunking Large Datasets

```lua
-- Process 100 records at a time
User:query():chunk(100, function(users, page)
    print("Processing page " .. page)
    for _, user in ipairs(users) do
        -- Process user
    end
end)
```

#### Bulk Operations

```lua
-- Insert many records at once
User:query():insertMany({
    { name = "Alice", email = "alice@example.com" },
    { name = "Bob", email = "bob@example.com" },
    { name = "Charlie", email = "charlie@example.com" }
})
```

### Model Features

#### Auto Timestamps

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"
User.timestamps = true -- Enable auto timestamps

-- When you create or update, created_at and updated_at are automatic
local user = User:create({ name = "Alice" })
print(user.created_at, user.updated_at)

user:update({ name = "Alice Updated" })
print(user.updated_at) -- Automatically updated
```

#### Soft Deletes

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"
User.softDelete = true -- Enable soft deletes

-- Soft delete (sets deleted_at timestamp)
local user = User:find(1)
user:delete()

-- Query excludes soft deleted by default
local users = User:all() -- Won't include deleted users

-- Include soft deleted records
local allUsers = User:withTrashed():all()

-- Only soft deleted records
local deleted = User:onlyTrashed():all()

-- Restore soft deleted record
user:restore()

-- Permanently delete
user:forceDelete()
```

#### Attribute Casting

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"
User.casts = {
    age = "integer",
    is_admin = "boolean",
    salary = "number",
    settings = "json",
    created_at = "datetime"
}

-- Values are automatically cast
local user = User:find(1)
print(type(user.age))      -- number
print(type(user.is_admin)) -- boolean
```

#### Query Scopes

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

-- Define a scope
function User:scopeActive(query)
    return query:where("status", "=", "active")
end

function User:scopeAdult(query)
    return query:where("age", ">=", 18)
end

-- Use scopes
local activeUsers = User:active():get()
local activeAdults = User:active():adult():get()
```

#### Mass Assignment Protection

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"
User.fillable = { "name", "email" } -- Only these can be mass-assigned
-- Or use guarded to blacklist fields
-- User.guarded = { "is_admin", "role" }

local user = User:new()
user:fillAttributes({
    name = "Alice",
    email = "alice@example.com",
    is_admin = true  -- This will be ignored
})
```

#### Model Events/Hooks

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"

function User:beforeCreate()
    print("About to create user")
    return true -- Return false to cancel
end

function User:afterCreate()
    print("User created!")
    -- Send welcome email, etc.
end

function User:beforeSave()
    -- Hash password, etc.
    return true
end

-- Available hooks:
-- beforeCreate, afterCreate
-- beforeSave, afterSave
-- beforeUpdate, afterUpdate
-- beforeDelete, afterDelete
```

#### Validation

```lua
local User = setmetatable({}, Model)
User.__index = User
User.table = "users"
User.rules = {
    name = "required|min:3|max:255",
    email = "required|email|unique:users",
    age = "numeric|min:18"
}

-- Validation runs automatically on create
local user = User:create({
    name = "Al",  -- Too short
    email = "invalid-email"
})
-- Error: Validation failed: name must be at least 3 characters, email must be a valid email address

-- Manual validation
local valid, errors = User:validate(data)
if not valid then
    print(table.concat(errors, ", "))
end
```

### Advanced Relationships

#### Has Many Through

```lua
-- Country -> User -> Post
local Country = setmetatable({}, Model)
Country.__index = Country
Country.table = "countries"

function Country:posts()
    return self:hasManyThrough(Post, User, "country_id", "user_id")
end

local country = Country:find(1)
local posts = country:posts() -- All posts from users in this country
```

#### Polymorphic Relationships

```lua
-- Comments can belong to either Posts or Videos
local Comment = setmetatable({}, Model)
Comment.__index = Comment
Comment.table = "comments"

function Comment:commentable()
    return self:morphTo("commentable")
end

-- Post has many comments (polymorphic)
local Post = setmetatable({}, Model)
Post.__index = Post
Post.table = "posts"

function Post:comments()
    return self:morphMany(Comment, "commentable")
end

local post = Post:find(1)
local comments = post:comments() -- All comments for this post
```

### Database Seeding

```lua
local Seeder = require("lumo.seeder")

-- Register a seeder
Seeder.register("UserSeeder", function()
    local User = require("models.user")

    for i = 1, 10 do
        User:create({
            name = Seeder.fake.name(),
            email = Seeder.fake.email(),
            age = Seeder.fake.number(18, 65),
            country = Seeder.fake.choice({"USA", "UK", "Canada"})
        })
    end
end)

-- Run seeders
Seeder:run()  -- Run all
Seeder:runSeeder("UserSeeder")  -- Run specific one
```

### Running Migrations

To apply migrations:
```sh
lua bin/migrate.lua up
```

To rollback:
```sh
lua bin/migrate.lua down
```

## Running Tests

Lumo ORM includes a test suite using `busted`. You can run tests manually with:

```sh
docker build -f Dockerfile.dev -t lumo-orm-test .
docker run --rm lumo-orm-test
```

### Using Makefile for Automation

Instead of manually building and running the Docker container, you can use the provided `Makefile` for convenience.

#### **Build the Docker Image**
```sh
make build
```
This will build the Docker image using `Dockerfile.dev`.

#### **Run Tests**
```sh
make test
```
This will build the image (if not already built) and run the test suite inside a temporary container.

#### **Open a Shell in the Container**
```sh
make shell
```
This will open an interactive shell inside the Docker container for debugging.

#### **Clean Up Docker Images**
```sh
make clean
```
Removes the built Docker image to free up space.

## Contributing
Pull requests are welcome! Please follow the project structure and ensure tests pass before submitting.

## License
This project is licensed under the MIT License.