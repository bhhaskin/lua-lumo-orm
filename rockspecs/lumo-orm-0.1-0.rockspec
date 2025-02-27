package = "lumo-orm"
version = "0.1-0"
source = {
    url = "git+https://github.com/bhhaskin/lua-lumo-orm.git",
    branch = "main"
}
description = {
    summary = "A lightweight Active Record ORM for Lua with SQLite support",
    detailed = [[
        Lumo-ORM provides an Eloquent-style ORM for Lua, built to work with SQLite.
        It includes migrations, a query builder, relationships, and Active Record pattern support.
    ]],
    license = "MIT",
    homepage = "https://github.com/bhhaskin/lua-lumo-orm"
}
dependencies = {
    "lua >= 5.1",
    "lsqlite3complete"
}
build = {
    type = "builtin",
    modules = {
        ["lumo"] = "src/lumo.lua",
        ["lumo.db"] = "src/lumo/db.lua",
        ["lumo.model"] = "src/lumo/model.lua",
        ["lumo.query_builder"] = "src/lumo/query_builder.lua",
        ["lumo.relationships"] = "src/lumo/relationships.lua",
        ["lumo.migrations"] = "src/lumo/migrations.lua",
    }
}
