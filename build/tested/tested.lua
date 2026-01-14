

local tested = { tests = {}, run_only_tests = false }

function tested.test(name, fn)
   table.insert(tested.tests, { name = name, fn = fn, kind = "test" })
end

function tested.skip(name, fn)
   table.insert(tested.tests, { name = name, fn = fn, kind = "skip" })
end

function tested.only(name, fn)
   tested.run_only_tests = true
   table.insert(tested.tests, { name = name, fn = fn, kind = "only" })
end

function tested.conditional_test(name, condition, fn)
   if condition then
      table.insert(tested.tests, { name = name, fn = fn, kind = "conditional_test" })
   else
      table.insert(tested.tests, { name = name, fn = fn, kind = "conditional_skip" })
   end
end

local function deep_compare(prefix, expected, actual)
   for k, v in pairs(expected) do
      if not actual[k] then
         print("missing key in actual", prefix .. "." .. tostring(k))

      elseif type(expected[k]) == "table" and type(actual[k] == "table") then

         deep_compare(prefix .. "." .. tostring(k), expected[k], actual[k])

      elseif actual[k] ~= v then
         print("differences in values", prefix .. "." .. tostring(k), tostring(actual[k]), tostring(v))
      end
   end

   for k, _ in pairs(actual) do
      if not expected[k] then

         print("additional key in actual", prefix .. tostring(k))
      end
   end
end



function tested.assert(assertion)
   local expected_type = type(assertion.expected)
   local actual_type = type(assertion.actual)

   if actual_type ~= expected_type then
      return false, "Expected: '" .. tostring(assertion.expected) .. "' (as '" ..
      expected_type .. "'). Actual: '" .. tostring(assertion.actual) .. "' (as '" .. actual_type .. "')"
   end

   if assertion.actual == assertion.expected then
      return true, ""
   end














   return false, "Expected: " .. tostring(assertion.expected) ..
   "\nActual: " .. tostring(assertion.actual)

end

return tested
