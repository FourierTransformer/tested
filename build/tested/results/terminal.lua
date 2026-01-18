
local colors = require("libs.ansicolors")

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
terminal.colors = colors

function terminal.header(modules)
   print(colors("%{bright}tested v0.0.0  " .. table.concat(modules, " ")))
   print()
end

local function to_ms(time)
   if time < 1 then
      return string.format("%.2fms", time * 1000)
   else
      return string.format("%.2fs", time)
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
   print(colors(test_color .. "- " .. tested_result.filename .. " (" .. to_ms(tested_result.total_time) .. ")"))
   for _, test_result in ipairs(tested_result.tests) do


      if test_types_to_display[test_result.result] then
         print(colors(color_map[test_result.result] .. symbol_map[test_result.result] .. " " .. test_result.name .. " (" .. to_ms(test_result.time) .. ")"))
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

function terminal.summary(counts, all_fully_tested, total_time)
   local summary = {}
   table.insert(summary, "%{bright}Test Summary (" .. to_ms(total_time) .. "):%{reset}")
   table.insert(summary, "  Run: %{green}" .. counts.passed .. " passed%{reset}, %{red}" .. counts.failed .. " failed%{reset}")
   table.insert(summary, "Other: %{yellow}" .. counts.skipped .. " skipped%{reset}, " .. counts.invalid .. " invalid")

   if all_fully_tested then
      table.insert(summary, "\n{%green}Fully Tested!%{reset}")
   end

   print(colors(table.concat(summary, "\n")))
end

return terminal
