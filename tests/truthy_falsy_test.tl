local tested = require("tested")

tested.test("truthy", function()
   tested.assert_truthy({given="empty string", actual=""})
   tested.assert_truthy({given="a number", actual=0})
   tested.assert_truthy({given="a function", actual=function() end})
   tested.assert_truthy({given="a table", actual={}})
   tested.assert_truthy({given="an unpack", actual=table.unpack({"a", "b"})})
   tested.assert_truthy({given="true boolean", actual=true})
   tested.assert_truthy({given="not false", actual=not false})
   tested.assert_truthy({given="not nil", actual=not nil})
   tested.assert_truthy({given="string.find he in hello", actual=string.find("hello", "he")})
end)

tested.test("falsy", function()
   local b: any
   tested.assert_falsy({given="nil", actual=nil})
   tested.assert_falsy({given="false", actual=false})
   tested.assert_falsy({given="unset variable", actual=b})
end)

return tested