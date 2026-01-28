
local colors = require("tested.libs.ansicolors")
local tadd = require("tested.libs.tadd")

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
   tadd.add("  ", symbol_map[assertion_result.result], " ", assertion_result.filename, ":", tostring(assertion_result.line_number))

   if assertion_result.given then
      tadd.add(" - Given: ", assertion_result.given)
      if assertion_result.should then
         tadd.add("  Should: ", assertion_result.should)
      end


   elseif assertion_result.should then
      tadd.add(" - Should: ", assertion_result.should)
   end
   tadd.add("\n")
end

function terminal.results(tested_result, test_types_to_display)
   tadd.new("%{bright}- ", tested_result.filename, to_ms(tested_result.total_time), "%{reset}\n")
   for _, test_result in ipairs(tested_result.tests) do


      if test_types_to_display[test_result.result] then
         tadd.add(color_map[test_result.result], symbol_map[test_result.result], " ", test_result.name, to_ms(test_result.time, false), "%{reset}\n")
         local extra_newline = false
         if test_result.result == "FAIL" or test_result.result == "PASS" then
            for _, assertion_result in ipairs(test_result.assertion_results) do
               if (assertion_result.result == "FAIL" and test_types_to_display["FAIL"]) or assertion_result.result == "PASS" and test_types_to_display["PASS"] then
                  format_assertion_result(assertion_result)

                  if assertion_result.result == "FAIL" then
                     tadd.add("      ", (assertion_result.error_message:gsub("\n", "\n      ")), "\n")
                  end
               end
               extra_newline = true
            end
            if extra_newline then tadd.add("\n") end
         end

         if test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" then
            tadd.add("      ", (test_result.message:gsub("\n", "\n      ")), "\n")
            tadd.add("\n")
         end
      end
   end
   print(colors(tadd.tostring()))
end


local function test_counts_s(test_count)
   if test_count == 1 then
      return tostring(test_count) .. " test"
   else
      return tostring(test_count) .. " tests"
   end
end

function terminal.summary(output)
   tadd.new("%{bright}Test Summary for ", test_counts_s(output.total_tests), to_ms(output.total_time, false), ":%{reset}\n")

   tadd.add(
   "  Run: %{green}",
   tostring(output.total_counts.passed),
   " passed%{reset}, %{red}",
   tostring(output.total_counts.failed),
   " failed%{reset}\n")


   tadd.add(
   "Other: %{yellow}",
   tostring(output.total_counts.skipped),
   " skipped%{reset}, ",
   tostring(output.total_counts.invalid),
   " invalid\n")


   if output.all_fully_tested then
      tadd.add("\n%{bright}Fully Tested!%{reset}\n")
   end

   print(colors(tadd.tostring()))
end

return terminal
