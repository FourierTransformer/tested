local argparse = require("argparse")
local path = require("path")
local fs = require("path.fs")
local load_file = require("tested.load_file")

local test_runner = require("tested.test_runner")















local cli_to_display = {
   ["skip"] = "SKIP",
   ["pass"] = "PASS",
   ["fail"] = "FAIL",
   ["exception"] = "EXCEPTION",
   ["unknown"] = "UNKNOWN",
   ["timeout"] = "TIMEOUT",
}









local function parse_args()
   local parser = argparse("tested", "A Lua/Teal Unit Testing Framework", "For more info see https://github.com/FourierTransformer/tested")
   parser:flag("-v --version"):
   description("Show version information"):
   action(function() print("tested v0.0.0"); os.exit(0) end)
   parser:flag("-r --randomize"):
   description("Randomize the order of the tests (default: not-set)"):
   default(false)
   parser:option("-d --display"):
   description("What test results to display (default: '-d fail -d exception -d unknown'"):
   choices({ "all", "valid", "invalid", "skip", "pass", "fail", "exception", "unknown", "timeout" }):
   count("*")
   parser:option("-o --output-format"):
   description("What format to output the results in (default: 'terminal')"):
   choices({ "terminal", "plain" }):
   default("terminal")
   parser:option("-f --custom-formatter"):
   description("Custom Formatter to use for output")
   parser:argument("paths", "Path(s) to directories containing test files to run (default: 'tests')"):
   args("*")

   local args = parser:parse()
   return args
end

local function set_defaults(args)
   if #args.display == 0 then
      args.display = { "fail", "exception", "unknown", "timeout" }
   end
   if #args.paths == 0 then args.paths = { "tests" } end
   local show_all = false
   for _, display_option in ipairs(args.display) do if display_option == "all" then show_all = true; break end end
   if show_all then args.display = { "skip", "pass", "fail", "exception", "unknown", "timeout" } end
   if not args.paths then args.paths = { "./tests" } end
end

local function validate_args(args)
   for _, test_path in ipairs(args.paths) do
      assert(path.exists(test_path), "The directory '" .. test_path .. "' does not appear to exist. Unable to run tests")
      assert(path.isdir(test_path), "tested requires the paths passed in to be a directory")
   end
end

local function find_lua_and_tl_tests(files, test_path)
   for file, file_type in fs.glob(test_path .. "/**_test.lua") do
      if file_type == "file" then table.insert(files, file) end
   end

   for file, file_type in fs.glob(test_path .. "/**_test.tl") do
      if file_type == "file" then table.insert(files, file) end
   end
end

local function load_result_formatter(args)
   if args.custom_formatter then
      local formatter = load_file(args.custom_formatter, "loading a custom formatter")

      if formatter then
         assert(formatter.header and type(formatter.header) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'header'.")
         assert(formatter.results and type(formatter.results) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'results'.")
         assert(formatter.summary and type(formatter.summary) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'summary'.")
         return formatter
      else
         error("Unable to load custom formatter from: " .. args.custom_formatter)
      end
   else
      return require("tested.results." .. args.output_format)
   end
end

local function get_test_files(paths)
   local all_files = {}
   for _, test_path in ipairs(paths) do
      local filenames = {}
      find_lua_and_tl_tests(filenames, test_path)
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

local function main()
   local args = parse_args()
   set_defaults(args)
   validate_args(args)
   local formatter = load_result_formatter(args)

   local test_files = get_test_files(args.paths)
   assert(#test_files > 0, "Unable to find any tests to run in: " .. table.concat(args.paths, ", "))
   formatter.header(test_files)

   local runner_output
   for test_result, output in test_runner.run_tests(test_files, { randomize = args.randomize }) do
      formatter.results(test_result, display_types(args.display))
      runner_output = output
   end

   formatter.summary(runner_output.total_counts, runner_output.all_fully_tested, runner_output.total_time)

   if runner_output.all_fully_tested then
      os.exit()
   else
      os.exit(1)
   end

end

main()
