local tested = require("tested")

local t = tested.new()

t:test("tagged as unit", {tags={"unit"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

t:test("tagged as integration", {tags={"integration"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

t:test("tagged as unit and slow", {tags={"unit", "slow"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

t:test("tagged as integration and slow", {tags={"integration", "slow"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

t:test("no tags", function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

return t
