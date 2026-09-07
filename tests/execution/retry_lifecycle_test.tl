local tested = require("tested")

local t = tested.new()

local lifecycle = { before_each = 0, after_each = 0 }
local attempt = 0

t:before_each(function()
   lifecycle.before_each = lifecycle.before_each + 1
end)

t:after_each(function()
   lifecycle.after_each = lifecycle.after_each + 1
end)

-- On attempt N inside the test body:
--   before_each has fired N times (once before each attempt including the current one)
--   after_each has fired N-1 times (once after each completed previous attempt)
-- The test only passes on attempt 3, so retries=2 gives exactly 3 total attempts.
t:test("retries with lifecycle: before_each and after_each run on every attempt", {retries = 2}, function()
   attempt = attempt + 1
   tested.assert({
      given = "before_each count during attempt " .. attempt,
      should = "equal the current attempt number",
      expected = attempt,
      actual = lifecycle.before_each
   })
   tested.assert({
      given = "after_each count during attempt " .. attempt,
      should = "equal attempt number minus 1",
      expected = attempt - 1,
      actual = lifecycle.after_each
   })
   tested.assert({
      given = "attempt number",
      should = "equal 3 (passes only on the third attempt)",
      expected = 3,
      actual = attempt
   })
end)

-- After all three attempts complete, after_each will have fired 3 times.
t:test("retries with lifecycle: after_each ran once per attempt (3 times total)", function()
   tested.assert({
      given = "after_each count",
      should = "be 3 after the retried test's three attempts",
      expected = 3,
      actual = lifecycle.after_each
   })
end)

return t
