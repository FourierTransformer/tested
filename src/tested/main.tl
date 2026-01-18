local argparse = require("argparse")
local lfs = require("lfs")
local file_loader = require("tested.file_loader")

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
    test_files: {string}
    test_directories: {string}
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
    parser:argument("paths", "Path(s) to directories or files with tests to run (default: 'tests')")
        :args("*")

    local args: CLIOptions = parser:parse() as CLIOptions
    return args
end

local function set_defaults(args: CLIOptions)
    if #args.display == 0 then args.display = {"fail", "exception", "unknown", "timeout"} end
    -- if not args.paths then args.paths = {"./tests"} end
    if #args.paths == 0 then args.paths = {"tests"} end
    args.test_files = {}
    args.test_directories = {}
    
    local show_all = false
    for _, display_option in ipairs(args.display) do if display_option == "all" then show_all = true break end end
    if show_all then args.display = {"skip", "pass", "fail", "exception", "unknown", "timeout"} end
end

local function validate_args(args: CLIOptions)
    for _, path in ipairs(args.paths) do
        local info, err = lfs.attributes(path)
        if err then error("The file or directory '" .. path .. "' does not appear to exist. Unable to run tests") end
        assert(info.mode == "directory" or info.mode == "file", "tested requires the paths passed in to be a directory or file")
        if info.mode == "directory" then table.insert(args.test_directories, path) end
        if info.mode == "file" then table.insert(args.test_files, path) end
    end
end

local function load_result_formatter(args: CLIOptions): types.ResultFormatter
    if args.custom_formatter then
        local formatter = file_loader.load_file(args.custom_formatter, "loading a custom formatter") as types.ResultFormatter

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

local function find_tests(files: {string}, test_path: string): {string}
    for file in lfs.dir(test_path) do
        local _, _, extension = file:find("^[^%.].-_test(%..-)$")
        if extension then
            local f = test_path..'/'..file
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
end

local function get_file_extension(str: string): string
    return str:match("^.+(%..+)$")
end

local function get_all_test_files(args: CLIOptions): {string}
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
    
    local test_files = get_all_test_files(args)
    assert(#test_files > 0, "Unable to find any tests to run in: " .. table.concat(args.paths, ", "))
    formatter.header(args.paths)

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