local logging = require("tested.libs.logging")
local type types = require("tested.types")
local type luacov_type = require("luacov.runner")

local logger = logging.get_logger("tested.test_runner")

-- Excludes third-party code from coverage: anything installed into a luarocks
-- tree (dependencies like luacov, lanes, tl, and tested itself when installed
-- normally), plus tested's own files when developed in place (its build/ or
-- src/ tree). Anchored to these specific directories rather than a bare
-- "tested/" anywhere in the path, so a project checked out into a directory
-- literally named "tested" doesn't have its own files excluded too.
local _coverage_exclude_patterns <const> = {
   "luarocks%/.+$",
   "share/lua/[%d%.]+/.+$",
   "build/tested%/.+$",
   "src/tested%/.+$",
   "tested$",
}

-- simple lookup through require so the file_loader table never ends up as an upvalue in the
-- closure sent through the Lanes linda (cross-module function upvalues cause linda:send to fail silently)
local function _load_file(filepath: string): any
   return require("tested.file_loader").load_file(filepath)
end

local _file_loader_ready = false

-- from the indomitable Penlight - MIT
-- turned into an upvalue so it can be available in Lanes properly
local _searchpath = package.searchpath or function (name: string, path: string, sep: string, rep: string): string, string    -- luacheck: ignore
     if type(name) ~= "string" then
         error(("bad argument #1 to 'searchpath' (string expected, got %s)"):format(type(path)), 2)
     end
     if type(path) ~= "string" then
         error(("bad argument #2 to 'searchpath' (string expected, got %s)"):format(type(path)), 2)
     end
     if sep ~= nil and type(sep) ~= "string" then
         error(("bad argument #3 to 'searchpath' (string expected, got %s)"):format(type(path)), 2)
     end
     if rep ~= nil and type(rep) ~= "string" then
         error(("bad argument #4 to 'searchpath' (string expected, got %s)"):format(type(path)), 2)
     end
     sep = sep or "."
     rep = rep or _G.package.config:sub(1,1)
     do
       local s, e = name:find(sep, nil, true)
       while s do
         name = name:sub(1, s-1) .. rep .. name:sub(e+1, -1)
         s, e = name:find(sep, s + #rep + 1, true)
       end
     end
     local tried = {}
     for m in path:gmatch('[^;]+') do
         local nm = m:gsub('?', name)
         tried[#tried+1] = nm
         local f = io.open(nm,'r')
         if f then f:close(); return nm end
     end
     return nil, "\tno file '" .. table.concat(tried, "'\n\tno file '") .. "'"
 end

local function is_c_package(module_name: string): boolean
   if _searchpath(module_name, package.cpath) then return true end
   return false
end

local function intialize_output(): types.TestRunnerOutput
   local output: types.TestRunnerOutput = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = {passed=0, failed=0, expected=0, skipped=0, filtered=0, invalid=0},
      module_results = {},
   }
   return output
end

local function run_with_cleanup(test_file: string, options: types.TestRunnerOptions): types.TestedOutput

   logger:info("%s: keeping track of pre-loaded packages", test_file)
   local pre_test_loaded_packages: {string: boolean} = {}
   for package_name, _ in pairs(package.loaded) do pre_test_loaded_packages[package_name] = true end

   local test_module = _load_file(test_file) as types.Tested
   if not (type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean") then
      error(test_file ..": does not 'return tested' at end of file - unable to run tests", 0)
   end

   local test_results = test_module:run(test_file, options)

   logger:info("%s: Clearing out any non-C packages that were loaded", test_file)
   for package_name, _ in pairs(package.loaded) do
      if not pre_test_loaded_packages[package_name] then
         if is_c_package(package_name) then
            logger:debug("%s: NOT clearing out C module: %s", test_file, package_name)
         else
            logger:debug("%s: Clearing out package: %s", test_file, package_name)
            package.loaded[package_name] = nil
         end
      end
   end
   collectgarbage()

   return test_results
end

local function run_without_cleanup(test_file: string, options: types.TestRunnerOptions): types.TestedOutput

   local test_module = _load_file(test_file) as types.Tested
   if not (type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean") then
      error(test_file ..": does not 'return tested' at end of file - unable to run tests", 0)
   end

   local test_results = test_module:run(test_file, options)

   return test_results
end

local function write_coverage_stats(luacov_runner: luacov_type, statsfile: string, data: {string: any})
   local luacov_stats = require("luacov.stats")
   local loaded = luacov_stats.load(statsfile) as {string: any} or {}
   for name, file_data in pairs(data) do
      if loaded[name] then
         luacov_runner.update_stats(loaded[name] as {any: any}, file_data as {any: any})
      else
         loaded[name] = file_data
      end
   end
   luacov_stats.save(statsfile, loaded)
end

local function add_stats(output: types.TestRunnerOutput)
   for _, test_output in ipairs(output.module_results) do
      if test_output.fully_tested == false then output.all_fully_tested = false end
      output.total_counts.passed = output.total_counts.passed + test_output.counts.passed
      output.total_counts.failed = output.total_counts.failed + test_output.counts.failed
      output.total_counts.expected = output.total_counts.expected + test_output.counts.expected
      output.total_counts.skipped = output.total_counts.skipped + test_output.counts.skipped
      output.total_counts.filtered = output.total_counts.filtered + test_output.counts.filtered
      output.total_counts.invalid = output.total_counts.invalid + test_output.counts.invalid
      output.total_time = output.total_time + test_output.total_time
      output.total_tests = output.total_tests + #test_output.tests
   end
end

local function run_sequential_tests(
   test_files: {string},
   options: types.TestRunnerOptions,
   display_func: function(to_display: types.TestedOutput)
): types.TestRunnerOutput
   local fl = require("tested.file_loader")
   for _, setup in ipairs(fl.setups) do setup() end

   local luacov_loaded, luacov_runner = pcall(require, "luacov.runner")
   if options and options.coverage and not luacov_loaded then
      error("Code coverage requires the luacov module to be installed")
   end

   local output = intialize_output()

   if options.coverage then
      logger:info("Initializing luacov")
      luacov_runner.init({exclude=_coverage_exclude_patterns})
      -- Neuter save_stats(): luacov calls this both from the os.exit it monkey-patches
      -- in and (were tick enabled) periodically from the debug hook itself. Either path
      -- would load+merge+rewrite luacov.stats.out from inside the hot per-line hook or
      -- at process exit; we merge and write the coverage ourselves, once, below instead.
      luacov_runner.save_stats = function() end
      luacov_runner.pause()
   end

   for i, test_file in ipairs(test_files) do
      if options.coverage then luacov_runner.resume() end
      local test_output = run_with_cleanup(test_file, options)
      if options.coverage then luacov_runner.pause() end

      output.module_results[i] = test_output

      display_func(test_output)
   end

   add_stats(output)

   if options.coverage then
      debug.sethook(nil, "")
      write_coverage_stats(luacov_runner, luacov_runner.configuration.statsfile, luacov_runner.data as {string: any})
   end

   return output

end

return {run_sequential_tests}
