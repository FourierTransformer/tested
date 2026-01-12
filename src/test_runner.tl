local tested_class = require("src.tested_class")
local Tested, _, Assertion = tested_class.Tested, tested_class.Test, tested_class.Assertion

local record TestRunnerOptions
    shuffle: boolean
end

local record TestRunner
    run: function(tested: Tested, options?: TestRunnerOptions)
end

local enum TestResult
    "PASS"
    "FAIL"
    "SKIP"
    "CONDITIONAL_SKIP"
    "EXCEPTION"
    "UNKNOWN"
end

local record AssertionResult
    filename: string
    line_number: integer
    result: TestResult
    given: string
    should: string
    error_message: string
end

local record TestOutput
    name: string
    result: TestResult
    message: string
    assertion_results: {AssertionResult}
end

local symbol_map: {TestResult: string} = {
    PASS = " ✓",
    FAIL = " ✗",
    SKIP = " ⊘",
    CONDITIONAL_SKIP = " ⊘",
    EXCEPTION = " !",
    UNKNOWN = " ?",
}

local test_runner: TestRunner = {}

local function fisher_yates_shuffle(t: {any})
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function test_runner.run(tested: Tested, options?: TestRunnerOptions)
    if options and options.shuffle then
        math.randomseed(os.time())
        fisher_yates_shuffle(tested.tests)
    end

    if tested.run_only_tests then
        print("Only running tests with 'tested.only'")
    end

    local test_results: {TestOutput} = {}


    for i, test in ipairs(tested.tests) do

        test_results[i] = {assertion_results = {}, name = test.name}

        if tested.run_only_tests and test.kind ~= "only" then
            test_results[i].result = "SKIP"
            test_results[i].message = "Only running 'tested.only' tests"

        elseif test.kind == "skip" then
            test_results[i].result = "SKIP"
            test_results[i].message = "Test marked with 'tested.skip'"

        elseif test.kind == "conditional_skip" then
            test_results[i].result = "CONDITIONAL_SKIP"
            test_results[i].message = "Condition in `tested.conditional_skip` returned false. Skipping test."

        else
            local assert_failed_count = 0
            local total_assertions = 0
            local filename = debug.getinfo(2, "S").short_src

            -- wrap the original assert so we can do some handling here
            local original_assert = tested.assert
            tested.assert = function<T>(assertion: Assertion<T>): boolean, string
                local ok, err = original_assert(assertion)

                total_assertions = total_assertions + 1

                local assertion_result: AssertionResult = {}
                local file_info = debug.getinfo(2, "l")
                assertion_result.filename = filename
                assertion_result.line_number = file_info.currentline

                assertion_result.given = assertion.given
                assertion_result.should = assertion.should

                if ok == false then
                    assert_failed_count = assert_failed_count + 1
                    assertion_result.result = "FAIL"
                    assertion_result.error_message = err
                else
                    assertion_result.result = "PASS"
                end
                table.insert(test_results[i].assertion_results, assertion_result)

                return ok, err
            end

            local ok, err = pcall(test.fn) as (boolean, string)
            if ok == false then
                test_results[i].result = "EXCEPTION"
                test_results[i].message = err
                -- probably save off debug.traceback() somewhere!

            elseif total_assertions == 0 then
                test_results[i].result = "UNKNOWN"
                test_results[i].message = "No assertions run during the test"

            elseif assert_failed_count == 0 then 
                test_results[i].result = "PASS"
                test_results[i].message = "All assertions have passed"

            else
                test_results[i].result = "FAIL"
                test_results[i].message = assert_failed_count .. " assertions have failed"
            end
        end
    end


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

return test_runner