local argparse = require("argparse")
local lfs = require("lfs")

local logging = require("tested.libs.logging")
local logger = logging.get_logger("tested.cli")



local cli = { CLIOptions = {} }










































local cli_to_display = {
   ["skip"] = "SKIP",
   ["pass"] = "PASS",
   ["fail"] = "FAIL",
   ["exception"] = "EXCEPTION",
   ["unknown"] = "UNKNOWN",
   ["unexpected"] = "UNEXPECTED",

}

function cli.parse_args(version)
   local parser = argparse("tested", "A Lua/Teal Unit Testing Framework", "For more info see https://fouriertransformer.github.io/tested")
   parser:flag("-c --coverage"):
   description("Enable code coverage - will generate luacov.stats.out (default: not-set)"):
   default(false)
   parser:flag("-r --random"):
   description("Randomize the order of the tests (default: not-set)"):
   default(false)
   parser:option("-F --filter"):
   description("Only run tests whose name matches this Lua pattern (default: not-set)")
   parser:option("-s --show"):
   description("What test results to display (default: '-s fail -s exception -s unknown')"):
   choices({ "all", "valid", "invalid", "skip", "pass", "fail", "exception", "unknown", "expected", "unexpected" }):
   count("*")
   parser:mutex(
   parser:option("-f --display-format"):
   description("What format to output the results in (default: 'terminal')"):
   choices({ "terminal", "plain", "tap" }):
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
   description("Set the log level - mostly for debugging issues with tested (default: 'WARNING')"):
   choices({ "DEBUG", "INFO", "WARNING" }):
   default("WARNING")
   parser:flag("--version"):
   description("Show version information"):
   action(function() print(version); os.exit(0) end)
   parser:argument("paths", "Path(s) to directories or files with tests to run (default: 'tests')"):
   args("*")

   logger:info("Parsing Arguments...")

   local args = parser:parse()
   return args
end

function cli.set_defaults(args)
   logger:info("Setting Defaults...")
   if #args.show == 0 then
      args.show = { "fail", "exception", "unknown", "unexpected" }
      args.specified_show = false
   else
      args.specified_show = true
   end
   if #args.paths == 0 then args.paths = { "tests" } end
   args.test_files = {}
   args.test_directories = {}

   local show_all = false
   for _, display_option in ipairs(args.show) do if display_option == "all" then show_all = true; break end end
   if show_all then args.show = { "skip", "pass", "fail", "exception", "unknown", "expected", "unexpected" } end
end

function cli.validate_args(args)
   logger:info("Validating args...")
   for _, path in ipairs(args.paths) do
      local info, err = lfs.attributes(path)
      if err then error("The file or directory '" .. path .. "' does not appear to exist. Unable to run tests") end
      if not (info.mode == "directory" or info.mode == "file") then error("tested requires the paths passed in to be a directory or file", 0) end
      if info.mode == "directory" then table.insert(args.test_directories, path) end
      if info.mode == "file" then table.insert(args.test_files, path) end
   end
   if args.filter then
      local ok, err = pcall(string.find, "", args.filter)
      if not ok then
         error("Invalid --filter pattern '" .. args.filter .. "': " .. tostring(err), 0)
      end
   end
end

function cli.display_types(options)
   local to_display = {}
   for _, cli_option in ipairs(options) do
      if cli_to_display[cli_option] then
         to_display[cli_to_display[cli_option]] = true
         if cli_option == "skip" then
            to_display["SKIP"] = true
            to_display["CONDITIONAL_SKIP"] = true
         end
      else
         if cli_option == "invalid" then
            to_display["EXCEPTION"] = true
            to_display["UNKNOWN"] = true
            to_display["TIMEOUT"] = true
            to_display["UNEXPECTED"] = true
         elseif cli_option == "valid" then
            to_display["PASS"] = true
            to_display["SKIP"] = true
            to_display["CONDITIONAL_SKIP"] = true
            to_display["FAIL"] = true
            to_display["EXPECTED_FAIL"] = true
            to_display["EXPECTED_EXCEPTION"] = true
            to_display["EXPECTED_UNKNOWN"] = true
         elseif cli_option == "expected" then
            to_display["EXPECTED_FAIL"] = true
            to_display["EXPECTED_EXCEPTION"] = true
            to_display["EXPECTED_UNKNOWN"] = true
         end
      end
   end
   return to_display
end

return cli
