local tested = require("tested")

tested.test("assert_nil passes when value is nil", function()
   tested.assert_nil({given="nil literal", actual=nil})

   local unset: any
   tested.assert_nil({given="unset variable", actual=unset})
end)

tested.test("assert_nil fails when value is false", {expected="FAIL"}, function()
   tested.assert_nil({given="false boolean", actual=false})
end)

tested.test("assert_nil fails when value is zero", {expected="FAIL"}, function()
   tested.assert_nil({given="zero", actual=0})
end)

tested.test("assert_nil fails when value is an empty string", {expected="FAIL"}, function()
   tested.assert_nil({given="empty string", actual=""})
end)

tested.test("assert_nil fails when value is a table", {expected="FAIL"}, function()
   tested.assert_nil({given="empty table", actual={}})
end)

tested.test("assert_nil error message includes actual value", {expected="FAIL"}, function()
   local _, message = tested.assert_nil({given="a number", actual=42})
   tested.assert({given="error message", should="contain actual value", expected="42", actual=tostring(message):match("42")})
end)

return tested
