

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

function tested.assert(assertion)
   local expected_type = type(assertion.expected)
   local actual_type = type(assertion.actual)

   if actual_type ~= expected_type then
      return false, "Expected: '" .. tostring(assertion.expected) .. "' (as '" ..
      expected_type .. "'). Actual: '" .. tostring(assertion.actual) .. "' (as '" .. actual_type .. "')"
   end


   if assertion.expected == assertion.actual then
      return true, ""
   end

   if expected_type == "number" and
      tostring(assertion.expected) == "nan" and
      tostring(assertion.actual) == "nan" then
      return true, ""
   end

   return false, "Expected: " .. tostring(assertion.expected) ..
   "\nActual: " .. tostring(assertion.actual)

end

return tested
