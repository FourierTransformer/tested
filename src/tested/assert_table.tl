local inspect = require("tested.libs.inspect")

local enum TableDiff
    "missing_key"
    "different_value"
    "additional_key"
end

local diff_symbol <total>: {TableDiff: string} = {
    missing_key = "- ",
    different_value = "~ ",
    additional_key = "+ "
}

local diff_message <total>: {TableDiff: string} = {
    missing_key = ": Mising Key",
    different_value = ": Different Values",
    additional_key = ": Additional Key"
}

local function add_index_error(errors: {string}, prefix: string, index: integer, error_type: TableDiff, expected?: any, actual?: any)
    table.insert(errors, diff_symbol[error_type])
    table.insert(errors, prefix)
    table.insert(errors, "[")
    table.insert(errors, tostring(index))
    table.insert(errors, "]")
    table.insert(errors, diff_message[error_type])
    if expected and actual then
        table.insert(errors, " (Expected: ")
        table.insert(errors, tostring(expected))
        table.insert(errors, "  Actual: ")
        table.insert(errors, tostring(actual))
        table.insert(errors, ")")
    end
    table.insert(errors, "\n")
end

local function add_key_error(errors: {string}, prefix: string, key: any, error_type: TableDiff, expected?: any, actual?: any)
    table.insert(errors, diff_symbol[error_type])
    table.insert(errors, prefix)
    table.insert(errors, ".")
    table.insert(errors, tostring(key))
    table.insert(errors, diff_message[error_type])
    if expected and actual then
        table.insert(errors, " (Expected: ")
        table.insert(errors, tostring(expected))
        table.insert(errors, "  Actual: ")
        table.insert(errors, tostring(actual))
        table.insert(errors, ")")
    end
    table.insert(errors, "\n")
end

local function deep_compare(errors: {string}, prefix: string, expected: table, actual: table)
    -- not cycle safe, but might be good enough to get us started?
    local keys, _key_length, sequence = inspect.getKeys(expected)
    for i = 1, sequence do
        if not actual[i] then
            add_index_error(errors, prefix, i, "missing_key")

        elseif type(expected[i]) == "table" and type(actual[i]) == "table" then
            -- DESCEND!
            deep_compare(errors, prefix .. "[" .. tostring(i) .."]", expected[i] as {any:any}, actual[i] as {any:any})

        elseif actual[i] ~= expected[i] then
            add_index_error(errors, prefix, i, "different_value", expected[i], actual[i])
        end
    end
    for _i, k in ipairs(keys) do
        if not actual[k] then
            add_key_error(errors, prefix, k, "missing_key")

        elseif type(expected[k]) == "table" and type(actual[k]) == "table" then
            -- DESCEND!
            deep_compare(errors, prefix .. "." .. tostring(k), expected[k] as {any:any}, actual[k] as {any:any})

        elseif actual[k] ~= expected[k] then
            add_key_error(errors, prefix, k, "different_value", expected[k], actual[k])
        end
    end

    -- check if there are any additional keys floating around
    keys, _key_length, sequence = inspect.getKeys(actual)
    for i = 1, sequence do 
        if not expected[i] then add_index_error(errors, prefix, i, "additional_key") end
    end
    for _i, k in ipairs(keys) do
        if not expected[k] then add_key_error(errors, prefix, k, "additional_key") end
    end
end

local function assert_tables(expected: table, actual: table): (boolean, string)
    local errors = {}
    deep_compare(errors, "", expected, actual)

    -- since change table starts off in there.
    if #errors == 0 then
        return true, ""
    end

    table.insert(errors, "\nActual: \n")
    table.insert(errors, inspect.inspect(actual, {}))

    table.insert(errors, "\n\nExpected: \n")
    table.insert(errors, inspect.inspect(expected, {}))

    return false, table.concat(errors)

end

return assert_tables