local tested = require("tested")

-- debug_var is silently ignored on passing assertions
tested.test("debug_var does not affect a passing string assertion", function()
   tested.assert({
      given = "matching strings",
      should = "pass with debug_var set",
      expected = "hello",
      actual = "hello",
      debug_var = "some debug info"
   })
end)

tested.test("debug_var does not affect a passing number assertion", function()
   tested.assert({
      given = "matching numbers",
      should = "pass with debug_var set",
      expected = 42,
      actual = 42,
      debug_var = 99
   })
end)

tested.test("debug_var does not affect a passing boolean assertion", function()
   tested.assert({
      given = "matching booleans",
      should = "pass with debug_var set",
      expected = true,
      actual = true,
      debug_var = false
   })
end)

tested.test("debug_var does not affect a passing table assertion", function()
   tested.assert({
      given = "matching tables",
      should = "pass with debug_var set",
      expected = {x = 1, y = 2},
      actual = {x = 1, y = 2},
      debug_var = {debug = "extra context"}
   })
end)

tested.test("debug_var does not affect assert_nil when value is nil", function()
   local value: any = nil
   tested.assert_nil({
      given = "nil value",
      actual = value,
      debug_var = "should be ignored"
   })
end)

-- demo: show string debug_var in failure output
tested.test("failing assertion shows string debug_var in output", {tags={"demo"}}, function()
   local actual_value = "world"
   tested.assert({
      given = "string comparison",
      should = "equal hello",
      expected = "hello",
      actual = actual_value,
      debug_var = "actual_value was: " .. actual_value
   })
end)

-- demo: show table debug_var formatted via inspect in failure output
tested.test("failing assertion shows table debug_var via inspect in output", {tags={"demo"}}, function()
   local state = {count = 5, items = {"a", "b", "c"}}
   tested.assert({
      given = "count check",
      should = "be 10",
      expected = 10,
      actual = state.count,
      debug_var = state
   })
end)

-- demo: show number debug_var in failure output
tested.test("failing assertion shows number debug_var in output", {tags={"demo"}}, function()
   tested.assert({
      given = "number comparison",
      should = "be 100",
      expected = 100,
      actual = 1,
      debug_var = 42
   })
end)

-- demo: show boolean debug_var in failure output
tested.test("failing assertion shows boolean debug_var in output", {tags={"demo"}}, function()
   tested.assert({
      given = "boolean comparison",
      should = "be true",
      expected = true,
      actual = false,
      debug_var = false
   })
end)

-- demo: show debug_var on assert_nil failure
tested.test("assert_nil failure shows debug_var in output", {tags={"demo"}}, function()
   tested.assert_nil({
      given = "a non-nil value",
      actual = 42,
      debug_var = "expected nil but got a number"
   })
end)

return tested
