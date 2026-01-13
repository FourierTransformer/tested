local argparse = require("argparse")
local lfs = require("lfs")
local tl = require("tl")
tl.loader()

local test_runner = require("tested.test_runner")
local display_results = require("tested.display_results")













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
   parser:option("-d --display"):description("What test results to display (default: '-d fail -d exception -d unknown'"):choices({ "all", "skip", "pass", "fail", "exception", "unknown", "timeout" }):default({ "fail", "exception", "unknown", "timeout" })
   parser:argument("paths", "Path(s) to directories containing test files to run (default: 'tests')"):args("*")

   local args = parser:parse()
   return args
end

local function set_defaults(args)
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
      print("Searching " .. path)
      local found_modules = find_lua_and_tl_modules(path)
      for _, module in ipairs(found_modules) do table.insert(all_modules, module) end
   end
   return all_modules
end

local function display_types(options)
   local to_display = {}
   for _, cli_option in ipairs(options) do
      to_display[cli_to_display[cli_option]] = true

      if cli_option == "skip" then
         to_display["CONDITIONAL_SKIP"] = true
      end
   end
   return to_display
end

local function main()
   local args = parse_args()
   set_defaults(args)
   validate_args(args)
   local test_modules = get_test_modules(args.paths)
   for _, module in ipairs(test_modules) do
      local test_module = require(module)
      assert(type(test_module) == "table", "It does not appear that the test module '" .. module .. "' returns the 'tested' module at the end")
      local output = test_runner.run(test_module)
      display_results(output, display_types(args.display))
   end
end

main()
