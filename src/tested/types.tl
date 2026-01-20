-- exporting all the shared types

local record types

    interface Assertion<T>
        given: string
        should: string
        expected: T
        actual: T
    end

    enum TestType
        "test"
        "skip"
        "only"
        "conditional_test"
        "conditional_skip"
    end

    enum TestResult
        "PASS"
        "FAIL"
        "SKIP"
        "CONDITIONAL_SKIP"
        "EXCEPTION"
        "TIMEOUT"
        "UNKNOWN"
    end

    interface AssertionResult
        filename: string
        line_number: integer
        result: types.TestResult
        given: string
        should: string
        error_message: string
    end

    interface TestOutput
        name: string
        result: types.TestResult
        message: string
        time: number
        assertion_results: {AssertionResult}
    end

    interface TestCounts
        passed: integer
        failed: integer
        skipped: integer
        invalid: integer
    end

    interface TestedOutput
        tests: {TestOutput}
        filename: string
        counts: TestCounts
        fully_tested: boolean
        total_time: number
    end

    interface TestRunnerOutput
        module_results: {TestedOutput}
        total_counts: TestCounts
        total_time: number
        total_tests: integer
        all_fully_tested: boolean
    end

    -- needed for result handling
    interface ResultFormatter
        format: string
        header: function(modules: {string})
        results: function(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean})
        summary: function(runner_output: types.TestRunnerOutput)
    end

    -- needed for registering new file types
    interface FileLoaderHandler
        extension: string
        loader: function(filepath: string): function(): any
    end

    -- needed for tested
    interface Test
        kind: TestType
        name: string
        fn: function()
    end

    interface Tested
        tests: {Test}
        run_only_tests: boolean
        assert: function<T>(assertion: Assertion<T>): boolean, string
        test: function(name: string, fn: function())
        skip: function(name: string, fn: function())
        only: function(name: string, fn: function())
        conditional_test: function(name: string, condition: boolean, fn: function())
    end
end

return types