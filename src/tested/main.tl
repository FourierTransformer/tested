local argparse = require("argparse")
local lfs = require("lfs")
local tl = require("tl")
tl.loader() -- register the tl loader so we can rip
local test_runner = require("tested.test_runner").TestRunner
local display_results = require("tested.display_results")
local Tested = require("tested.tested_types").Tested

local enum DisplayOptions
    "all"
    "skip"
    "pass"
    "fail"
    "exception"
    "unknown"
    "timeout"
end

local record CLIOptions
    randomize: boolean
    display: {DisplayOptions}
    paths: {string}
end

local record TestFiles
    lua: {string}
    tl: {string}
end

local function parse_args(): CLIOptions
    local parser = argparse("tested", "A Lua/Teal Unit Testing Framework", "For more info see https://github.com/FourierTransformer/tested")
    parser:flag("-v --version"):description("Show version information"):action(function() print("tested v0.0.0") os.exit(0) end)
    parser:flag("-r --randomize"):description("Randomize the order of the tests (default: not-set)"):default(false)
    parser:option("-d --display"):description("What test results to display (default: '-d fail -d exception -d unknown'"):choices({"all", "skip", "pass", "fail", "exception", "unknown", "timeout"}):default({"fail", "exception", "unknown", "timeout"})
    parser:argument("paths", "Path(s) to directories containing test files to run (default: 'tests')"):args("*")

    local args: CLIOptions = parser:parse() as CLIOptions
    return args
end

local function set_defaults(args: CLIOptions)
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


local function find_lua_and_tl_files(path: string): TestFiles
    local found_files = {lua = {}, tl = {}}
    for file in lfs.dir(path) do
        local _, _, tl_file = file:find("^([^%.].-%.tl)$")
        local _, _, lua_file = file:find("^([^%.].-%.lua)$")
        if tl_file or lua_file  then
            local f = path..'/'..file
            local attr = lfs.attributes(f)
            if attr and attr.mode == "file" then
                if tl_file then table.insert(found_files.tl, f) end
                if lua_file then table.insert(found_files.lua, f) end
            end
        end
    end
    return found_files
end

local function get_test_files(paths: {string}): TestFiles
    local all_files: TestFiles = {lua = {}, tl = {}}
    for _, path in ipairs(paths) do
        print("Searching " .. path)
        local found_files = find_lua_and_tl_files(path)
        for _, lua_file in ipairs(found_files.lua) do table.insert(all_files.lua, lua_file) end
        for _, tl_file in ipairs(found_files.tl) do table.insert(all_files.tl, tl_file) end
    end
    return all_files
end

local function main()
    local args = parse_args()
    set_defaults(args)
    validate_args(args)
    local test_files = get_test_files(args.paths)
    for _, file in ipairs(test_files.tl) do
        local module_name = file:gsub(".tl$", ""):gsub("/", ".")
        local test_module = require(module_name) as Tested
        local output = test_runner.run(test_module)
        display_results(output)
    end
end

main()