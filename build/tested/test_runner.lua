local logging = require("tested.libs.logging")



local logger = logging.get_logger("tested.test_runner")







local _coverage_exclude_patterns = {
   "luarocks%/.+$",
   "share/lua/[%d%.]+/.+$",
   "build/tested%/.+$",
   "src/tested%/.+$",
   "tested$",
}



local function _load_file(filepath)
   return require("tested.file_loader").load_file(filepath)
end

local _file_loader_ready = false



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

local function intialize_output()
   local output = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, expected = 0, skipped = 0, filtered = 0, invalid = 0 },
      module_results = {},
   }
   return output
end

local function run_with_cleanup(test_file, options)

   logger:info("%s: keeping track of pre-loaded packages", test_file)
   local pre_test_loaded_packages = {}
   for package_name, _ in pairs(package.loaded) do pre_test_loaded_packages[package_name] = true end

   local test_module = _load_file(test_file)
   if not (type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean") then
      error(test_file .. ": does not 'return tested' at end of file - unable to run tests", 0)
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

local function run_without_cleanup(test_file, options)

   local test_module = _load_file(test_file)
   if not (type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean") then
      error(test_file .. ": does not 'return tested' at end of file - unable to run tests", 0)
   end

   local test_results = test_module:run(test_file, options)

   return test_results
end

local function write_coverage_stats(luacov_runner, statsfile, data)
   local luacov_stats = require("luacov.stats")
   local loaded = luacov_stats.load(statsfile) or {}
   for name, file_data in pairs(data) do
      if loaded[name] then
         luacov_runner.update_stats(loaded[name], file_data)
      else
         loaded[name] = file_data
      end
   end
   luacov_stats.save(statsfile, loaded)
end

local function add_stats(output)
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
   test_files,
   options,
   display_func)

   local fl = require("tested.file_loader")
   for _, setup in ipairs(fl.setups) do setup() end

   local luacov_loaded, luacov_runner = pcall(require, "luacov.runner")
   if options and options.coverage and not luacov_loaded then
      error("Code coverage requires the luacov module to be installed")
   end

   local output = intialize_output()

   if options.coverage then
      logger:info("Initializing luacov")
      luacov_runner.init({ exclude = _coverage_exclude_patterns })




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
      write_coverage_stats(luacov_runner, luacov_runner.configuration.statsfile, luacov_runner.data)
   end

   return output

end

return { run_sequential_tests }
