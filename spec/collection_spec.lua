local Collection = require("lumo.collection")
local busted = require("busted")

describe("Collection", function()
    it("should create an empty collection", function()
        local collection = Collection:new()
        assert.is_not_nil(collection)
        assert.are.equal(0, collection:count())
    end)

    it("should store and retrieve items", function()
        local collection = Collection:new({1, 2, 3})
        assert.are.equal(3, collection:count())
        assert.are.same({1, 2, 3}, collection.items)
    end)

    it("should check if it is an instance of Collection", function()
        local collection = Collection:new({1, 2, 3})
        assert.is_true(collection:isInstanceOf(Collection))
    end)

    it("should filter items", function()
        local collection = Collection:new({1, 2, 3, 4, 5})
        local filtered = collection:filter(function(item) return item % 2 == 0 end)
        assert.are.equal(2, filtered:count())
        assert.are.same({2, 4}, filtered.items)
    end)

    it("should map over items", function()
        local collection = Collection:new({1, 2, 3})
        local mapped = collection:map(function(item) return item * 2 end)
        assert.are.same({2, 4, 6}, mapped.items)
    end)

    it("should retrieve a specific item using pluck", function()
        local data = {
            {id = 1, name = "Alice"},
            {id = 2, name = "Bob"},
            {id = 3, name = "Charlie"}
        }
        local collection = Collection:new(data)
        local names = collection:pluck("name")
        assert.are.same({"Alice", "Bob", "Charlie"}, names)
    end)

    it("should retrieve the first item", function()
        local collection = Collection:new({10, 20, 30})
        assert.are.equal(10, collection:first())
    end)

    it("should retrieve the last item", function()
        local collection = Collection:new({10, 20, 30})
        assert.are.equal(30, collection:last())
    end)
end)