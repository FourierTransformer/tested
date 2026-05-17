local type types = require("tested.types")
local colors = require("tested.libs.ansicolors")
local tadd = require("tested.libs.tadd")

local SYMBOL_MAP <total>: {types.TestResult: string} = {
   PASS = " ✓",
   FAIL = " ✗",
   SKIP = " ⊘",
   FILTERED = " ᗊ",
   EXCEPTION = " !",
   TIMEOUT = " ⏱",
   UNKNOWN = " ?",
   EXPECTED_FAIL = "(✗)",
   EXPECTED_EXCEPTION = "(!)",
   EXPECTED_UNKNOWN = "(?)",
   UNEXPECTED = " ‽"
}

local COLOR_MAP <total>: {types.TestResult: string} = {
   PASS = " %{green}",
   FAIL = " %{red}",
   SKIP = " %{yellow}",
   FILTERED = " %{dim yellow}",
   EXCEPTION = " %{cyan}",
   TIMEOUT = " %{blue}",
   UNKNOWN = " %{magenta}",
   EXPECTED_FAIL = " %{dim red}",
   EXPECTED_EXCEPTION = " %{dim cyan}",
   EXPECTED_UNKNOWN = " %{dim magenta}",
   UNEXPECTED = " %{bright red}"
}

local record terminal is types.ResultFormatter where self.format == "terminal"
   format: string
   colors: colors
end

terminal.format = "terminal"
terminal.supports_show = true

-- used to disable the colors in the "plain" formatter
terminal.colors = colors

function terminal.header(version_info: string, filepaths: {string}, comments: {string}): string
   tadd.new("%{bright}", version_info, "  ", table.concat(filepaths, " "), "\n")
   for _, comment in ipairs(comments) do
      tadd.add(comment, "\n")
   end
   tadd.add("\n")
   return colors(tadd.tostring())
end

local function to_ms(time: number, add_color?: boolean): string
   if time < 1 then
      return string.format(" (%.2fms)", time*1000)
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

local function format_assertion_result(assertion_result: types.AssertionResult): string
   tadd.add("  ", SYMBOL_MAP[assertion_result.result], " ", assertion_result.filename, ":", tostring(assertion_result.line_number))
   -- given and should
   if assertion_result.given then
      tadd.add(" - Given: ", assertion_result.given)
      if assertion_result.should then
         tadd.add("  Should: ", assertion_result.should)
      end

   -- just should
   elseif assertion_result.should then
      tadd.add(" - Should: ", assertion_result.should)
   end
   tadd.add("\n")
end

function terminal.results(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean}): string
   tadd.new("%{bright}- ", tested_result.filename, to_ms(tested_result.total_time), "%{reset}\n")
   for _, test_result in ipairs(tested_result.tests) do

      -- if the user wants to see it
      if test_types_to_display[test_result.result] then
         tadd.add(COLOR_MAP[test_result.result], SYMBOL_MAP[test_result.result], " ", test_result.name, to_ms(test_result.time, false), "%{reset}\n")
         local extra_newline = false
         if test_result.result == "FAIL" or test_result.result == "PASS" or test_result.result == "EXPECTED_FAIL" then
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

         if test_result.result == "EXCEPTION" or test_result.result == "UNKNOWN" or test_result.result == "UNEXPECTED" or test_result.result == "EXPECTED_EXCEPTION" or test_result.result == "EXPECTED_UNKNOWN" then
            tadd.add("      ", (test_result.message:gsub("\n", "\n      ")), "\n")
            tadd.add("\n")
         end
      end
   end
   return colors(tadd.tostring())
end

-- just being particular!
local function test_counts_s(test_count: integer): string
   if test_count == 1 then
      return tostring(test_count) .. " test"
   else
      return tostring(test_count) .. " tests"
   end
end

function terminal.summary(output: types.TestRunnerOutput): string
   tadd.new("%{bright}Test Summary for ", test_counts_s(output.total_tests), to_ms(output.total_time, false), ":%{reset}\n")
   
   tadd.add(
      "  Run: %{green}",
      tostring(output.total_counts.passed),
      " passed%{reset}, %{red}",
      tostring(output.total_counts.failed), 
      " failed%{reset}"
   )

   -- only add expected if they are using it. Try to avoid confusing new users.
   if output.total_counts.expected > 0 then
      tadd.add(
         ", ",
         tostring(output.total_counts.expected),
         " expected"
      )
   end

   tadd.add("\n")
   
   tadd.add(
      "Other: %{yellow}",
      tostring(output.total_counts.skipped),
      " skipped%{reset}"
   )
   if output.total_counts.filtered > 0 then
      tadd.add(", %{dim}", tostring(output.total_counts.filtered), " filtered out%{reset}")
   end
   tadd.add(", ", tostring(output.total_counts.invalid), " invalid\n")

   if output.all_fully_tested then
      tadd.add("\n%{bright}Fully Tested!%{reset}\n")
   end

   return colors(tadd.tostring())
end

return terminal
