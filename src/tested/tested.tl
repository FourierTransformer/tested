local type types = require("tested.types")
local assert_table = require("tested.assert_table")

local tested: types.Tested = { tests = {}, run_only_tests = false }

function tested.test(name: string, fn: function())
    table.insert(tested.tests, {name=name, fn=fn, kind="test"})
end

function tested.skip(name: string, fn: function())
    table.insert(tested.tests, {name=name, fn=fn, kind="skip"})
end

function tested.only(name: string, fn: function())
    tested.run_only_tests = true
    table.insert(tested.tests, {name=name, fn=fn, kind="only"})
end

function tested.conditional_test(name: string, condition: boolean, fn: function())
    if condition then
        table.insert(tested.tests, {name=name, fn=fn, kind="conditional_test"})
    else
        table.insert(tested.tests, {name=name, fn=fn, kind="conditional_skip"})
    end
end


function tested.assert<T>(assertion: types.Assertion<T>): boolean, string
    local expected_type = type(assertion.expected)
    local actual_type = type(assertion.actual)
    
    if actual_type ~= expected_type then
        return false, "Actual: " .. tostring(assertion.actual) .. " (as '" .. 
        expected_type .."'). Expected: " .. tostring(assertion.expected) .. " (as '" .. actual_type .. "')"
    end

    if assertion.actual == assertion.expected then
        return true, ""
    end

    if actual_type == "table" and expected_type == "table" then
        return assert_table(assertion.expected as table, assertion.actual as table)
    end

    return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: " .. tostring(assertion.expected)

end

return tested
