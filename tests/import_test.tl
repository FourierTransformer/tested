local tested = require("tested")
local str = require("tests.tl_to_import")

tested.test("imported files should work", function()
    tested.assert({
        given = "a nested string",
        should = "be equivalent to imported string",
        expected = "somewhat nested",
        actual = str
    })
end)

return tested