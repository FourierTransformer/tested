local tested = require("tested")

-- === EXPECTED_FAIL ===
-- A test expected to fail that actually fails → EXPECTED_FAIL
tested.test("expected fail: assertion fails as expected", {expected="FAIL"}, function()
   tested.assert({
      given = "1 + 1",
      should = "equal 3 (intentionally wrong)",
      expected = 3,
      actual = 1 + 1
   })
end)

-- === EXPECTED_EXCEPTION ===
-- A test expected to throw that actually throws → EXPECTED_EXCEPTION
tested.test("expected exception: throws as expected", {expected="EXCEPTION"}, function()
   error("this exception is expected")
end)

-- === EXPECTED_UNKNOWN ===
-- A test expected to be unknown that runs no assertions → EXPECTED_UNKNOWN
tested.test("expected unknown: no assertions as expected", {expected="UNKNOWN"}, function()
   -- intentionally no assertions
end)

-- === UNEXPECTED: expected FAIL but test passes ===
-- A test expected to fail that actually passes → UNEXPECTED
tested.test("unexpected: expected fail but test passes", {expected="FAIL", tags={"demo"}}, function()
   tested.assert({
      given = "1 + 1",
      should = "equal 2",
      expected = 2,
      actual = 1 + 1
   })
end)

-- === UNEXPECTED: expected EXCEPTION but no exception thrown ===
-- A test expected to throw that completes normally → UNEXPECTED
tested.test("unexpected: expected exception but no exception thrown", {expected="EXCEPTION", tags={"demo"}}, function()
   tested.assert({
      given = "1 + 1",
      should = "equal 2",
      expected = 2,
      actual = 1 + 1
   })
end)

-- === UNEXPECTED: expected UNKNOWN but assertions were run ===
-- A test expected to be unknown that does run assertions → UNEXPECTED
tested.test("unexpected: expected unknown but assertions were run", {expected="UNKNOWN", tags={"demo"}}, function()
   tested.assert({
      given = "1 + 1",
      should = "equal 2",
      expected = 2,
      actual = 1 + 1
   })
end)

return tested
