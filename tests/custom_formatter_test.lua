local tested = require("tested")

local TESTED = "tested"
local FORMATTER = "tests/simple_formatter.lua"

local function run(test_file)
    local cmd = TESTED .. " -n 0 -z " .. FORMATTER .. " " .. test_file .. " 2>&1"
    local handle = io.popen(cmd)
    local out = handle:read("*a")
    handle:close()
    return out
end

-- header()

tested.test("header line appears in output", function()
    local out = run("tests/fully_working_test.lua")
    tested.assert({
        given = "custom formatter output",
        should = "contain CFMT_HEADER line",
        expected = true,
        actual = out:find("CFMT_HEADER") ~= nil
    })
end)

tested.test("header contains the test filename", function()
    local out = run("tests/fully_working_test.lua")
    tested.assert({
        given = "CFMT_HEADER line",
        should = "contain the test file path",
        expected = true,
        actual = out:find("fully_working_test%.lua") ~= nil
    })
end)

tested.test("header contains the tested version", function()
    local out = run("tests/fully_working_test.lua")
    tested.assert({
        given = "CFMT_HEADER line",
        should = "contain 'tested v'",
        expected = true,
        actual = out:find("tested v") ~= nil
    })
end)

-- results() — file section and PASS

tested.test("file section line appears with correct filename", function()
    local out = run("tests/fully_working_test.lua")
    tested.assert({
        given = "results output",
        should = "contain CFMT_FILE with filename",
        expected = true,
        actual = out:find("CFMT_FILE tests/fully_working_test%.lua") ~= nil
    })
end)

tested.test("each passing test gets a CFMT_TEST PASS line", function()
    local out = run("tests/fully_working_test.lua")
    tested.assert({
        given = "first test in fully_working_test.lua",
        should = "appear as CFMT_TEST PASS",
        expected = true,
        actual = out:find("CFMT_TEST PASS just works!") ~= nil
    })
    tested.assert({
        given = "second test in fully_working_test.lua",
        should = "appear as CFMT_TEST PASS",
        expected = true,
        actual = out:find("CFMT_TEST PASS just works without given and should!") ~= nil
    })
end)

-- results() — skip variants

tested.test("run_when=false test appears as CFMT_TEST CONDITIONAL_SKIP", function()
    -- tested_test.tl contains: tested.test("conditional guy should be skipped", {run_when=false}, ...)
    local out = run("tests/tested_test.tl")
    tested.assert({
        given = "test with run_when=false",
        should = "appear as CFMT_TEST CONDITIONAL_SKIP",
        expected = true,
        actual = out:find("CFMT_TEST CONDITIONAL_SKIP conditional guy should be skipped") ~= nil
    })
end)

-- results() — expected result types

tested.test("expected-fail test appears as CFMT_TEST EXPECTED_FAIL", function()
    local out = run("tests/expected_test.tl")
    tested.assert({
        given = "test with {expected='FAIL'} that fails",
        should = "appear as CFMT_TEST EXPECTED_FAIL",
        expected = true,
        actual = out:find("CFMT_TEST EXPECTED_FAIL") ~= nil
    })
end)

tested.test("expected-exception test appears as CFMT_TEST EXPECTED_EXCEPTION", function()
    local out = run("tests/expected_test.tl")
    tested.assert({
        given = "test with {expected='EXCEPTION'} that throws",
        should = "appear as CFMT_TEST EXPECTED_EXCEPTION",
        expected = true,
        actual = out:find("CFMT_TEST EXPECTED_EXCEPTION") ~= nil
    })
end)

tested.test("test that doesn't match its expected result appears as CFMT_TEST UNEXPECTED", function()
    local out = run("tests/expected_test.tl")
    tested.assert({
        given = "test with {expected='FAIL'} that passes",
        should = "appear as CFMT_TEST UNEXPECTED",
        expected = true,
        actual = out:find("CFMT_TEST UNEXPECTED") ~= nil
    })
end)

-- summary()

tested.test("summary line appears in output", function()
    local out = run("tests/fully_working_test.lua")
    tested.assert({
        given = "custom formatter output",
        should = "contain CFMT_SUMMARY line",
        expected = true,
        actual = out:find("CFMT_SUMMARY") ~= nil
    })
end)

tested.test("summary shows correct total and passed counts for all-passing run", function()
    local out = run("tests/fully_working_test.lua")
    -- fully_working_test.lua has exactly 2 passing tests
    tested.assert({
        given = "CFMT_SUMMARY for fully_working_test.lua",
        should = "show total=2",
        expected = true,
        actual = out:find("total=2") ~= nil
    })
    tested.assert({
        given = "CFMT_SUMMARY for fully_working_test.lua",
        should = "show passed=2",
        expected = true,
        actual = out:find("passed=2") ~= nil
    })
    tested.assert({
        given = "CFMT_SUMMARY for fully_working_test.lua",
        should = "show failed=0",
        expected = true,
        actual = out:find("failed=0") ~= nil
    })
end)

tested.test("summary shows non-zero failed count when tests fail", function()
    -- tested_test.tl has known failing tests (sum() fails several assertions)
    local out = run("tests/tested_test.tl")
    tested.assert({
        given = "CFMT_SUMMARY for tested_test.tl",
        should = "show failed > 0",
        expected = false,
        actual = out:find("failed=0") ~= nil
    })
end)

tested.test("summary skipped count reflects conditional skips", function()
    -- tested_test.tl has one run_when=false test → skipped=1
    local out = run("tests/tested_test.tl")
    tested.assert({
        given = "CFMT_SUMMARY for tested_test.tl",
        should = "show skipped=1",
        expected = true,
        actual = out:find("skipped=1") ~= nil
    })
end)

return tested
