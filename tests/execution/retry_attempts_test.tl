local tested = require("tested")
local cjson = require("cjson")

local is_windows <const> = package.config:sub(1, 1) == "\\"
local null_device <const> = is_windows and "NUL" or "/dev/null"

local t = tested.new()

-- runs the given fixture file as a subprocess and returns the decoded JSON output.
-- a subprocess is needed since retry_attempts is only observable in the JSON output
-- of a full run, not through the public tested API. tested's own dkjson vendor copy
-- is encode-only, so cjson (an existing test_dependency) is used to decode instead.
local function run_and_capture_json(test_file: string): {any:any}
   local tmpdir = os.getenv("TMPDIR") or os.getenv("RUNNER_TEMP") or "/tmp"
   local json_path = tmpdir .. "/retry_attempts_" .. tostring(os.time()) .. ".json"

   local cmd = string.format(
      'tested -o "%s" "%s" > %s 2>&1',
      json_path, test_file, null_device
   )
   local handle = io.popen(cmd)
   if handle then handle:close() end

   local file = io.open(json_path, "r")
   if not file then error("expected tested to write JSON output to: " .. json_path) end
   local contents = file:read("*a")
   file:close()
   os.remove(json_path)

   local decoded = cjson.decode(contents)
   return decoded as {any:any}
end

local function find_test(module_result: {any:any}, name: string): {any:any}
   for _, test in ipairs(module_result.tests as {any:any}) do
      local test_table = test as {any:any}
      if test_table.name == name then return test_table end
   end
end

t:test("retry_attempts stays scoped to the test that actually retried", function()
   local output = run_and_capture_json("tests/execution/retry_attempts_fixture.lua")
   local module_result = (output.module_results as {any:any})[1] as {any:any}

   local retried_test = find_test(module_result, "retried test that eventually passes")
   local clean_test = find_test(module_result, "immediate pass with no retries configured")

   tested.assert({
      given = "a test with retries=2 that fails twice before passing",
      should = "record exactly 2 prior failed attempts",
      expected = 2,
      actual = #(retried_test.retry_attempts as {any})
   })

   tested.assert({
      given = "a test with no retries configured, run immediately after a retried test",
      should = "have an empty retry_attempts list instead of leaking the earlier test's failed attempts",
      expected = 0,
      actual = #(clean_test.retry_attempts as {any})
   })
end)

return t
