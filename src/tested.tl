local type types = require("tested.types")
local assert_table = require("tested.assert_table")

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


function tested.assert<T>(assertion: types.Assertion<T>): boolean, string
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
      actual_type .."'). Expected: " .. tostring(assertion.expected) .. " (as '" .. expected_type .. "')"
   end

   if assertion.actual == assertion.expected then
      return true, ""
   end

   if actual_type == "table" and expected_type == "table" then
      return assert_table(assertion.expected as table, assertion.actual as table)
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: " .. tostring(assertion.expected)
end

function tested.assert_truthy(assertion: types.TruthyAssertion): boolean, string
   return tested.assert({given=assertion.given, should=assertion.should or "be truthy", expected=true, actual=(not not (assertion.actual)) })
end

function tested.assert_falsy(assertion: types.FalsyAssertion): boolean, string
   return tested.assert({given=assertion.given, should=assertion.should or "be falsy", expected=false, actual=(not not (assertion.actual)) })
end

function tested.assert_throws_exception(assertion: types.ExceptionAssertion): boolean, string
   if assertion.expected then
      local function wrapped_pcall(): {boolean, string | any}
         local ok, err: boolean, string | any = pcall(function() assertion.actual() end)
         if err is string then
            return {ok, err:match(" (.-)$")}
         else
            return {ok, err}
         end
      end

      return tested.assert({
         given=assertion.given,
         should=assertion.should or "throw exception with error message",
         expected={false, assertion.expected}, 
         actual=wrapped_pcall()
      })
   else
      return tested.assert({
         given=assertion.given,
         should=assertion.should or "throw exception",
         expected=false, 
         actual=pcall(function() assertion.actual() end) 
      })
   end
end

return tested
