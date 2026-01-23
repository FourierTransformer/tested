local argparse = require("argparse")
local lfs = require("lfs")
local file_loader = require("tested.file_loader")

local test_runner = require("tested.test_runner")
local TestRunner, run_parallel_tests = test_runner[1], test_runner[2]

local logging = require("tested.libs.logging")
local logger = logging.get_logger("tested.main")















local cli_to_display = {
   ["skip"] = "SKIP",
   ["pass"] = "PASS",
   ["fail"] = "FAIL",
   ["exception"] = "EXCEPTION",
   ["unknown"] = "UNKNOWN",
   ["timeout"] = "TIMEOUT",
}





















local function parse_args()
   local parser = argparse("tested", "A Lua/Teal Unit Testing Framework", "For more info see https://fouriertransformer.github.io")
   parser:flag("-c --coverage"):
   description("Enable code coverage - will generate luacov.stats.out (default: not-set)"):
   default(false)
   parser:flag("-r --random"):
   description("Randomize the order of the tests (default: not-set)"):
   default(false)
   parser:option("-s --show"):
   description("What test results to display (default: '-s fail -s exception -s unknown')"):
   choices({ "all", "valid", "invalid", "skip", "pass", "fail", "exception", "unknown", "timeout" }):
   count("*")
   parser:mutex(
   parser:option("-f --display-format"):
   description("What format to output the results in (default: 'terminal')"):
   choices({ "terminal", "plain" }):
   default("terminal"),
   parser:option("-z --custom-formatter"):
   description("File that loads a custom formatter to use for output"))

   parser:option("-n --threads"):
   description("Set the number of threads to run the tests with (default: 4). Set to 0 to disable."):
   default(4):
   convert(tonumber)
   parser:option("-x --format-handler"):
   description("File that loads custom formats that are Lua-compatible"):
   count("*")
   parser:option("-d --debug"):
   description("Set the log level - mostly for debugging purposes (default: 'WARNING')"):
   choices({ "DEBUG", "INFO", "WARNING" }):
   default("WARNING")
   parser:flag("--version"):
   description("Show version information"):
   action(function() print("tested v0.0.0"); os.exit(0) end)
   parser:argument("paths", "Path(s) to directories or files with tests to run (default: 'tests')"):
   args("*")

   logger:info("Parsing Arguments...")

   local args = parser:parse()
   return args
end

local function set_defaults(args)
   logger:info("Setting Defaults...")
   if #args.show == 0 then args.show = { "fail", "exception", "unknown", "timeout" } end
   if #args.paths == 0 then args.paths = { "tests" } end
   args.test_files = {}
   args.test_directories = {}

   local show_all = false
   for _, display_option in ipairs(args.show) do if display_option == "all" then show_all = true; break end end
   if show_all then args.show = { "skip", "pass", "fail", "exception", "unknown", "timeout" } end
end

local function validate_args(args)
   logger:info("Validating args...")
   for _, path in ipairs(args.paths) do
      local info, err = lfs.attributes(path)
      if err then error("The file or directory '" .. path .. "' does not appear to exist. Unable to run tests") end
      assert(info.mode == "directory" or info.mode == "file", "tested requires the paths passed in to be a directory or file")
      if info.mode == "directory" then table.insert(args.test_directories, path) end
      if info.mode == "file" then table.insert(args.test_files, path) end
   end
end

local function load_result_formatter(args)
   if args.custom_formatter then
      logger:info("Loading custom formatter: " .. args.custom_formatter)

      local ok, custom_formatter = pcall(require, args.custom_formatter)
      if ok then
         logger:info("Successfully loaded custom formatter as module")
         return custom_formatter
      end


      logger:info("Unable to load as module, attempting to load from filepath")
      local info, err = lfs.attributes(args.custom_formatter)
      if err then error("Unable to load custom formatter, the file/module '" .. args.custom_formatter .. "' could not be loaded.") end
      assert(info.mode == "file", "The custom formatter should point to a file, but currently appears to be a: " .. info.mode)
      local formatter = file_loader.load_file(args.custom_formatter)

      if formatter then
         assert(formatter.header and type(formatter.header) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'header'.")
         assert(formatter.results and type(formatter.results) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'results'.")
         assert(formatter.summary and type(formatter.summary) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'summary'.")
         return formatter
      else
         error("Unable to load custom formatter from: " .. args.custom_formatter)
      end
   else
      logger:info("Loading builtin formatter: " .. args.display_format)
      return require("tested.results." .. args.display_format)
   end
end

local function register_format_handler(handlers)
   for _, handler in ipairs(handlers) do
      logger:info("Registering format handler: " .. handler)
      local ok, module_format_handler = pcall(require, handler)
      if ok then
         file_loader.register_handler(module_format_handler.extension, module_format_handler.loader)
      end

      local info, err = lfs.attributes(handler)
      if err then error("Unable to load format handler, the file/module '" .. handler .. "' was not able to be loaded.") end
      assert(info.mode == "file", "The custom format loader should point to a file, but currently appears to be a: " .. info.mode)

      file_loader.load_and_register_handler(handler)
   end
end

local function find_tests(files, test_path)
   logger:info("Looking for test files in " .. test_path)
   for file in lfs.dir(test_path) do
      local _, _, extension = file:find("^[^%.].-_test(%..-)$")
      if extension then
         local f = test_path .. '/' .. file
         local attr = lfs.attributes(f)
         if attr then
            if attr.mode == "file" and file_loader.file_loader[extension] then
               table.insert(files, f)

            elseif attr.mode == "directory" then
               find_tests(files, f)

            end
         end
      end
   end
   logger:info("Found " .. #files .. " test files to run in " .. test_path)
end

local function get_file_extension(str)
   return str:match("^.+(%..+)$")
end

local function get_all_test_files(args)
   local all_files = {}
   for _, test_file in ipairs(args.test_files) do
      if file_loader.file_loader[get_file_extension(test_file)] then
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

local function display_types(options)
   local to_display = {}
   for _, cli_option in ipairs(options) do
      if cli_to_display[cli_option] then
         to_display[cli_to_display[cli_option]] = true
         if cli_option == "skip" then
            to_display["CONDITIONAL_SKIP"] = true
         end
      else
         if cli_option == "invalid" then
            to_display["EXCEPTION"] = true
            to_display["UNKNOWN"] = true
            to_display["TIMEOUT"] = true
         elseif cli_option == "valid" then
            to_display["PASS"] = true
            to_display["SKIP"] = true
            to_display["CONDITIONAL_SKIP"] = true
            to_display["FAIL"] = true
         end
      end
   end
   return to_display
end

local function run_tests(formatter, args, test_files)
   local options = {
      random = args.random,
      coverage = args.coverage,
   }

   local display_results = function(test_output)
      formatter.results(test_output, display_types(args.show))
   end

   if args.threads == 0 then
      logger:info("Running tests sequentially")
      local runner_output
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

local function main()

   local args = parse_args()
   logging.set_level(args.debug)
   set_defaults(args)
   validate_args(args)
   local formatter = load_result_formatter(args)
   if args.format_handler then
      register_format_handler(args.format_handler)
   end


   local test_files = get_all_test_files(args)
   assert(#test_files > 0, "Unable to find any tests to run in: " .. table.concat(args.paths, ", "))


   formatter.header(args.paths)
   local runner_output = run_tests(formatter, args, test_files)
   formatter.summary(runner_output)


   if runner_output.all_fully_tested then
      os.exit()
   else
      os.exit(1)
   end

end

main()
