# Lumo ORM

Lumo ORM is a lightweight, Active Record-style ORM for Lua, designed to work with SQLite.
It provides an intuitive API for database interactions, including querying, relationships, and migrations.

## Features
- Active Record-style models
- Query Builder with chainable methods
- One-to-One, One-to-Many, and Many-to-Many relationships
- Migrations system with CLI support
- LuaRocks-compatible installation
- SQLite support via `lsqlite3complete`

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

-- Fetch all users
local users = User:all()

-- Find a user by ID
local user = User:find(1)
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