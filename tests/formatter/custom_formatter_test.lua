local tested = require("tested")

local TESTED = "tested"
local FORMATTER = "tests/formatter/simple_formatter.lua"

local function run(test_file)
    local cmd = TESTED .. " -n 0 -z " .. FORMATTER .. " " .. test_file .. " 2>&1"
    local handle = io.popen(cmd)
    local out = handle:read("*a")
    handle:close()
    return out
end

tested.test("custom formatter output for fully_working_test.lua", function()
    local out = run("tests/assertions/fully_working_test.lua")
    tested.assert({ given = "custom formatter output", should = "contain CFMT_HEADER line", expected = true, actual = out:find("CFMT_HEADER") ~= nil })
    tested.assert({ given = "CFMT_HEADER line", should = "contain the test file path", expected = true, actual = out:find("fully_working_test%.lua") ~= nil })
    tested.assert({ given = "CFMT_HEADER line", should = "contain 'tested v'", expected = true, actual = out:find("tested v") ~= nil })
    tested.assert({ given = "results output", should = "contain CFMT_FILE with filename", expected = true, actual = out:find("CFMT_FILE tests/assertions/fully_working_test%.lua") ~= nil })
    tested.assert({ given = "first test in fully_working_test.lua", should = "appear as CFMT_TEST PASS", expected = true, actual = out:find("CFMT_TEST PASS just works!") ~= nil })
    tested.assert({ given = "second test in fully_working_test.lua", should = "appear as CFMT_TEST PASS", expected = true, actual = out:find("CFMT_TEST PASS just works without given and should!") ~= nil })
    tested.assert({ given = "custom formatter output", should = "contain CFMT_SUMMARY line", expected = true, actual = out:find("CFMT_SUMMARY") ~= nil })
    tested.assert({ given = "CFMT_SUMMARY for fully_working_test.lua", should = "show total=2", expected = true, actual = out:find("total=2") ~= nil })
    tested.assert({ given = "CFMT_SUMMARY for fully_working_test.lua", should = "show passed=2", expected = true, actual = out:find("passed=2") ~= nil })
    tested.assert({ given = "CFMT_SUMMARY for fully_working_test.lua", should = "show failed=0", expected = true, actual = out:find("failed=0") ~= nil })
end)

tested.test("custom formatter output for tested_test.tl", function()
    local out = run("tests/execution/tested_test.tl")
    tested.assert({ given = "test with run_when=false", should = "appear as CFMT_TEST SKIP", expected = true, actual = out:find("CFMT_TEST SKIP conditional guy should be skipped") ~= nil })
    tested.assert({ given = "CFMT_SUMMARY for tested_test.tl", should = "show failed > 0", expected = false, actual = out:find("failed=0") ~= nil })
    tested.assert({ given = "CFMT_SUMMARY for tested_test.tl", should = "show skipped=1", expected = true, actual = out:find("skipped=1") ~= nil })
end)

tested.test("custom formatter output for expected_test.tl", function()
    local out = run("tests/execution/expected_test.tl")
    tested.assert({ given = "test with {expected='FAIL'} that fails", should = "appear as CFMT_TEST EXPECTED_FAIL", expected = true, actual = out:find("CFMT_TEST EXPECTED_FAIL") ~= nil })
    tested.assert({ given = "test with {expected='EXCEPTION'} that throws", should = "appear as CFMT_TEST EXPECTED_EXCEPTION", expected = true, actual = out:find("CFMT_TEST EXPECTED_EXCEPTION") ~= nil })
    tested.assert({ given = "test with {expected='FAIL'} that passes", should = "appear as CFMT_TEST UNEXPECTED", expected = true, actual = out:find("CFMT_TEST UNEXPECTED") ~= nil })
end)

return tested
