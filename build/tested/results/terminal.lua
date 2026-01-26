
local colors = require("tested.libs.ansicolors")

local symbol_map = {
   PASS = " ✓",
   FAIL = " ✗",
   SKIP = " ⊘",
   CONDITIONAL_SKIP = " ⊘",
   EXCEPTION = " !",
   TIMEOUT = " ⏱",
   UNKNOWN = " ?",
}

local color_map = {
   PASS = " %{green}",
   FAIL = " %{red}",
   SKIP = " %{yellow}",
   CONDITIONAL_SKIP = " %{yellow}",
   EXCEPTION = " %{cyan}",
   TIMEOUT = " %{blue}",
   UNKNOWN = " %{magenta}",
}

local terminal = {}




terminal.format = "terminal"
terminal.allow_filtering = true


terminal.colors = colors

function terminal.header(version_info, filepaths)
   print(colors("%{bright}" .. version_info .. "  " .. table.concat(filepaths, " ")))
   print()
end

local function to_ms(time, add_color)
   if time < 1 then
      return string.format(" (%.2fms)", time * 1000)
   else
      if add_color then
         if time > 10 then
            return string.format(" %%{red dim}(%.2fs)%%{reset}", time)
         else
            return string.format(" %%{red}(%.2fs)%%{reset}", time)
         end
      else
         return string.format(" (%.2fs)", time)
      end
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

function terminal.results(tested_result, test_types_to_display)
   local test_color = "%{bright}"
   if tested_result.fully_tested then test_color = "%{bright}" end
   print(colors(test_color .. "- " .. tested_result.filename .. to_ms(tested_result.total_time)))
   for _, test_result in ipairs(tested_result.tests) do


      if test_types_to_display[test_result.result] then
         print(colors(color_map[test_result.result] .. symbol_map[test_result.result] .. " " .. test_result.name .. to_ms(test_result.time, false)))
         local extra_newline = false
         if test_result.result == "FAIL" or test_result.result == "PASS" then
            for _, assertion_result in ipairs(test_result.assertion_results) do
               if (assertion_result.result == "FAIL" and test_types_to_display["FAIL"]) or assertion_result.result == "PASS" and test_types_to_display["PASS"] then
                  print(format_assertion_result(assertion_result))

                  if assertion_result.result == "FAIL" then
                     print("      " .. assertion_result.error_message:gsub("\n", "\n      "))
                  end
               end
               extra_newline = true
            end
            if extra_newline then print() end
         end

         if test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" then
            print("      " .. test_result.message:gsub("\n", "\n      "))
            print()
         end
      end
   end
end


local function test_counts_s(test_count)
   if test_count == 1 then
      return tostring(test_count) .. " test"
   else
      return tostring(test_count) .. " tests"
   end
end

function terminal.summary(output)
   local summary = {}
   table.insert(summary, "%{bright}Test Summary for " .. test_counts_s(output.total_tests) .. to_ms(output.total_time, false) .. ":%{reset}")
   table.insert(summary, "  Run: %{green}" .. output.total_counts.passed .. " passed%{reset}, %{red}" .. output.total_counts.failed .. " failed%{reset}")
   table.insert(summary, "Other: %{yellow}" .. output.total_counts.skipped .. " skipped%{reset}, " .. output.total_counts.invalid .. " invalid")

   if output.all_fully_tested then
      table.insert(summary, "\n%{bright}Fully Tested!%{reset}")
   end

   print(colors(table.concat(summary, "\n")))
end

return terminal
