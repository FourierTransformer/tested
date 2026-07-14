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

tested.test("debug_var does not affect a passing assert_truthy assertion", function()
   tested.assert_truthy({
      given = "a non-empty string",
      should = "pass with debug_var set",
      actual = "not empty",
      debug_var = "some debug info"
   })
end)

tested.test("debug_var does not affect a passing assert_falsy assertion", function()
   tested.assert_falsy({
      given = "a nil value",
      should = "pass with debug_var set",
      actual = nil,
      debug_var = "some debug info"
   })
end)

tested.test("debug_var does not affect a passing assert_throws_exception assertion", function()
   tested.assert_throws_exception({
      given = "a function that throws",
      should = "pass with debug_var set",
      actual = function() error("boom") end,
      debug_var = "some debug info"
   })
end)

-- regression test for a bug where assert_truthy, assert_falsy, and assert_throws_exception
-- each built a fresh assertion table internally without copying over debug_var, so it never
-- reached the failure output. Runs a fixture as a subprocess since we need to inspect the
-- actual rendered output, not just whether the assertion passed or failed.
tested.test("debug_var is forwarded to failure output for assert_truthy, assert_falsy, and assert_throws_exception", function()
   local cmd = "tested -f plain tests/assertions/debug_var_forwarding_fixture.lua 2>&1"
   local handle = io.popen(cmd)
   local out = handle:read("*a")
   handle:close()

   tested.assert({
      given = "assert_truthy failure output",
      should = "include the forwarded debug_var",
      expected = true,
      actual = out:find("debug_var: FORWARDED_TRUTHY_MARKER", 1, true) ~= nil
   })

   tested.assert({
      given = "assert_falsy failure output",
      should = "include the forwarded debug_var",
      expected = true,
      actual = out:find("debug_var: FORWARDED_FALSY_MARKER", 1, true) ~= nil
   })

   tested.assert({
      given = "assert_throws_exception failure output",
      should = "include the forwarded debug_var",
      expected = true,
      actual = out:find("debug_var: FORWARDED_THROWS_MARKER", 1, true) ~= nil
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

-- demo: show debug_var on assert_truthy failure
tested.test("assert_truthy failure shows debug_var in output", {tags={"demo"}}, function()
   tested.assert_truthy({
      given = "a falsy value",
      should = "be truthy",
      actual = false,
      debug_var = "actual_value was: false"
   })
end)

-- demo: show debug_var on assert_falsy failure
tested.test("assert_falsy failure shows debug_var in output", {tags={"demo"}}, function()
   tested.assert_falsy({
      given = "a truthy value",
      should = "be falsy",
      actual = "not empty",
      debug_var = "actual_value was: not empty"
   })
end)

-- demo: show debug_var on assert_throws_exception failure
tested.test("assert_throws_exception failure shows debug_var in output", {tags={"demo"}}, function()
   tested.assert_throws_exception({
      given = "a function that does not throw",
      should = "throw an exception",
      actual = function() end,
      debug_var = "function returned without throwing"
   })
end)

return tested
