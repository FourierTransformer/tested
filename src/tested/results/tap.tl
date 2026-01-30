local type types = require("tested.types")
local tadd = require("tested.libs.tadd")

local record tap is types.ResultFormatter where self.format == "tap" end

tap.allow_filtering = false
tap.format = "tap"

function tap.header(_version_info: string, _filepaths: {string})
   print("TAP version 14")
end

function tap.results(tested_result: types.TestedOutput, _test_types_to_display: {types.TestResult: boolean})
   tadd.new("# ", tested_result.filename, "\n")
   local tap_result: string
   
   for _, test in ipairs(tested_result.tests) do
      if test.result == "PASS" or test.result == "SKIP" or test.result == "CONDITIONAL_SKIP" then
         tap_result = "ok - "
      else
         tap_result = "not ok - "
      end
      tadd.add(tap_result, test.name)
      
      if test.result == "SKIP" or test.result == "CONDITIONAL_SKIP" then
         tadd.add(" # SKIP" or "", "\n")
      else
         tadd.add("\n")
      
         for j, assertion in ipairs(test.assertion_results) do
            if assertion.result == "PASS" or assertion.result == "SKIP" then
               tap_result = "    ok - "
            else
               tap_result = "    not ok - "
            end
            tadd.add(tap_result, tostring(j), "  ", tostring(assertion.line_number), ":")
            if assertion.given then
               tadd.add("  Given: ", assertion.given)
            end
            if assertion.should then
               tadd.add("  Should: ", assertion.should)
            end

            tadd.add("\n")

         end
         tadd.add("    1..", tostring(#test.assertion_results), "\n")
      end
   end

   print(tadd.tostring())
end

function tap.summary(output: types.TestRunnerOutput)
   print("1.." .. output.total_tests)
end

return tap