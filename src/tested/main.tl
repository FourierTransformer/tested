local argparse = require("argparse")
local lfs = require("lfs")
local tl = require("tl")
tl.loader() -- register the tl loader so we can rip

local test_runner = require("tested.test_runner")
local type types = require("tested.types")


local enum DisplayOptions
    "all"
    "valid"
    "invalid"
    "skip"
    "pass"
    "fail"
    "exception"
    "unknown"
    "timeout"
end

local cli_to_display: {DisplayOptions:types.TestResult} = {
    ["skip"] = "SKIP",
    ["pass"] = "PASS",
    ["fail"] = "FAIL",
    ["exception"] = "EXCEPTION",
    ["unknown"] = "UNKNOWN",
    ["timeout"] = "TIMEOUT"
}

local record CLIOptions
    randomize: boolean
    display: {DisplayOptions}
    output_format: string
    custom_formatter: string
    paths: {string}
end

local function parse_args(): CLIOptions
    local parser = argparse("tested", "A Lua/Teal Unit Testing Framework", "For more info see https://github.com/FourierTransformer/tested")
    parser:flag("-v --version")
        :description("Show version information")
        :action(function() print("tested v0.0.0") os.exit(0) end)
    parser:flag("-r --randomize")
        :description("Randomize the order of the tests (default: not-set)")
        :default(false)
    parser:option("-d --display")
        :description("What test results to display (default: '-d fail -d exception -d unknown'")
        :choices({"all", "valid", "invalid", "skip", "pass", "fail", "exception", "unknown", "timeout"})
        :count("*")
    parser:option("-o --output-format")
        :description("What format to output the results in (default: 'terminal')")
        :choices({"terminal", "plain"})
        :default("terminal")
    parser:option("-f --custom-formatter")
        :description("Custom Formatter to use for output")
    parser:argument("paths", "Path(s) to directories containing test files to run (default: 'tests')")
        :args("*")

    local args: CLIOptions = parser:parse() as CLIOptions
    return args
end

local function set_defaults(args: CLIOptions)
    if #args.display == 0 then
        args.display = {"fail", "exception", "unknown", "timeout"}
    end
    if #args.paths == 0 then args.paths = {"tests"} end
    local show_all = false
    for _, display_option in ipairs(args.display) do if display_option == "all" then show_all = true break end end
    if show_all then args.display = {"skip", "pass", "fail", "exception", "unknown", "timeout"} end
    if not args.paths then args.paths = {"./tests"} end
end

local function validate_args(args: CLIOptions)
    for _, path in ipairs(args.paths) do
        local _, err = lfs.attributes(path)
        if err then error("The directory '" .. path .. "' does not appear to exist. Unable to run tests") end
        assert(lfs.attributes(path).mode == "directory", "tested requires the paths passed in to be a directory")
    end
end

local function find_lua_and_tl_tests(path: string): {string}
    local modules = {}

    for file in lfs.dir(path) do
        local _, _, tl_module = file:find("^([^%.].-_test)%.tl$")
        local _, _, lua_module = file:find("^([^%.].-_test)%.lua$")
        if tl_module or lua_module  then
            local f = path..'/'..file
            local attr = lfs.attributes(f)
            if attr and attr.mode == "file" then
                if tl_module then table.insert(modules, path .. "." .. tl_module) end
                if lua_module then table.insert(modules, path .. "." .. lua_module) end
            end
        end
    end
    return modules
end

local function load_result_formatter(args: CLIOptions): types.ResultFormatter
    if args.custom_formatter then
        local file = io.open(args.custom_formatter, "r")
        if not file then
            error("Unable to load custom formatter, file not found: " .. args.custom_formatter)
        end

        local formatter: types.ResultFormatter
        if args.custom_formatter:find("%.tl$") then
            -- had some troubles wrapping in an assert...
            local load_function, errors = tl.load(file:read("*all"), args.custom_formatter)
            if not load_function then error(errors) end
            formatter = load_function() as types.ResultFormatter
            file:close()

        elseif args.custom_formatter:find("^[^%.].-%.lua$") then
            formatter = assert(loadfile(args.custom_formatter))() as types.ResultFormatter
            file:close()

        else
            error("The custom formatter must point to a Lua (.lua) or Teal (.tl) file. Found: " .. args.custom_formatter)
        end

        if formatter then
            assert(formatter.header and type(formatter.header) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'header'.")
            assert(formatter.results and type(formatter.results) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'results'.")
            assert(formatter.summary and type(formatter.summary) == "function", "Custom formatter must include a 'header', 'results', and 'summary' section. Missing 'summary'.")
            return formatter
        else
            error("Unable to load custom formatter from: " .. args.custom_formatter)
        end
    else
        return require("tested.results." .. args.output_format) as types.ResultFormatter
    end
end

local function get_test_files(paths: {string}): {string}
    local all_files = {}
    for _, path in ipairs(paths) do
        local filenames = find_lua_and_tl_tests(path)
        for _, module in ipairs(filenames) do table.insert(all_files, module) end
    end
    return all_files
end

local function display_types(options: {DisplayOptions}): {types.TestResult: boolean}
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

    local runner_output: types.TestRunnerOutput
    for test_result, output in test_runner.run_tests(test_files, {randomize=args.randomize}) do
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