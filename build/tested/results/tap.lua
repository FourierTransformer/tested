
local tadd = require("tested.libs.tadd")

local tap = {}

tap.allow_filtering = false
tap.format = "tap"

function tap.header(_version_info, _filepaths, comments)
   tadd.new("TAP version 14")
   for _, comment in ipairs(comments) do
      tadd.add("\n# ", comment)
   end
   return tadd.tostring()
end

function tap.results(tested_result, _test_types_to_display)
   tadd.new("# ", tested_result.filename, "\n")
   local tap_result

   for i, test in ipairs(tested_result.tests) do
      local i_str = tostring(i)

      if test.result == "SKIP" or test.result == "FILTERED" then
         local reason = (test.message and test.message ~= "") and (" " .. test.message) or ""
         tadd.add("ok ", i_str, " - ", test.name, " # SKIP", reason, "\n")
      elseif test.result == "EXPECTED_FAIL" or test.result == "EXPECTED_EXCEPTION" or test.result == "EXPECTED_UNKNOWN" then
         tadd.add("ok ", i_str, " - ", test.name, " # TODO\n")
      else
         if #test.assertion_results > 0 then
            tadd.add("# Subtest: ", test.name, "\n")
            for j, assertion in ipairs(test.assertion_results) do
               if assertion.result == "PASS" or assertion.result == "SKIP" then
                  tap_result = "    ok "
               else
                  tap_result = "    not ok "
               end
               local has_detail = assertion.given or assertion.should
               tadd.add(tap_result, tostring(j), " - ", tostring(assertion.line_number), has_detail and ":" or "")
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

         if test.result == "PASS" then
            tap_result = "ok "
         else
            tap_result = "not ok "
         end
         tadd.add(tap_result, i_str, " - ", test.name, "\n")
      end
   end

   return tadd.tostring()
end

function tap.summary(output)
   return "1.." .. output.total_tests
end

return tap
