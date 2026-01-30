
local tadd = require("tested.libs.tadd")

local tap = {}

tap.allow_filtering = false
tap.format = "tap"

function tap.header(_version_info, _filepaths)
   print("TAP version 14")
end

function tap.results(tested_result, _test_types_to_display)
   tadd.new("# ", tested_result.filename, "\n")
   local tap_result

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

function tap.summary(output)
   print("1.." .. output.total_tests)
end

return tap
