local argparse = require("libs.argparse")
local test_runner = require("tested.test_runner").TestRunner
local display_results = require("tested.display_results")

















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
   for _, v in ipairs(args.display) do if v == "all" then show_all = true; break end end
   if show_all then args.display = { "skip", "pass", "fail", "exception", "unknown", "timeout" } end
end

local function main()
   local args = parse_args()
   set_defaults(args)


end

main()
