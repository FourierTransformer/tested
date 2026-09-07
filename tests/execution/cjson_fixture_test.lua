local tested = require("tested")
local cjson = require("cjson")

local t = tested.new()

t:test("cjson is available", function()
    tested.assert({ given = "cjson", should = "be a table", expected = "table", actual = type(cjson) })
end)

return t
