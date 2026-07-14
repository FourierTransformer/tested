-- fixture used by tests/assertions/debug_var_test.tl via subprocess.
-- not named '*_test.lua' so the main suite does not pick it up directly.
-- exercises assert_truthy/assert_falsy/assert_throws_exception failures with debug_var set,
-- so the parent test can confirm debug_var actually reaches the failure output.
local tested = require("tested")

tested.test("assert_truthy fails with debug_var", function()
   tested.assert_truthy({
      given = "a falsy value",
      actual = false,
      debug_var = "FORWARDED_TRUTHY_MARKER"
   })
end)

tested.test("assert_falsy fails with debug_var", function()
   tested.assert_falsy({
      given = "a truthy value",
      actual = true,
      debug_var = "FORWARDED_FALSY_MARKER"
   })
end)

tested.test("assert_throws_exception fails with debug_var", function()
   tested.assert_throws_exception({
      given = "a function that does not throw",
      actual = function() end,
      debug_var = "FORWARDED_THROWS_MARKER"
   })
end)

return tested
