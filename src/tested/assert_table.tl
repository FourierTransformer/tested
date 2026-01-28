local inspect = require("tested.libs.inspect")
local tadd = require("tested.libs.tadd")

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

local function add_index_error(prefix: string, index: integer, error_type: TableDiff, expected?: any, actual?: any)
   tadd.add(
      diff_symbol[error_type],
      prefix,
      "[",
      tostring(index),
      "]",
      diff_message[error_type]
   )
   if expected and actual then
      tadd.add(
         " (Expected: ",
         tostring(expected),
         "  Actual: ",
         tostring(actual),
         ")"
      )
   end
   tadd.add("\n")
end

local function add_key_error(prefix: string, key: any, error_type: TableDiff, expected?: any, actual?: any)
   tadd.add(
      diff_symbol[error_type],
      prefix,
      ".",
      tostring(key),
      diff_message[error_type]
   )
   if expected and actual then
      tadd.add(
         " (Expected: ",
         tostring(expected),
         "  Actual: ",
         tostring(actual),
         ")"
      )
   end
   tadd.add("\n")
end

local function deep_compare(prefix: string, expected: table, actual: table)
   -- not cycle safe, but might be good enough to get us started?
   local keys, _key_length, sequence = inspect.getKeys(expected)
   for i = 1, sequence do
      if actual[i] == nil then
         add_index_error(prefix, i, "missing_key")

      elseif type(expected[i]) == "table" and type(actual[i]) == "table" then
         -- DESCEND!
         deep_compare(prefix .. "[" .. tostring(i) .."]", expected[i] as {any:any}, actual[i] as {any:any})

      elseif actual[i] ~= expected[i] then
         add_index_error(prefix, i, "different_value", expected[i], actual[i])
      end
   end
   for _i, k in ipairs(keys) do
      if actual[k] == nil then
         add_key_error(prefix, k, "missing_key")

      elseif type(expected[k]) == "table" and type(actual[k]) == "table" then
         -- DESCEND!
         deep_compare(prefix .. "." .. tostring(k), expected[k] as {any:any}, actual[k] as {any:any})

      elseif actual[k] ~= expected[k] then
         add_key_error(prefix, k, "different_value", expected[k], actual[k])
      end
   end

   -- check if there are any additional keys floating around
   keys, _key_length, sequence = inspect.getKeys(actual)
   for i = 1, sequence do 
      if expected[i] == nil then add_index_error(prefix, i, "additional_key") end
   end
   for _i, k in ipairs(keys) do
      if expected[k] == nil then add_key_error(prefix, k, "additional_key") end
   end
end

local function assert_tables(expected: table, actual: table): (boolean, string)
   deep_compare("", expected, actual)

   -- since change table starts off in there.
   -- using tadd here feels super risky to me... might switch to a bool or something?
   if #tadd.buffer == 0 then
      return true, ""
   end

   tadd.add("\nActual: \n", inspect.inspect(actual, {}))
   tadd.add("\n\nExpected: \n", inspect.inspect(expected, {}))

   return false, tadd.tostring()

end

return assert_tables