local tested = require("tested")

local t = tested.new()

local TESTED = "tested"
local FIXTURE = "tests/execution/cjson_fixture_test.lua"

local function run_with_debug(test_file)
    local cmd = TESTED .. " -n 0 -f plain -d DEBUG " .. test_file .. " 2>&1"
    local handle = io.popen(cmd)
    local out = handle:read("*a")
    handle:close()
    return out
end

t:test("C modules are not unloaded after test run", function()
    local out = run_with_debug(FIXTURE)
    tested.assert({
        given = "debug output after running a test that requires cjson",
        should = "contain 'NOT clearing out C module: cjson'",
        expected = true,
        actual = out:find("NOT clearing out C module: cjson") ~= nil
    })
end)

t:test("non-C modules are still unloaded after test run", function()
    local out = run_with_debug(FIXTURE)
    tested.assert({
        given = "debug output after running a test that requires cjson",
        should = "not show cjson being cleared out",
        expected = false,
        actual = out:find("Clearing out package: cjson") ~= nil
    })
    tested.assert({
        given = "debug output after running a test that requires cjson",
        should = "show tested package getting cleared",
        expected = true,
        actual = out:find("Clearing out package: tested") ~= nil
    })
end)

return t
