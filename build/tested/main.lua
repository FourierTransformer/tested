local argparse = require("argparse")
local lfs = require("lfs")
local tl = require("tl")
tl.loader()

local test_runner = require("tested.test_runner")
local display = require("tested.display")















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
   parser:flag("-v --version"):description("Show version information"):action(function() print("tested v0.0.0"); os.exit(0) end)
   parser:flag("-r --randomize"):description("Randomize the order of the tests (default: not-set)"):default(false)
   parser:option("-d --display"):description("What test results to display (default: '-d fail -d exception -d unknown'"):choices({ "all", "valid", "invalid", "skip", "pass", "fail", "exception", "unknown", "timeout" }):count("*")
   parser:argument("paths", "Path(s) to directories containing test files to run (default: 'tests')"):args("*")

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
   for _, path in ipairs(args.paths) do
      local _, err = lfs.attributes(path)
      if err then error("The directory '" .. path .. "' does not appear to exist. Unable to run tests") end
      assert(lfs.attributes(path).mode == "directory", "tested requires the paths passed in to be a directory")
   end
end

local function find_lua_and_tl_modules(path)
   local modules = {}

   for file in lfs.dir(path) do
      local _, _, tl_module = file:find("^([^%.].-)%.tl$")
      local _, _, lua_module = file:find("^([^%.].-)%.lua$")
      if tl_module or lua_module then
         local f = path .. '/' .. file
         local attr = lfs.attributes(f)
         if attr and attr.mode == "file" then
            if tl_module then table.insert(modules, path .. "." .. tl_module) end
            if lua_module then table.insert(modules, path .. "." .. lua_module) end
         end
      end
   end
   return modules
end

local function get_test_modules(paths)
   local all_modules = {}
   for _, path in ipairs(paths) do
      local found_modules = find_lua_and_tl_modules(path)
      for _, module in ipairs(found_modules) do table.insert(all_modules, module) end
   end
   return all_modules
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

   local test_modules = get_test_modules(args.paths)
   display.header(test_modules)

   local total_time = 0
   local total_counts = { passed = 0, failed = 0, skipped = 0, invalid = 0 }
   local all_fully_tested = true

   for _, module in ipairs(test_modules) do



      package.loaded["tested.tested"] = nil
      local test_module = require(module)
      assert(type(test_module) == "table", "It does not appear that the test module '" .. module .. "' returns the 'tested' module")

      local output = test_runner.run(module, test_module, { randomize = args.randomize })
      display.results(output, display_types(args.display))

      if output.fully_tested == false then all_fully_tested = false end
      total_counts.passed = total_counts.passed + output.counts.passed
      total_counts.failed = total_counts.failed + output.counts.failed
      total_counts.skipped = total_counts.skipped + output.counts.skipped
      total_counts.invalid = total_counts.invalid + output.counts.invalid
      total_time = total_time + output.total_time
   end

   display.summary(total_counts, all_fully_tested, total_time)

   if all_fully_tested then
      os.exit()
   else
      os.exit(1)
   end

end

main()
