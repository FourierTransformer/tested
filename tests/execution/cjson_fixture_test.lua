local tested = require("tested")
local cjson = require("cjson")

tested.test("cjson is available", function()
    tested.assert({ given = "cjson", should = "be a table", expected = "table", actual = type(cjson) })
end)

return tested
