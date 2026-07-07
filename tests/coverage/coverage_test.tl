local tested = require("tested")
local lfs = require("lfs")

local function run_tested_with_coverage(tmpdir: string, threads: integer, tests_path: string)
   local cmd = string.format(
      "cd '%s' && tested -c -n %d -f plain '%s' > /dev/null 2>&1",
      tmpdir, threads, tests_path
   )
   local handle = io.popen(cmd)
   if handle then handle:close() end
end

tested.test("coverage output is identical for sequential and parallel runs", {tags = {"coverage"}}, function()
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
   run_tested_with_coverage(tmpdir, 0, tests_path)
   tested.assert({
      given = "luacov.stats.out",
      should = "exist after sequential coverage run",
      expected = true,
      actual = lfs.attributes(stats_path) ~= nil
   })
   tested.assert({
      given = "luacov.stats.out",
      should = "not be empty after sequential coverage run",
      expected = true,
      actual = (lfs.attributes(stats_path, "size") as integer) > 0
   })
   os.rename(stats_path, sequential_stats_path)

   -- parallel coverage run
   os.remove(stats_path)
   run_tested_with_coverage(tmpdir, 4, tests_path)
   tested.assert({
      given = "luacov.stats.out",
      should = "exist after parallel coverage run",
      expected = true,
      actual = lfs.attributes(stats_path) ~= nil
   })
   tested.assert({
      given = "luacov.stats.out",
      should = "not be empty after parallel coverage run",
      expected = true,
      actual = (lfs.attributes(stats_path, "size") as integer) > 0
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

return tested
