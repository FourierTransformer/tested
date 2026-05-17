local inspect = require("tested.libs.inspect")
local tadd = require("tested.libs.tadd")







local diff_symbol = {
   missing_key = "- ",
   different_value = "~ ",
   additional_key = "+ ",
}

local diff_message = {
   missing_key = ": Missing Key",
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

local function add_index_eq_error(prefix, index)
   tadd.add("~ ", prefix, "[", tostring(index), "]: Not equal according to __eq\n")
end

local function add_key_eq_error(prefix, key)
   tadd.add("~ ", prefix, ".", tostring(key), ": Not equal according to __eq\n")
end


local function get_shared_eq_function(a, b)
   local mt = getmetatable(a)
   if mt and mt == getmetatable(b) then
      return mt.__eq
   end
end

local function deep_compare(prefix, expected, actual, ancestors_expected, ancestors_actual)
   local expected_is_ancestor = ancestors_expected[expected]
   local actual_is_ancestor = ancestors_actual[actual]
   if expected_is_ancestor or actual_is_ancestor then
      if not (expected_is_ancestor and actual_is_ancestor) then
         tadd.add("~ ", prefix, ": Cycle structure mismatch\n")
      end
      return
   end
   ancestors_expected[expected] = true
   ancestors_actual[actual] = true

   local keys, _key_length, sequence = inspect.getKeys(expected)
   for i = 1, sequence do
      if actual[i] == nil then
         add_index_error(prefix, i, "missing_key")

      elseif type(expected[i]) == "table" and type(actual[i]) == "table" then
         local eq_fn = get_shared_eq_function(expected[i], actual[i])
         if eq_fn then
            if not eq_fn(expected[i], actual[i]) then
               add_index_eq_error(prefix, i)
            end
         else
            deep_compare(prefix .. "[" .. tostring(i) .. "]", expected[i], actual[i], ancestors_expected, ancestors_actual)
         end

      elseif actual[i] ~= expected[i] then
         add_index_error(prefix, i, "different_value", expected[i], actual[i])
      end
   end
   for _i, k in ipairs(keys) do
      if actual[k] == nil then
         add_key_error(prefix, k, "missing_key")

      elseif type(expected[k]) == "table" and type(actual[k]) == "table" then
         local eq_fn = get_shared_eq_function(expected[k], actual[k])
         if eq_fn then
            if not eq_fn(expected[k], actual[k]) then
               add_key_eq_error(prefix, k)
            end
         else
            deep_compare(prefix .. "." .. tostring(k), expected[k], actual[k], ancestors_expected, ancestors_actual)
         end

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

   ancestors_expected[expected] = nil
   ancestors_actual[actual] = nil
end

local function assert_tables(expected, actual)
   local eq_fn = get_shared_eq_function(expected, actual)
   if eq_fn then
      if eq_fn(expected, actual) then
         return true, ""
      else
         tadd.add("Not equal according to __eq at root\n")
      end

   else
      deep_compare("", expected, actual, {}, {})

   end



   if #tadd.buffer == 0 then
      return true, ""
   end

   tadd.add("\nActual: \n", inspect.inspect(actual, {}))
   tadd.add("\n\nExpected: \n", inspect.inspect(expected, {}))

   return false, tadd.tostring()

end

return assert_tables
