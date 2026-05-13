local tested = require("tested")

-- before_fn is called without pcall in tested:run(), so this error unwinds
-- through run_with_cleanup() with no catch — none of the tests below will run.
tested.before(function()
    error("before hook is broken")
end)

tested.test("this test never runs", function()
    tested.assert({ expected = true, actual = true })
end)

tested.test("neither does this one", function()
    tested.assert({ expected = 1, actual = 1 })
end)

return tested
