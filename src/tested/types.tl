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
        assertion_results: {AssertionResult}
    end

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