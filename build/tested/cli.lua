local argparse = require("argparse")
local lfs = require("lfs")

local logging = require("tested.libs.logging")
local logger = logging.get_logger("tested.cli")
local util = require("tested.util")



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
   parser:option("-t --tags"):
   description("Only run tests matching a tag expression, e.g. 'integration' or '(unit or integration) and not slow' (default: not-set)")
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
   description("File that loads a custom formatter to use for terminal output"))

   parser:option("-o --output-file"):
   description("Output file to save test results in (currently supported extensions: '.txt' and '.json')"):
   count("*")
   parser:option("-n --threads"):
   description("Set the number of threads to run the tests with (default: 4). Set to 0 to disable. Test files are split amongst the threads."):
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

   if #args.output_file > 0 then
      for _, output_file in ipairs(args.output_file) do
         if not (util.get_file_extension(output_file) == ".txt" or util.get_file_extension(output_file) == ".json") then
            error("The given output file does not have a supported file extension: '" .. output_file .. "'. Supported file extensions are: '.txt', '.json'", 0)
         end
      end
   end
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
   if args.tags then
      if args.tags:match("[^a-zA-Z0-9_ ()]") then
         error("Invalid --tags expression: only letters, digits, underscores, spaces, and parentheses are allowed", 0)
      end
      local lua_expr = (args.tags:gsub("([a-zA-Z_][a-zA-Z0-9_]*)", function(word)
         if word == "and" or word == "or" or word == "not" then return word end
         return 'tags["' .. word .. '"]'
      end))
      local tag_filter = "local tags = ... \nreturn " .. lua_expr


      local string_loader = loadstring or load
      local loaded = string_loader(tag_filter)
      if not loaded then
         error("Invalid --tags expression '" .. args.tags .. "': Be sure to use boolean expressions ('or', 'and', 'not', etc) when combining tags", 0)
      end
      args.tags_filter = loaded
   end

   if args.custom_formatter then
      if not (util.is_valid_filename(args.custom_formatter) or util.is_valid_lua_module_name(args.custom_formatter)) then
         error("Invalid --custom-formatter '" .. args.custom_formatter .. "'. It does not appear to be a valid filepath nor Lua module name")
      end
   end

   if args.format_handler then
      for _, format_handler in ipairs(args.format_handler) do
         if not (util.is_valid_filename(format_handler) or util.is_valid_lua_module_name(format_handler)) then
            error("Invalid --format-handler '" .. format_handler .. "'. It does not appear to be a valid filepath nor Lua module name")
         end
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
            to_display["FILTERED"] = true
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
