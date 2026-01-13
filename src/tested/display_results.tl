local _test_runner = require("tested.test_runner")
local TestOutput, TestResult = _test_runner.TestOutput, _test_runner.TestResult


local symbol_map: {TestResult: string} = {
    PASS = " ✓",
    FAIL = " ✗",
    SKIP = " ⊘",
    CONDITIONAL_SKIP = " ⊘",
    EXCEPTION = " !",
    TIMEOUT = " ⏱",
    UNKNOWN = " ?",
}

local function display_results(test_results: {TestOutput})
    local passed = 0
    local failed = 0
    local skipped = 0
    local invalid = 0
    print("tested v0.0.0 test_file_a.tl\n")
    print("test_file_a.tl")
    for _, test_result in ipairs(test_results) do
        if test_result.result == "PASS" then passed = passed + 1
        elseif test_result.result == "FAIL" then failed = failed + 1
        elseif test_result.result == "SKIP" or test_result.result == "CONDITIONAL_SKIP" then skipped = skipped + 1
        else invalid = invalid + 1
        end

        if test_result.result == "FAIL" or test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" then
            print(symbol_map[test_result.result] .. " " .. test_result.name)
            if test_result.result == "FAIL" then
                for _, assertion_result in ipairs(test_result.assertion_results) do
                    if assertion_result.result == "FAIL" then
                        print("  " .. symbol_map[assertion_result.result] .. " " .. assertion_result.filename .. ":" .. assertion_result.line_number ..
                        " - Given: " .. assertion_result.given .. "  Should: " .. assertion_result.should)
                        print("      " .. assertion_result.error_message:gsub("\n", "\n      "))
                        print()
                    end
                end
            end

            if test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" then
                print("      " .. test_result.message)
                print()
            end
        end

    end

    print()
    print("Test Summary:")
    print("  Run: " .. passed .. " passed, " .. failed .. " failed")
    print("Other: " .. skipped .. " skipped, " .. invalid .. " invalid")
    if failed == 0 and invalid == 0 then
        print()
        print(" ✓ Fully Tested")
    end
end

return display_results