local tested = require("tested")

-- fails on attempt 1 (actual=1 ≠ 2), passes on attempt 2
local two_attempt_count = 0
tested.test("retries: passes on second attempt with retries=1", {retries = 1}, function()
   two_attempt_count = two_attempt_count + 1
   tested.assert({
      given = "attempt number",
      should = "equal 2 on successful retry",
      expected = 2,
      actual = two_attempt_count
   })
end)

-- fails on attempts 1 and 2, passes on attempt 3
local three_attempt_count = 0
tested.test("retries: passes on third attempt with retries=2", {retries = 2}, function()
   three_attempt_count = three_attempt_count + 1
   tested.assert({
      given = "attempt number",
      should = "equal 3 after two retries",
      expected = 3,
      actual = three_attempt_count
   })
end)

-- throws on attempt 1, passes on attempt 2
local exception_attempt_count = 0
tested.test("retries: exception retried and then passes", {retries = 1}, function()
   exception_attempt_count = exception_attempt_count + 1
   if exception_attempt_count == 1 then
      error("first attempt raises an exception")
   end
   tested.assert({
      given = "second attempt after exception",
      should = "pass after initial exception",
      expected = true,
      actual = true
   })
end)

-- passes immediately — verify no retry occurs even with retries configured
local immediate_pass_count = 0
tested.test("retries: no retry when test passes immediately", {retries = 3}, function()
   immediate_pass_count = immediate_pass_count + 1
   tested.assert({
      given = "immediate pass",
      should = "not require any retries",
      expected = true,
      actual = true
   })
end)

tested.test("retries: immediate-pass test ran exactly once", function()
   tested.assert({
      given = "immediate_pass_count",
      should = "be 1 since no retry was needed",
      expected = 1,
      actual = immediate_pass_count
   })
end)

local delay_attempt_count = 0
local delay_start_time: integer = 0
tested.test("retries: retry_delay waits before retrying", {retries = 1, retry_delay = 1}, function()
   delay_attempt_count = delay_attempt_count + 1
   if delay_attempt_count == 1 then
      delay_start_time = os.time()
      tested.assert({
         given = "attempt number",
         should = "equal 2 to trigger a retry",
         expected = 2,
         actual = delay_attempt_count
      })
   else
      tested.assert({
         given = "elapsed time since first attempt",
         should = "be at least 1 second",
         expected = true,
         actual = os.time() - delay_start_time >= 1
      })
   end
end)

return tested
