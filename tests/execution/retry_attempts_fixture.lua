-- fixture used by tests/execution/retry_attempts_test.tl via subprocess.
-- not named '*_test.lua' so the main suite does not pick it up directly.
local tested = require("tested")

local t = tested.new()

local attempt_count = 0
t:test("retried test that eventually passes", {retries = 2}, function()
   attempt_count = attempt_count + 1
   tested.assert({
      given = "attempt count",
      should = "reach 3 on the second retry",
      expected = 3,
      actual = attempt_count
   })
end)

t:test("immediate pass with no retries configured", function()
   tested.assert({
      given = "1 + 1",
      should = "equal 2",
      expected = 2,
      actual = 1 + 1
   })
end)

return t
