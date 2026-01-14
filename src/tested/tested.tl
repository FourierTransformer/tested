local type types = require("tested.types")

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

local function deep_compare(prefix: string, expected: {any:any}, actual: {any:any}): boolean, string
    for k, v in pairs(expected) do
        if not actual[k] then
            print("missing key in actual", prefix .. "." .. tostring(k))

        elseif type(expected[k]) == "table" and type(actual[k] == "table") then
            -- DESCEND!
            deep_compare(prefix .. "." .. tostring(k), expected[k] as {any:any}, actual[k] as {any:any})

        elseif actual[k] ~= v then
            print("differences in values", prefix .. "." .. tostring(k), tostring(actual[k]), tostring(v))
        end
    end

    for k, _ in pairs(actual) do
        if not expected[k] then
            -- additional key
            print("additional key in actual", prefix .. tostring(k))
        end
    end
end



function tested.assert<T>(assertion: types.Assertion<T>): boolean, string
    local expected_type = type(assertion.expected)
    local actual_type = type(assertion.actual)
    
    if actual_type ~= expected_type then
        return false, "Expected: '" .. tostring(assertion.expected) .. "' (as '" .. 
        expected_type .."'). Actual: '" .. tostring(assertion.actual) .. "' (as '" .. actual_type .. "')"
    end

    if assertion.actual == assertion.expected then
        return true, ""
    end

    -- if actual_type == "table" and expected_type == "table" then
    --     return deep_compare("", assertion.expected as {any:any}, assertion.actual as {any:any})
    -- end

    -- honestly not sure if i should keep this.
    -- It's mostly in because TOML can serialize "nan" and then has checks if it's been serialized correctly.
    -- Fun stack overflow on nans: https://stackoverflow.com/questions/10034149/why-is-nan-not-equal-to-nan
    -- if expected_type == "number" 
    -- and tostring(assertion.expected) == "nan"
    -- and tostring(assertion.actual) == "nan" then
    --     return true, ""
    -- end

    return false, "Expected: " .. tostring(assertion.expected) ..
        "\nActual: " .. tostring(assertion.actual)

end

return tested
