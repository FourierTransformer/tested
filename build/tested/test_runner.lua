local file_loader = require("tested.file_loader")
local logging = require("tested.libs.logging")


local logger = logging.get_logger("tested.test_runner")

local test_runner = {}


local _coverage_exclude_patterns = {
   "luarocks%/.+$",
   "share/lua/[%d%.]+/.+$",
   "build/tested%/.+$",
   "src/tested%/.+$",
   "tested$",
}



local _searchpath = package.searchpath or function(name, path, sep, rep)
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
   rep = rep or _G.package.config:sub(1, 1)
   do
      local s, e = name:find(sep, nil, true)
      while s do
         name = name:sub(1, s - 1) .. rep .. name:sub(e + 1, -1)
         s, e = name:find(sep, s + #rep + 1, true)
      end
   end
   local tried = {}
   for m in path:gmatch('[^;]+') do
      local nm = m:gsub('?', name)
      tried[#tried + 1] = nm
      local f = io.open(nm, 'r')
      if f then f:close(); return nm end
   end
   return nil, "\tno file '" .. table.concat(tried, "'\n\tno file '") .. "'"
end

local function is_c_package(module_name)
   if _searchpath(module_name, package.cpath) then return true end
   return false
end

local function run_with_cleanup(test_file, options)

   logger:info("%s: keeping track of pre-loaded packages", test_file)
   local pre_test_loaded_packages = {}
   for package_name, _ in pairs(package.loaded) do pre_test_loaded_packages[package_name] = true end

   logger:info("%s: keeping track of pre-existing module searchers", test_file)
   local pre_test_searchers = {}
   for index, searcher in ipairs(package.searchers or package.loaders) do
      pre_test_searchers[index] = searcher
   end

   local test_module = file_loader.load_file(test_file)
   if not (type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean") then
      error(test_file .. ": does not 'return tested' at end of file - unable to run tests", 0)
   end

   local test_results = test_module:run(options, test_file)

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

   logger:info("%s: Restoring module searchers to their pre-test state", test_file)
   local searchers = package.searchers or package.loaders
   for index = #searchers, 1, -1 do searchers[index] = nil end
   for index, searcher in ipairs(pre_test_searchers) do searchers[index] = searcher end

   collectgarbage()

   return test_results

end

function test_runner.run_tests(
   test_files,
   test_options,
   test_runner_options,
   display_func)

   local luacov_loaded, luacov_runner = pcall(require, "luacov.runner")
   if test_runner_options and test_runner_options.coverage and not luacov_loaded then
      error("Code coverage requires the luacov module to be installed")
   end

   local output = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, expected = 0, skipped = 0, filtered = 0, invalid = 0 },
      module_results = {},
   }

   if test_runner_options.coverage then
      logger:info("Initializing luacov")
      luacov_runner.init({ exclude = _coverage_exclude_patterns })
      luacov_runner.pause()
   end

   for i, test_file in ipairs(test_files) do
      if test_runner_options.coverage then luacov_runner.resume() end
      local test_output = run_with_cleanup(test_file, test_options)
      if test_runner_options.coverage then luacov_runner.pause() end

      display_func(test_output)
      output.module_results[i] = test_output

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

   if test_runner_options.coverage then
      luacov_runner.save_stats()
   end

   return output

end

return test_runner
