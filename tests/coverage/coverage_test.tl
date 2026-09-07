local tested = require("tested")
local lfs = require("lfs")

local is_windows <const> = package.config:sub(1, 1) == "\\"
local null_device <const> = is_windows and "NUL" or "/dev/null"

local t = tested.new()

local function run_tested_with_coverage(tmpdir: string, threads: integer, tests_path: string): string
   local stderr_path = tmpdir .. "/tested_stderr.log"

   -- change directory in-process (rather than shelling out to `cd`) so the
   -- command itself needs no OS-specific quoting/chaining (`cd '%s' && ...`
   -- doesn't work under cmd.exe, which doesn't understand single quotes)
   local original_dir = lfs.currentdir()
   lfs.chdir(tmpdir)

   local cmd = string.format(
      'tested -c -n %d -f plain "%s" > %s 2>"%s"',
      threads, tests_path, null_device, stderr_path
   )
   local handle = io.popen(cmd)
   if handle then handle:close() end

   if original_dir then lfs.chdir(original_dir) end

   local captured_stderr = ""
   local stderr_file = io.open(stderr_path, "r")
   if stderr_file then
      captured_stderr = stderr_file:read("*a") or ""
      stderr_file:close()
      os.remove(stderr_path)
   end
   return captured_stderr
end

t:test("coverage output is identical for sequential and parallel runs", {tags = {"coverage"}}, function()
   local project_root = lfs.currentdir()
   if not project_root then
      error("cannot determine current working directory")
   end

   -- use assertions/ — most test files (5), no slow retry-delay tests
   local tests_path = project_root .. "/tests/assertions"
   local tmpdir = (os.getenv("TMPDIR") or os.getenv("RUNNER_TEMP") or "/tmp") .. "/tested_cov_" .. tostring(os.time())
   lfs.mkdir(tmpdir)

   local stats_path = tmpdir .. "/luacov.stats.out"
   local sequential_stats_path = tmpdir .. "/sequential.stats.out"

   -- sequential coverage run
   os.remove(stats_path)
   local sequential_stderr = run_tested_with_coverage(tmpdir, 0, tests_path)
   tested.assert({
      given = "luacov.stats.out",
      should = "exist after sequential coverage run",
      expected = true,
      actual = lfs.attributes(stats_path) ~= nil,
      debug_var = sequential_stderr ~= "" and sequential_stderr or nil
   })
   local sequential_size = lfs.attributes(stats_path, "size") as integer
   tested.assert({
      given = "luacov.stats.out",
      should = "not be empty after sequential coverage run",
      expected = true,
      actual = (sequential_size or 0) > 0,
      debug_var = sequential_stderr ~= "" and sequential_stderr or nil
   })
   os.rename(stats_path, sequential_stats_path)

   -- parallel coverage run
   os.remove(stats_path)
   local parallel_stderr = run_tested_with_coverage(tmpdir, 4, tests_path)
   tested.assert({
      given = "luacov.stats.out",
      should = "exist after parallel coverage run",
      expected = true,
      actual = lfs.attributes(stats_path) ~= nil,
      debug_var = parallel_stderr ~= "" and parallel_stderr or nil
   })
   local parallel_size = lfs.attributes(stats_path, "size") as integer
   tested.assert({
      given = "luacov.stats.out",
      should = "not be empty after parallel coverage run",
      expected = true,
      actual = (parallel_size or 0) > 0,
      debug_var = parallel_stderr ~= "" and parallel_stderr or nil
   })

   local luacov_stats = require("luacov.stats")
   tested.assert({
      given = "luacov coverage data",
      should = "be identical for sequential and parallel runs",
      expected = luacov_stats.load(sequential_stats_path),
      actual = luacov_stats.load(stats_path)
   })

   -- clean up temp directory
   os.remove(stats_path)
   os.remove(sequential_stats_path)
   lfs.rmdir(tmpdir)
end)

return t
