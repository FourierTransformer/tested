local ThreadPool = require("tested.libs.ThreadPool")
local logging = require("tested.libs.logging")


local logger = logging.get_logger("tested.test_runner")

local test_runner = {}

function test_runner.run_with_cleanup(file_loader, test_file, options)

   logger:info("%s: keeping track of pre-loaded packages", test_file)
   local pre_test_loaded_packages = {}
   for package_name, _ in pairs(package.loaded) do pre_test_loaded_packages[package_name] = true end

   local test_module = file_loader.load_file(test_file)
   assert(type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean", "It does not appear that '" .. test_file .. "' returns the 'tested' module")

   local test_results = test_module:run(test_file, options)

   logger:info("%s: Clearing out any packages that were loaded", test_file)
   for package_name, _ in pairs(package.loaded) do
      if not pre_test_loaded_packages[package_name] then
         logger:debug("%s: Clearing out package: %s", test_file, package_name)
         package.loaded[package_name] = nil
      end
   end
   collectgarbage()

   return test_results

end

function test_runner.run_tests(
   test_files,
   options)




   local luacov_loaded, luacov_runner = pcall(require, "luacov.runner")
   if options and options.coverage and not luacov_loaded then
      error("Code coverage requires the luacov module to be installed")
   end
   local file_loader = require("tested.file_loader")

   local output = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, skipped = 0, invalid = 0 },
      module_results = {},
   }
   local coverage_results = {}

   local i = 0

   if options.coverage then
      logger:info("Initializing luacov")
      luacov_runner.init({ exclude = { "luarocks%/.+$", "tested%/.+$", "tested$" } })
      luacov_runner.pause()
   end

   return function()
      i = i + 1
      if i > #test_files then
         if options.coverage then luacov_runner.shutdown() end
         return nil, output
      end

      local coverage = {}

      if options.coverage then luacov_runner.resume() end
      local test_output = test_runner.run_with_cleanup(file_loader, test_files[i], options)
      if options.coverage then
         coverage = luacov_runner.data
         luacov_runner.resume()
      end

      output.module_results[i] = test_output
      coverage_results[i] = coverage

      if test_output.fully_tested == false then output.all_fully_tested = false end
      output.total_counts.passed = output.total_counts.passed + test_output.counts.passed
      output.total_counts.failed = output.total_counts.failed + test_output.counts.failed
      output.total_counts.skipped = output.total_counts.skipped + test_output.counts.skipped
      output.total_counts.invalid = output.total_counts.invalid + test_output.counts.invalid
      output.total_time = output.total_time + test_output.total_time
      output.total_tests = output.total_tests + #test_output.tests

      return test_output, output
   end

end

local function load_and_run_test(test_file, options)



   local file_loader = require("tested.file_loader")
   return test_runner.run_with_cleanup(file_loader, test_file, options)
end

local function run_parallel_tests(
   test_files,
   num_threads,
   options,
   display_func)


   local output = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, skipped = 0, invalid = 0 },
      module_results = {},
   }
   local coverage_results = {}

   local pool = ThreadPool.init(num_threads, options.coverage)
   local input = {}
   for i = 1, #test_files do
      input[i] = { test_files[i], options }
   end

   local map_results = pool:map(load_and_run_test, input, display_func)
   for i, map_result in ipairs(map_results) do
      output.module_results[i] = map_result.result
      coverage_results[i] = map_result.code_coverage
   end
   pool:shutdown()




   if options.coverage then


      local luacov = require("luacov.runner")
      luacov.data = {}
      luacov.configuration = { statsfile = "luacov.stats.out" }

      for _, stats in ipairs(coverage_results) do
         for name, file_data in pairs(stats) do
            if luacov.data[name] then
               luacov.update_stats(luacov.data[name], file_data)
            else
               luacov.data[name] = file_data
            end
         end
      end
      luacov.save_stats()
   end

   for _, test_output in ipairs(output.module_results) do
      if test_output.fully_tested == false then output.all_fully_tested = false end
      output.total_counts.passed = output.total_counts.passed + test_output.counts.passed
      output.total_counts.failed = output.total_counts.failed + test_output.counts.failed
      output.total_counts.skipped = output.total_counts.skipped + test_output.counts.skipped
      output.total_counts.invalid = output.total_counts.invalid + test_output.counts.invalid
      output.total_time = output.total_time + test_output.total_time
      output.total_tests = output.total_tests + #test_output.tests
   end

   return output
end

return { test_runner, run_parallel_tests }
