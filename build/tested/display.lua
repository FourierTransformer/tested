


local symbol_map = {
   PASS = " ✓",
   FAIL = " ✗",
   SKIP = " ⊘",
   CONDITIONAL_SKIP = " ⊘",
   EXCEPTION = " !",
   TIMEOUT = " ⏱",
   UNKNOWN = " ?",
}

local display = {}

function display.header(modules)
   print("tested v0.0.0  " .. table.concat(modules, " "))
   print()
end

local function to_ms(time_s)
   if time_s < 1 then
      return string.format("%.3fms", time_s * 1000)
   else
      return string.format("%.3fs", time_s)
   end
end

local function format_assertion_result(assertion_result)
   local output = "  " .. symbol_map[assertion_result.result] .. " " .. assertion_result.filename .. ":" .. assertion_result.line_number

   if assertion_result.given then
      output = output .. " - Given: " .. assertion_result.given
      if assertion_result.should then
         output = output .. "  Should: " .. assertion_result.should
      end


   elseif assertion_result.should then
      output = output .. " - Should: " .. assertion_result.should
   end
   return output
end

function display.results(tested_result, test_types_to_display)
   print("- " .. tested_result.module_name .. " (" .. to_ms(tested_result.total_time) .. ")")
   for _, test_result in ipairs(tested_result.tests) do


      if test_types_to_display[test_result.result] then
         print(symbol_map[test_result.result] .. " " .. test_result.name .. " (" .. to_ms(test_result.time) .. ")")

         if test_result.result == "FAIL" or test_result.result == "PASS" then
            for _, assertion_result in ipairs(test_result.assertion_results) do
               if (assertion_result.result == "FAIL" and test_types_to_display["FAIL"]) or assertion_result.result == "PASS" and test_types_to_display["PASS"] then
                  print(format_assertion_result(assertion_result))

                  if assertion_result.result == "FAIL" then
                     print("      " .. assertion_result.error_message:gsub("\n", "\n      "))
                     print()
                  end
               end
            end
         end

         if test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" then
            print("      " .. test_result.message:gsub("\n", "\n      "))
            print()
         end
      end
   end
end

function display.summary(counts, all_fully_tested, total_time)
   print("\nTest Summary (" .. to_ms(total_time) .. "):")
   print("  Run: " .. counts.passed .. " passed, " .. counts.failed .. " failed")
   print("Other: " .. counts.skipped .. " skipped, " .. counts.invalid .. " invalid")

   if all_fully_tested then
      print("\nFully Tested!")
   end
end

return display
