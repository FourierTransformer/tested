local tested = require("tested")

tested.test("tagged as unit", {tags={"unit"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

tested.test("tagged as integration", {tags={"integration"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

tested.test("tagged as unit and slow", {tags={"unit", "slow"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

tested.test("tagged as integration and slow", {tags={"integration", "slow"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

tested.test("no tags", function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

return tested
