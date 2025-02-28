local Collection = require("lumo.collection")
local busted = require("busted")

describe("Collection", function()

    it("should create a collection", function()
        local col = Collection:new({1, 2, 3})
        assert.are.equal(3, col:count())
    end)

    it("should map over a collection", function()
        local col = Collection:new({1, 2, 3})
        local new_col = col:map(function(item) return item * 2 end)

        assert.are.same({2, 4, 6}, new_col:toArray())
    end)

    it("should filter a collection", function()
        local col = Collection:new({1, 2, 3, 4, 5})
        local filtered = col:filter(function(item) return item % 2 == 0 end)

        assert.are.same({2, 4}, filtered:toArray())
    end)

    it("should get the first item", function()
        local col = Collection:new({10, 20, 30})
        assert.are.equal(10, col:first())
    end)

    it("should get the last item", function()
        local col = Collection:new({10, 20, 30})
        assert.are.equal(30, col:last())
    end)

    it("should convert to a plain Lua table", function()
        local col = Collection:new({10, 20, 30})
        assert.are.same({10, 20, 30}, col:toArray())
    end)

    it("should count the number of items", function()
        local col = Collection:new({1, 2, 3, 4})
        assert.are.equal(4, col:count())
    end)

    it("should check if an instance is a Collection", function()
        local col = Collection:new({1, 2, 3})
        assert.is_true(col:isInstanceOf(Collection))
    end)

    it("should pluck a field from a collection of tables", function()
        local col = Collection:new({
            { id = 1, name = "Alice" },
            { id = 2, name = "Bob" },
            { id = 3, name = "Charlie" }
        })

        local names = col:pluck("name")
        assert.are.same({"Alice", "Bob", "Charlie"}, names:toArray())
    end)

    it("should iterate over each item", function()
        local col = Collection:new({1, 2, 3})
        local sum = 0
        col:each(function(item) sum = sum + item end)

        assert.are.equal(6, sum)
    end)

    it("should check if collection contains a matching item", function()
        local col = Collection:new({1, 2, 3, 4})
        assert.is_true(col:contains(function(item) return item == 3 end))
        assert.is_false(col:contains(function(item) return item == 10 end))
    end)

    it("should reduce a collection to a single value", function()
        local col = Collection:new({1, 2, 3, 4})
        local sum = col:reduce(function(acc, item) return acc + item end, 0)

        assert.are.equal(10, sum)
    end)

    it("should sort a collection by a key", function()
        local col = Collection:new({
            { id = 2, name = "Bob" },
            { id = 1, name = "Alice" },
            { id = 3, name = "Charlie" }
        })

        local sorted = col:sortBy("id")
        local sorted_ids = sorted:pluck("id"):toArray()

        assert.are.same({1, 2, 3}, sorted_ids)
    end)

    it("should sort a collection by a key in descending order", function()
        local col = Collection:new({
            { id = 2, name = "Bob" },
            { id = 1, name = "Alice" },
            { id = 3, name = "Charlie" }
        })

        local sorted = col:sortBy("id", false)
        local sorted_ids = sorted:pluck("id"):toArray()

        assert.are.same({3, 2, 1}, sorted_ids)
    end)

    it("should reverse the collection", function()
        local col = Collection:new({1, 2, 3, 4})
        local reversed = col:reverse()

        assert.are.same({4, 3, 2, 1}, reversed:toArray())
    end)

end)