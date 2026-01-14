local type types = require("tested.types")


local symbol_map <total>: {types.TestResult: string} = {
    PASS = " ✓",
    FAIL = " ✗",
    SKIP = " ⊘",
    CONDITIONAL_SKIP = " ⊘",
    EXCEPTION = " !",
    TIMEOUT = " ⏱",
    UNKNOWN = " ?",
}

local record display end

function display.header(modules: {string})
    print("tested v0.0.0  " .. table.concat(modules, " "))
    print()
end

function display.results(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean})
    print("- " .. tested_result.module_name)
    for _, test_result in ipairs(tested_result.tests) do

        -- if the user wants to see it
        if test_types_to_display[test_result.result] then
            print(symbol_map[test_result.result] .. " " .. test_result.name)
            
            if test_result.result == "FAIL" or test_result.result == "PASS" then
                for _, assertion_result in ipairs(test_result.assertion_results) do
                    if assertion_result.result == "FAIL" or test_result.result == "PASS" then
                        print("  " .. symbol_map[assertion_result.result] .. " " .. assertion_result.filename .. ":" .. assertion_result.line_number ..
                        " - Given: " .. assertion_result.given .. "  Should: " .. assertion_result.should)
                        if assertion_result.result == "FAIL" then
                            print("      " .. assertion_result.error_message:gsub("\n", "\n      "))
                        end
                    end
                end
            end

            if test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" then
                print("      " .. test_result.message:gsub("\n", "\n      "))
            end
        end
    end
    print()
end

function display.summary(counts: types.TestCounts, all_fully_tested: boolean)
    print("Test Summary:")
    print("  Run: " .. counts.passed .. " passed, " .. counts.failed .. " failed")
    print("Other: " .. counts.skipped .. " skipped, " .. counts.invalid .. " invalid")
    if all_fully_tested then
        print()
        print(" ✓ Fully Tested")
    end
end

return display
