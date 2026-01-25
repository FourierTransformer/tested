local inspect = require("tested.libs.inspect")







local diff_symbol = {
   missing_key = "- ",
   different_value = "~ ",
   additional_key = "+ ",
}

local diff_message = {
   missing_key = ": Mising Key",
   different_value = ": Different Values",
   additional_key = ": Additional Key",
}

local function add_index_error(errors, prefix, index, error_type, expected, actual)
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

local function add_key_error(errors, prefix, key, error_type, expected, actual)
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

local function deep_compare(errors, prefix, expected, actual)

   local keys, _key_length, sequence = inspect.getKeys(expected)
   for i = 1, sequence do
      if actual[i] == nil then
         add_index_error(errors, prefix, i, "missing_key")

      elseif type(expected[i]) == "table" and type(actual[i]) == "table" then

         deep_compare(errors, prefix .. "[" .. tostring(i) .. "]", expected[i], actual[i])

      elseif actual[i] ~= expected[i] then
         add_index_error(errors, prefix, i, "different_value", expected[i], actual[i])
      end
   end
   for _i, k in ipairs(keys) do
      if actual[k] == nil then
         add_key_error(errors, prefix, k, "missing_key")

      elseif type(expected[k]) == "table" and type(actual[k]) == "table" then

         deep_compare(errors, prefix .. "." .. tostring(k), expected[k], actual[k])

      elseif actual[k] ~= expected[k] then
         add_key_error(errors, prefix, k, "different_value", expected[k], actual[k])
      end
   end


   keys, _key_length, sequence = inspect.getKeys(actual)
   for i = 1, sequence do
      if expected[i] == nil then add_index_error(errors, prefix, i, "additional_key") end
   end
   for _i, k in ipairs(keys) do
      if expected[k] == nil then add_key_error(errors, prefix, k, "additional_key") end
   end
end

local function assert_tables(expected, actual)
   local errors = {}
   deep_compare(errors, "", expected, actual)


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
