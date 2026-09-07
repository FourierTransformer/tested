local tested = require("tested")

local t = tested.new()

-- before_fn is called without pcall in tested:run(), so this error unwinds
-- through run_with_cleanup() with no catch — none of the tests below will run.
t:before(function()
    error("before hook is broken")
end)

t:test("this test never runs", function()
    tested.assert({ expected = true, actual = true })
end)

t:test("neither does this one", function()
    tested.assert({ expected = 1, actual = 1 })
end)

return t
