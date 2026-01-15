
local assert_table = require("tested.assert_table")

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
   local errors = {}
   if assertion.given == nil then table.insert(errors, "'given'") end
   if assertion.should == nil then table.insert(errors, "'should'") end
   if assertion.expected == nil then table.insert(errors, "'expected'") end
   if assertion.actual == nil then table.insert(errors, "'actual'") end
   assert(#errors == 0, "The assertion table must include 'given', 'should', 'expected', and 'actual'. Missing: " .. table.concat(errors, ", "))
   local expected_type = type(assertion.expected)
   local actual_type = type(assertion.actual)

   if actual_type ~= expected_type then
      return false, "Actual: " .. tostring(assertion.actual) .. " (as '" ..
      actual_type .. "'). Expected: " .. tostring(assertion.expected) .. " (as '" .. expected_type .. "')"
   end

   if assertion.actual == assertion.expected then
      return true, ""
   end

   if actual_type == "table" and expected_type == "table" then
      return assert_table(assertion.expected, assertion.actual)
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: " .. tostring(assertion.expected)

end

return tested
