local inspect = require("tested.libs.inspect")
local tadd = require("tested.libs.tadd")







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

local function add_index_error(prefix, index, error_type, expected, actual)
   tadd.add(
   diff_symbol[error_type],
   prefix,
   "[",
   tostring(index),
   "]",
   diff_message[error_type])

   if expected and actual then
      tadd.add(
      " (Expected: ",
      tostring(expected),
      "  Actual: ",
      tostring(actual),
      ")")

   end
   tadd.add("\n")
end

local function add_key_error(prefix, key, error_type, expected, actual)
   tadd.add(
   diff_symbol[error_type],
   prefix,
   ".",
   tostring(key),
   diff_message[error_type])

   if expected and actual then
      tadd.add(
      " (Expected: ",
      tostring(expected),
      "  Actual: ",
      tostring(actual),
      ")")

   end
   tadd.add("\n")
end

local function deep_compare(prefix, expected, actual)

   local keys, _key_length, sequence = inspect.getKeys(expected)
   for i = 1, sequence do
      if actual[i] == nil then
         add_index_error(prefix, i, "missing_key")

      elseif type(expected[i]) == "table" and type(actual[i]) == "table" then

         deep_compare(prefix .. "[" .. tostring(i) .. "]", expected[i], actual[i])

      elseif actual[i] ~= expected[i] then
         add_index_error(prefix, i, "different_value", expected[i], actual[i])
      end
   end
   for _i, k in ipairs(keys) do
      if actual[k] == nil then
         add_key_error(prefix, k, "missing_key")

      elseif type(expected[k]) == "table" and type(actual[k]) == "table" then

         deep_compare(prefix .. "." .. tostring(k), expected[k], actual[k])

      elseif actual[k] ~= expected[k] then
         add_key_error(prefix, k, "different_value", expected[k], actual[k])
      end
   end


   keys, _key_length, sequence = inspect.getKeys(actual)
   for i = 1, sequence do
      if expected[i] == nil then add_index_error(prefix, i, "additional_key") end
   end
   for _i, k in ipairs(keys) do
      if expected[k] == nil then add_key_error(prefix, k, "additional_key") end
   end
end

local function assert_tables(expected, actual)
   deep_compare("", expected, actual)



   if #tadd.buffer == 0 then
      return true, ""
   end

   tadd.add("\nActual: \n", inspect.inspect(actual, {}))
   tadd.add("\n\nExpected: \n", inspect.inspect(expected, {}))

   return false, tadd.tostring()

end

return assert_tables
