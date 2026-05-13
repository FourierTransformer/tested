local lfs = require("lfs")

local cli = require("tested.cli")
local file_loader = require("tested.file_loader")
local logging = require("tested.libs.logging")
local test_runner = require("tested.test_runner")
local type types = require("tested.types")
local util = require("tested.util")

local logger = logging.get_logger("tested.main")
local TestRunner, run_parallel_tests = test_runner[1], test_runner[2]

local TESTED_VERSION = "tested v0.2.0"

local function load_result_formatter(args: cli.CLIOptions): types.ResultFormatter
   if args.custom_formatter then
      logger:info("Loading custom formatter: %s", args.custom_formatter)
      local formatter: types.ResultFormatter

      -- try loading as a module first
      local ok, custom_formatter = pcall(require, args.custom_formatter)
      if ok then
         logger:info("Successfully loaded custom formatter as module")
         formatter = custom_formatter as types.ResultFormatter
      else

         -- then try loading from a file
         logger:info("Unable to load as module, attempting to load from filepath")
         local info, err = lfs.attributes(args.custom_formatter)
         if err then error("Unable to load custom formatter, the file/module '" .. args.custom_formatter .. "' could not be loaded.") end
         if info.mode ~= "file" then error("The custom formatter should point to a file, but currently appears to be a: " .. info.mode, 0) end
         formatter = file_loader.load_file(args.custom_formatter) as types.ResultFormatter
      end

      if formatter then
         if not (formatter.header and type(formatter.header) == "function") then error("Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'header'.", 0) end
         if not (formatter.results and type(formatter.results) == "function") then error("Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'results'.", 0) end
         if not (formatter.summary and type(formatter.summary) == "function") then error("Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'summary'.", 0) end
         return formatter
      else
         error("Unable to load custom formatter from: " .. args.custom_formatter)
      end
   else
      logger:info("Loading builtin formatter: %s", args.display_format)
      return require("tested.results." .. args.display_format) as types.ResultFormatter
   end
end

local function register_format_handler(handlers: {string})
   for _, handler in ipairs(handlers) do
      logger:info("Registering format handler: %s", handler)
      local ok, module_format_handler = pcall(require, handler) as (boolean, types.FileLoaderHandler)
      if ok then
          file_loader.register_handler(module_format_handler.extension, module_format_handler.loader)
      else
         local info, err = lfs.attributes(handler)
         if err then error("Unable to load format handler, the file/module '" .. handler .."' was not able to be loaded.") end
         if info.mode ~= "file" then error("The custom format loader should point to a file, but currently appears to be a: " .. info.mode, 0) end

         file_loader.load_and_register_handler(handler)
      end
   end
end

local function find_tests(files: {string}, test_path: string): {string}
   logger:info("Looking for test files in %s", test_path)
   for file in lfs.dir(test_path) do
      local _, _, extension = file:find("^[^%.].-_test(%..-)$")
      if extension then
         local f = test_path..'/'..file
         local attr = lfs.attributes(f)
         if attr then
            if attr.mode == "file" and file_loader.loader[extension] then
               table.insert(files, f)

            elseif attr.mode == "directory" then
               find_tests(files, f)

            end
         end
      end
   end
   logger:info("Found %d test files to run in %s", #files, test_path)
end

local function get_all_test_files(args: cli.CLIOptions): {string}
   local all_files = {}
   for _, test_file in ipairs(args.test_files) do
      if file_loader.loader[util.get_file_extension(test_file)] then
         table.insert(all_files, test_file)
      end
   end
   for _, test_path in ipairs(args.test_directories) do
      local filenames = {}
      find_tests(filenames, test_path)
      for _, module in ipairs(filenames) do table.insert(all_files, module) end
   end
   return all_files
end

local function run_tests(formatter: types.ResultFormatter, args: cli.CLIOptions, test_files: {string}): types.TestRunnerOutput
   local options: types.TestRunnerOptions = {
      random = args.random,
      coverage = args.coverage,
      filter = args.filter
   }

   local display_results = function(test_output: types.TestedOutput)
      print(formatter.results(test_output, cli.display_types(args.show)))
   end

   if args.threads == 0 or #test_files <= 1 then
      logger:info("Running tests sequentially")
      local runner_output: types.TestRunnerOutput
      for test_result, output in TestRunner.run_tests(test_files, options) do
         display_results(test_result)
         runner_output = output
      end
      return runner_output
   end

   logger:info("Running tests in parallel")
   local runner_output = run_parallel_tests(test_files, args.threads, options, display_results)

   return runner_output
end

local function write_output_files(args: cli.CLIOptions, header_comments: {string}, runner_output: types.TestRunnerOutput)
   -- write out all the files at the end
   for _, file_output in ipairs(args.output) do
      local extension = util.get_file_extension(file_output)
      local output_formatter = require("tested.file_output" .. extension) as types.ResultFormatter
      local file_to_write, err = io.open(file_output, "w")
      if not file_to_write then error("Unable to open file for writing: " .. err, 0) end
      file_to_write:write(output_formatter.header(TESTED_VERSION, args.paths, header_comments))

      for _, test_output in ipairs(runner_output.module_results) do
         file_to_write:write(output_formatter.results(test_output, cli.display_types(args.show)))
      end

      file_to_write:write(output_formatter.summary(runner_output))
      file_to_write:close()
   end
end

local function main()
   -- setting up defaults and registering things...
   local args = cli.parse_args(TESTED_VERSION)
   logging.set_level(args.debug)
   cli.set_defaults(args)
   cli.validate_args(args)
   local formatter = load_result_formatter(args)
   if args.specified_show and formatter.allow_filtering == false then
      logger:warning("It appears the formatter you selected does not allow filtering. Please remove the '-s, --show' parameters from the CLI invocation")
   end
   if args.format_handler then
      register_format_handler(args.format_handler)
   end

   -- finding all the files
   local test_files = get_all_test_files(args)
   if #test_files == 0 then error("Unable to find any tests to run in: " .. table.concat(args.paths, ", "), 0) end

   local header_comments: {string} = {}
   if args.filter ~= nil then
      table.insert(header_comments, "Filtering tests with pattern: '" .. args.filter .. "'")
   end

   -- running the tests
   print(formatter.header(TESTED_VERSION, args.paths, header_comments))

   local runner_output = run_tests(formatter, args, test_files)
   runner_output.tested_version = TESTED_VERSION
   print(formatter.summary(runner_output))

   write_output_files(args, header_comments, runner_output)

   -- exiting cleanly
   if runner_output.all_fully_tested then
      os.exit()
   else
      os.exit(1)
   end

end

main()
