
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
   if assertion.expected == nil then table.insert(errors, "'expected'") end
   if assertion.actual == nil then table.insert(errors, "'actual'") end
   assert(#errors == 0, "The assertion table must include 'expected' and 'actual'. Missing: " .. table.concat(errors, ", "))
   if assertion.given and type(assertion.given) ~= "string" then
      table.insert(errors, "In assertion, 'given' should be a 'string'. It appears to be a '" .. type(assertion.given) .. "' with value: '" .. tostring(assertion.given))
   end
   if assertion.should and type(assertion.should) ~= "string" then
      table.insert(errors, "In assertion, 'should' should be a 'string'. It appears to be a '" .. type(assertion.should) .. "' with value: " .. tostring(assertion.should))
   end
   assert(#errors == 0, table.concat(errors, ". "))
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

function tested.assert_truthy(assertion)
   return tested.assert({ given = assertion.given, should = assertion.should or "be truthy", expected = true, actual = (not not (assertion.actual)) })
end

function tested.assert_falsy(assertion)
   return tested.assert({ given = assertion.given, should = assertion.should or "be falsy", expected = false, actual = (not not (assertion.actual)) })
end

function tested.assert_throws_exception(assertion)
   if assertion.expected then
      local function wrapped_pcall()
         local ok, err = pcall(function() assertion.actual() end)
         if type(err) == "string" then
            return { ok, err:match(" (.-)$") }
         else
            return { ok, err }
         end
      end

      return tested.assert({
         given = assertion.given,
         should = assertion.should or "throw exception",
         expected = { false, assertion.expected },
         actual = wrapped_pcall(),
      })
   else
      return tested.assert({
         given = assertion.given,
         should = assertion.should or "throw exception",
         expected = false,
         actual = pcall(function() assertion.actual() end),
      })
   end
end

return tested
