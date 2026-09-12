-- this file is generated from the tested source.
-- It is intended to be used in a standlone manner.
-- it _does not_ provide the tested CLI tool.

-- To install the CLI tool, please install via LuaRocks:
-- luarocks install tested

-- The source code in this bundle is MIT Licensed, and also bundles in portions of the following:
-- kikito's inspect and ansicolors (both MIT Licensed)


do
local _ENV = _ENV
package.preload[ "tested.assert_table" ] = function( ... ) _ENV = _ENV;
local inspect = require("tested.libs.inspect")
local tadd = require("tested.libs.tadd")







local DIFF_SYMBOL = {
   missing_key = "- ",
   different_value = "~ ",
   additional_key = "+ ",
}

local DIFF_MESSAGE = {
   missing_key = ": Missing Key",
   different_value = ": Different Values",
   additional_key = ": Additional Key",
}

local function add_index_error(prefix, index, error_type, expected, actual)
   tadd.add(
   DIFF_SYMBOL[error_type],
   prefix,
   "[",
   tostring(index),
   "]",
   DIFF_MESSAGE[error_type])

   if expected and actual then
      tadd.add(
      " (Expected: ",
      tostring(expected),
      "  Actual: ",
      tostring(actual),
      ")")

   end
   tadd.add("\n")
end

local function add_key_error(prefix, key, error_type, expected, actual)
   tadd.add(
   DIFF_SYMBOL[error_type],
   prefix,
   ".",
   tostring(key),
   DIFF_MESSAGE[error_type])

   if expected and actual then
      tadd.add(
      " (Expected: ",
      tostring(expected),
      "  Actual: ",
      tostring(actual),
      ")")

   end
   tadd.add("\n")
end

local function add_index_eq_error(prefix, index)
   tadd.add("~ ", prefix, "[", tostring(index), "]: Not equal according to __eq\n")
end

local function add_key_eq_error(prefix, key)
   tadd.add("~ ", prefix, ".", tostring(key), ": Not equal according to __eq\n")
end


local function get_shared_eq_function(a, b)
   local mt = getmetatable(a)
   if mt and mt == getmetatable(b) then
      return mt.__eq
   end
end

local function deep_compare(prefix, expected, actual, ancestors_expected, ancestors_actual)
   local expected_is_ancestor = ancestors_expected[expected]
   local actual_is_ancestor = ancestors_actual[actual]
   if expected_is_ancestor or actual_is_ancestor then
      if not (expected_is_ancestor and actual_is_ancestor) then
         tadd.add("~ ", prefix, ": Cycle structure mismatch\n")
      end
      return
   end
   ancestors_expected[expected] = true
   ancestors_actual[actual] = true

   local keys, _key_length, sequence = inspect.getKeys(expected)
   for i = 1, sequence do
      if actual[i] == nil then
         add_index_error(prefix, i, "missing_key")

      elseif type(expected[i]) == "table" and type(actual[i]) == "table" then
         local eq_fn = get_shared_eq_function(expected[i], actual[i])
         if eq_fn then
            if not eq_fn(expected[i], actual[i]) then
               add_index_eq_error(prefix, i)
            end
         else
            deep_compare(prefix .. "[" .. tostring(i) .. "]", expected[i], actual[i], ancestors_expected, ancestors_actual)
         end

      elseif actual[i] ~= expected[i] then
         add_index_error(prefix, i, "different_value", expected[i], actual[i])
      end
   end
   for _i, k in ipairs(keys) do
      if actual[k] == nil then
         add_key_error(prefix, k, "missing_key")

      elseif type(expected[k]) == "table" and type(actual[k]) == "table" then
         local eq_fn = get_shared_eq_function(expected[k], actual[k])
         if eq_fn then
            if not eq_fn(expected[k], actual[k]) then
               add_key_eq_error(prefix, k)
            end
         else
            deep_compare(prefix .. "." .. tostring(k), expected[k], actual[k], ancestors_expected, ancestors_actual)
         end

      elseif actual[k] ~= expected[k] then
         add_key_error(prefix, k, "different_value", expected[k], actual[k])
      end
   end


   keys, _key_length, sequence = inspect.getKeys(actual)
   for i = 1, sequence do
      if expected[i] == nil then add_index_error(prefix, i, "additional_key") end
   end
   for _i, k in ipairs(keys) do
      if expected[k] == nil then add_key_error(prefix, k, "additional_key") end
   end

   ancestors_expected[expected] = nil
   ancestors_actual[actual] = nil
end

local function assert_tables(expected, actual)
   local eq_fn = get_shared_eq_function(expected, actual)
   if eq_fn then
      if eq_fn(expected, actual) then
         return true, ""
      else
         tadd.add("Not equal according to __eq at root\n")
      end

   else
      deep_compare("", expected, actual, {}, {})

   end



   if #tadd.buffer == 0 then
      return true, ""
   end

   tadd.add("\nActual: \n", inspect.inspect(actual, {}))
   tadd.add("\n\nExpected: \n", inspect.inspect(expected, {}))

   return false, tadd.tostring()

end

return assert_tables
end
end

do
local _ENV = _ENV
package.preload[ "tested.libs.ansicolors" ] = function( ... ) _ENV = _ENV;

























local function isWindows()
   return type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1, 1) == '\\'
end











local enabled = not isWindows()
if isWindows() then
   enabled = os.getenv("ANSICON")
   if not enabled then
      local ok, sys = pcall(require, "system")
      if ok and sys.getconsoleflags then
         local flags = sys.getconsoleflags(io.stdout)
         if flags then
            enabled = flags:has_all_of(sys.COF_VIRTUAL_TERMINAL_PROCESSING)
         end
      end
   end
end


local keys = {

   reset = 0,


   bright = 1,
   dim = 2,
   underline = 4,
   blink = 5,
   reverse = 7,
   hidden = 8,


   black = 30,
   red = 31,
   green = 32,
   yellow = 33,
   blue = 34,
   magenta = 35,
   cyan = 36,
   white = 37,
   grey = 38,


   blackbg = 40,
   redbg = 41,
   greenbg = 42,
   yellowbg = 43,
   bluebg = 44,
   magentabg = 45,
   cyanbg = 46,
   whitebg = 47,
}

local escapeString = string.char(27) .. '[%dm'
local function escapeNumber(number)
   return escapeString:format(number)
end

local function escapeKeys(str)

   if not enabled then return "" end

   local buffer = {}
   local number
   for word in str:gmatch("%w+") do
      number = keys[word]
      assert(number, "Unknown key: " .. word)
      table.insert(buffer, escapeNumber(number))
   end

   return table.concat(buffer)
end

local function replaceCodes(str)
   str = string.gsub(str, "(%%{(.-)})", function(_, found) return escapeKeys(found) end)
   return str
end



local function ansicolors(str)
   str = tostring(str or '')

   return replaceCodes('%{reset}' .. str .. '%{reset}')
end

local colors = {}





colors.noReset = replaceCodes
colors.enable = function(val) enabled = not not val end


local colors_mt
colors_mt = {
   __call = function(_self, str)
      return ansicolors(str)
   end,
}

return setmetatable(colors, colors_mt)
end
end

do
local _ENV = _ENV
package.preload[ "tested.libs.inspect" ] = function( ... ) _ENV = _ENV;






local inspect = { Options = {} }























inspect._VERSION = 'inspect.lua 3.1.0'
inspect._URL = 'http://github.com/kikito/inspect.lua'
inspect._DESCRIPTION = 'human-readable representations of tables'
inspect._LICENSE = [[
  MIT LICENSE

  Copyright (c) 2022 Enrique García Cota

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
inspect.KEY = setmetatable({}, { __tostring = function() return 'inspect.KEY' end })
inspect.METATABLE = setmetatable({}, { __tostring = function() return 'inspect.METATABLE' end })

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

local function rawpairs(t)
   return next, t, nil
end



local function smartQuote(str)
   if match(str, '"') and not match(str, "'") then
      return "'" .. str .. "'"
   end
   return '"' .. gsub(str, '"', '\\"') .. '"'
end


local shortControlCharEscapes = {
   ["\a"] = "\\a", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r", ["\t"] = "\\t", ["\v"] = "\\v", ["\127"] = "\\127",
}
local longControlCharEscapes = { ["\127"] = "\127" }
for i = 0, 31 do
   local ch = char(i)
   if not shortControlCharEscapes[ch] then
      shortControlCharEscapes[ch] = "\\" .. i
      longControlCharEscapes[ch] = fmt("\\%03d", i)
   end
end

local function escape(str)
   return (gsub(gsub(gsub(str, "\\", "\\\\"),
   "(%c)%f[0-9]", longControlCharEscapes),
   "%c", shortControlCharEscapes))
end

local function isIdentifier(str)
   return type(str) == "string" and not not str:match("^[_%a][_%a%d]*$")
end

local flr = math.floor
local function isSequenceKey(k, sequenceLength)
   return type(k) == "number" and
   flr(k) == k and
   1 <= (k) and
   k <= sequenceLength
end

local defaultTypeOrders = {
   ['number'] = 1, ['boolean'] = 2, ['string'] = 3, ['table'] = 4,
   ['function'] = 5, ['userdata'] = 6, ['thread'] = 7,
}

local function sortKeys(a, b)
   local ta, tb = type(a), type(b)


   if ta == tb and (ta == 'string' or ta == 'number') then
      return (a) < (b)
   end

   local dta = defaultTypeOrders[ta] or 100
   local dtb = defaultTypeOrders[tb] or 100


   return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t)

   local seqLen = 1
   while rawget(t, seqLen) ~= nil do
      seqLen = seqLen + 1
   end
   seqLen = seqLen - 1

   local keys, keysLen = {}, 0
   for k in rawpairs(t) do
      if not isSequenceKey(k, seqLen) then
         keysLen = keysLen + 1
         keys[keysLen] = k
      end
   end
   table.sort(keys, sortKeys)
   return keys, keysLen, seqLen
end

local function countCycles(x, cycles)
   if type(x) == "table" then
      if cycles[x] then
         cycles[x] = cycles[x] + 1
      else
         cycles[x] = 1
         for k, v in rawpairs(x) do
            countCycles(k, cycles)
            countCycles(v, cycles)
         end
         countCycles(getmetatable(x), cycles)
      end
   end
end

local function makePath(path, a, b)
   local newPath = {}
   local len = #path
   for i = 1, len do newPath[i] = path[i] end

   newPath[len + 1] = a
   newPath[len + 2] = b

   return newPath
end


local function processRecursive(process,
   item,
   path,
   visited)
   if item == nil then return nil end
   if visited[item] then return visited[item] end

   local processed = process(item, path)
   if type(processed) == "table" then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey

      for k, v in rawpairs(processed) do
         processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
         if processedKey ~= nil then
            processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
         end
      end

      local mt = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end
      setmetatable(processedCopy, mt)
      processed = processedCopy
   end
   return processed
end

local function puts(buf, str)
   buf.n = buf.n + 1
   buf[buf.n] = str
end



local Inspector = {}










local Inspector_mt = { __index = Inspector }

local function tabify(inspector)
   puts(inspector.buf, inspector.newline .. rep(inspector.indent, inspector.level))
end

function Inspector:getId(v)
   local id = self.ids[v]
   local ids = self.ids
   if not id then
      local tv = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return id
end

function Inspector:putValue(v)
   local buf = self.buf
   local tv = type(v)
   if tv == 'string' then
      puts(buf, smartQuote(escape(v)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
      tv == 'cdata' or tv == 'ctype' then
      puts(buf, tostring(v))
   elseif tv == 'table' and not self.ids[v] then
      local t = v

      if t == inspect.KEY or t == inspect.METATABLE then
         puts(buf, tostring(t))
      elseif self.level >= self.depth then
         puts(buf, '{...}')
      else
         if self.cycles[t] > 1 then puts(buf, fmt('<%d>', self:getId(t))) end

         local keys, keysLen, seqLen = getKeys(t)

         puts(buf, '{')
         self.level = self.level + 1

         for i = 1, seqLen + keysLen do
            if i > 1 then puts(buf, ',') end
            if i <= seqLen then
               puts(buf, ' ')
               self:putValue(t[i])
            else
               local k = keys[i - seqLen]
               tabify(self)
               if isIdentifier(k) then
                  puts(buf, k)
               else
                  puts(buf, "[")
                  self:putValue(k)
                  puts(buf, "]")
               end
               puts(buf, ' = ')
               self:putValue(t[k])
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
            if seqLen + keysLen > 0 then puts(buf, ',') end
            tabify(self)
            puts(buf, '<metatable> = ')
            self:putValue(mt)
         end

         self.level = self.level - 1

         if keysLen > 0 or type(mt) == 'table' then
            tabify(self)
         elseif seqLen > 0 then
            puts(buf, ' ')
         end

         puts(buf, '}')
      end

   else
      puts(buf, fmt('<%s %d>', tv, self:getId(v)))
   end
end




function inspect.inspect(root, options)
   options = options or {}

   local depth = options.depth or (math.huge)
   local newline = options.newline or '\n'
   local indent = options.indent or '  '
   local process = options.process

   if process then
      root = processRecursive(process, root, {}, {})
   end

   local cycles = {}
   countCycles(root, cycles)

   local inspector = setmetatable({
      buf = { n = 0 },
      ids = {},
      cycles = cycles,
      depth = depth,
      level = 0,
      newline = newline,
      indent = indent,
   }, Inspector_mt)

   inspector:putValue(root)

   return table.concat(inspector.buf)
end


inspect.getKeys = getKeys
inspect.countCycles = countCycles

return inspect
end
end

do
local _ENV = _ENV
package.preload[ "tested.libs.shared" ] = function( ... ) _ENV = _ENV;


local types = require("tested.types")


local shared = {}







local cli_to_display = {
   ["skip"] = "SKIP",
   ["pass"] = "PASS",
   ["fail"] = "FAIL",
   ["exception"] = "EXCEPTION",
   ["unknown"] = "UNKNOWN",
   ["unexpected"] = "UNEXPECTED",

}

shared.version = "tested v0.5.0"

shared.blocking_sleep = function(s) local end_time = os.clock() + s; repeat until os.clock() > end_time end

function shared.create_tags_function(tags)
   if tags:match("[^a-zA-Z0-9_ ()]") then
      error("Invalid --tags expression: only letters, digits, underscores, spaces, and parentheses are allowed", 0)
   end
   local lua_expr = (tags:gsub("([a-zA-Z_][a-zA-Z0-9_]*)", function(word)
      if word == "and" or word == "or" or word == "not" then return word end
      return 'tags["' .. word .. '"]'
   end))
   local tag_filter = "local tags = ... \nreturn " .. lua_expr


   local string_loader = loadstring or load
   local loaded = string_loader(tag_filter)
   if not loaded then
      error("Invalid --tags expression '" .. tags .. "': Be sure to use boolean expressions ('or', 'and', 'not', etc) when combining tags", 0)
   end
   return loaded
end

function shared.display_types(options)
   local to_display = {}
   for _, cli_option in ipairs(options) do
      if cli_to_display[cli_option] then
         to_display[cli_to_display[cli_option]] = true
         if cli_option == "skip" then
            to_display["SKIP"] = true
         end
      else
         if cli_option == "invalid" then
            to_display["EXCEPTION"] = true
            to_display["UNKNOWN"] = true
            to_display["TIMEOUT"] = true
            to_display["UNEXPECTED"] = true
         elseif cli_option == "valid" then
            to_display["PASS"] = true
            to_display["SKIP"] = true
            to_display["FILTERED"] = true
            to_display["FAIL"] = true
            to_display["EXPECTED_FAIL"] = true
            to_display["EXPECTED_EXCEPTION"] = true
            to_display["EXPECTED_UNKNOWN"] = true
         elseif cli_option == "expected" then
            to_display["EXPECTED_FAIL"] = true
            to_display["EXPECTED_EXCEPTION"] = true
            to_display["EXPECTED_UNKNOWN"] = true
         end
      end
   end
   return to_display
end

function shared.combine_results(tests_output)
   local output = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, expected = 0, skipped = 0, filtered = 0, invalid = 0 },
      module_results = {},
   }

   for i, test_output in ipairs(tests_output) do
      output.module_results[i] = test_output

      if test_output.fully_tested == false then output.all_fully_tested = false end
      output.total_counts.passed = output.total_counts.passed + test_output.counts.passed
      output.total_counts.failed = output.total_counts.failed + test_output.counts.failed
      output.total_counts.expected = output.total_counts.expected + test_output.counts.expected
      output.total_counts.skipped = output.total_counts.skipped + test_output.counts.skipped
      output.total_counts.filtered = output.total_counts.filtered + test_output.counts.filtered
      output.total_counts.invalid = output.total_counts.invalid + test_output.counts.invalid
      output.total_time = output.total_time + test_output.total_time
      output.total_tests = output.total_tests + #test_output.tests
   end

   return output
end

return shared
end
end

do
local _ENV = _ENV
package.preload[ "tested.libs.tadd" ] = function( ... ) _ENV = _ENV;



local tadd = {}







tadd.buffer = {}

function tadd.clear()
   for i = 1, #tadd.buffer do
      tadd.buffer[i] = nil
   end
end



function tadd.add(...)
   local table_size = #tadd.buffer
   for i = 1, select("#", ...) do
      tadd.buffer[table_size + i] = select(i, ...)
   end
end

function tadd.new(...)
   tadd.clear()
   tadd.add(...)
end

function tadd.tostring()
   local output = table.concat(tadd.buffer)
   tadd.clear()
   return output
end

return tadd
end
end

do
local _ENV = _ENV
package.preload[ "tested.results.plain" ] = function( ... ) _ENV = _ENV;
local terminal = require("tested.results.terminal")


local plain = {}

plain.format = "plain"


terminal.colors.enable(false)
plain.header = terminal.header
plain.results = terminal.results
plain.summary = terminal.summary

return terminal
end
end

do
local _ENV = _ENV
package.preload[ "tested.results.tap" ] = function( ... ) _ENV = _ENV;

local tadd = require("tested.libs.tadd")

local tap = {}

tap.supports_show = false
tap.format = "tap"

function tap.header(version_info, _filepaths, comments)
   tadd.new("TAP version 14")
   tadd.add("\n# ", version_info)

   for _, comment in ipairs(comments) do
      tadd.add("\n# ", comment)
   end

   tadd.add("\n")

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
end
end

do
local _ENV = _ENV
package.preload[ "tested.results.terminal" ] = function( ... ) _ENV = _ENV;

local colors = require("tested.libs.ansicolors")
local tadd = require("tested.libs.tadd")

local SYMBOL_MAP = {
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
   UNEXPECTED = " ‽",
}

local COLOR_MAP = {
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
   UNEXPECTED = " %{bright red}",
}

local terminal = {}




terminal.format = "terminal"
terminal.supports_show = true


terminal.colors = colors

function terminal.header(version_info, filepaths, comments)
   tadd.new("%{bright}", version_info, "  ", table.concat(filepaths, " "), "\n")
   for _, comment in ipairs(comments) do
      tadd.add(comment, "\n")
   end
   tadd.add("\n")
   return colors(tadd.tostring())
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
   tadd.add("  ", SYMBOL_MAP[assertion_result.result], " ", assertion_result.filename, ":", tostring(assertion_result.line_number))

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
   " failed%{reset}")



   if output.total_counts.expected > 0 then
      tadd.add(
      ", ",
      tostring(output.total_counts.expected),
      " expected")

   end

   tadd.add("\n")

   tadd.add(
   "Other: %{yellow}",
   tostring(output.total_counts.skipped),
   " skipped%{reset}")

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
end
end


local assert_table = require("tested.assert_table")
local inspect = require("tested.libs.inspect")
local shared = require("tested.libs.shared")

local tested_class = {}
local tested = {}

local options_set = { tags = true, expected = true, run_when = true, retries = true, retry_delay = true }


function tested_class.new(filename)
   if filename == nil then
      filename = debug.getinfo(2, "S").short_src
   end

   local self = {
      tests = {},
      run_only_tests = false,
      filename = filename,
   }
   setmetatable(self, { __index = tested })

   return self
end

function tested_class.assert(assertion)
   local errors = {}
   if assertion.expected == nil then table.insert(errors, "In assertion table, 'expected' is currently 'nil'.") end
   if assertion.actual == nil then table.insert(errors, "In assertion table, 'actual' is currently 'nil'.") end
   if #errors ~= 0 then return false, table.concat(errors, "\n") .. "\nCannot perform comparisons with 'nil' - use 'tested.assert_nil' for 'nil' comparison." end
   if assertion.given and type(assertion.given) ~= "string" then
      table.insert(errors, "In assertion table, 'given' should be a 'string'. It appears to be a '" .. type(assertion.given) .. "' with value: '" .. tostring(assertion.given) .. "'.")
   end
   if assertion.should and type(assertion.should) ~= "string" then
      table.insert(errors, "In assertion table, 'should' should be a 'string'. It appears to be a '" .. type(assertion.should) .. "' with value: " .. tostring(assertion.should) .. "'.")
   end
   if #errors ~= 0 then return false, table.concat(errors, "\n") end
   local expected_type = type(assertion.expected)
   local actual_type = type(assertion.actual)

   if actual_type ~= expected_type then
      return false, "Actual: " .. tostring(assertion.actual) .. " (as '" ..
      actual_type .. "'). Expected: " .. tostring(assertion.expected) .. " (as '" .. expected_type .. "')"
   end



   if actual_type == "table" and expected_type == "table" then
      return assert_table(assertion.expected, assertion.actual)
   end

   if assertion.actual == assertion.expected then
      return true, ""
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: " .. tostring(assertion.expected)
end


function tested_class.assert_nil(assertion)
   assertion.should = assertion.should or "be nil"
   if assertion.actual == nil then
      return true, ""
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: nil"
end

function tested_class.assert_truthy(assertion)
   return tested_class.assert({ given = assertion.given, should = assertion.should or "be truthy", expected = true, actual = (not not (assertion.actual)), debug_var = assertion.debug_var })
end

function tested_class.assert_falsy(assertion)
   return tested_class.assert({ given = assertion.given, should = assertion.should or "be falsy", expected = false, actual = (not not (assertion.actual)), debug_var = assertion.debug_var })
end

function tested_class.assert_throws_exception(assertion)
   if assertion.expected then
      local function wrapped_pcall()
         local ok, err = pcall(function() assertion.actual() end)
         if type(err) == "string" then
            return { ok, err:match("^.+:%d+: (.+)$") or err }
         else
            return { ok, err }
         end
      end

      return tested_class.assert({
         given = assertion.given,
         should = assertion.should or "throw exception with error message",
         expected = { false, assertion.expected },
         actual = wrapped_pcall(),
         debug_var = assertion.debug_var,
      })
   else
      return tested_class.assert({
         given = assertion.given,
         should = assertion.should or "throw exception",
         expected = false,
         actual = pcall(function() assertion.actual() end),
         debug_var = assertion.debug_var,
      })
   end
end




local tested_object_call_error = "on your tested object ensure you are calling ':test' and not '.test'"

local function validate_options(test_name, options, filename)
   local error_prefix = filename .. " in \"" .. test_name .. "\": "

   for k, _ in pairs(options) do
      if not options_set[k] then
         error(error_prefix .. "options includes unknown value '" .. k .. "'. Options must be one of: " .. "'tags', 'expected', 'run_when', 'retries', or 'retry_delay'")
      end
   end

   if options.expected ~= nil then
      if type(options.expected) ~= "string" then
         error(error_prefix .. "options.expected takes in a 'string', but received '" .. type(options.expected) .. "'", 0)
      end
      if not (options.expected == "FAIL" or options.expected == "EXCEPTION" or options.expected == "UNKNOWN") then
         error(error_prefix .. "options.expected should be one of 'FAIL', 'EXCEPTION', or 'UNKNOWN'", 0)
      end
   end

   if options.run_when ~= nil then
      if type(options.run_when) ~= "boolean" then
         error(error_prefix .. "options.run_when takes in a 'boolean', but received '" .. type(options.run_when) .. "'", 0)
      end
   end

   if options.tags ~= nil then
      if type(options.tags) ~= "table" then
         error(error_prefix .. "options.tags takes in a '{string}', but received '" .. type(options.tags) .. "'", 0)
      end
      for i, tag in ipairs(options.tags) do
         if type(tag) ~= "string" then
            error(error_prefix .. "options.tags[" .. i .. "] should be a 'string', but received '" .. type(tag) .. "'", 0)
         end
         if tag == "and" or tag == "or" or tag == "not" then
            error(error_prefix .. "options.tags[" .. i .. "] appears to be a reserved keyword: 'and', 'or', or 'not'. Please change to a different tag name", 0)
         end
      end
   end

   if options.retries ~= nil then
      if type(options.retries) ~= "number" or (options.retries) ~= math.floor(options.retries) or (options.retries) < 0 then
         error(error_prefix .. "options.retries takes in a non-negative integer, but received '" .. tostring(options.retries) .. "'", 0)
      end
   end

   if options.retry_delay ~= nil then
      if type(options.retry_delay) ~= "number" or (options.retry_delay) < 0 then
         error(error_prefix .. "options.retry_delay takes in a non-negative number, but received '" .. tostring(options.retry_delay) .. "'", 0)
      end
   end
end

local function extract_fn_and_options(test_name, fn_or_options, fn, filename)
   local options = {}
   if type(fn_or_options) == "function" then
      fn = fn_or_options

   elseif type(fn_or_options) == "table" then
      options = fn_or_options
      if not fn then error("a function must be provided to run a unit test") end
      fn = fn
   end

   validate_options(test_name, options, filename)

   return fn, options
end


function tested:test(name, fn_or_options, fn)
   assert(type(self) == "table", tested_object_call_error)
   local func, options = extract_fn_and_options(name, fn_or_options, fn, self.filename)
   table.insert(self.tests, { name = name, fn = func, options = options, kind = "test" })
end

function tested:skip(name, fn_or_options, fn)
   assert(type(self) == "table", tested_object_call_error)
   local func, options = extract_fn_and_options(name, fn_or_options, fn, self.filename)
   table.insert(self.tests, { name = name, fn = func, options = options, kind = "skip" })
end

function tested:only(name, fn_or_options, fn)
   assert(type(self) == "table", tested_object_call_error)
   local func, options = extract_fn_and_options(name, fn_or_options, fn, self.filename)
   table.insert(self.tests, { name = name, fn = func, options = options, kind = "only" })
   self.run_only_tests = true
end

function tested:before(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.before_fn = fn
end

function tested:after(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.after_fn = fn
end

function tested:before_each(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.before_each_fn = fn
end

function tested:after_each(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.after_each_fn = fn
end

local function fisher_yates_shuffle(t)
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

local function should_skip_test(test, run_only, options)
   if run_only and test.kind ~= "only" then
      return "SKIP", "Only running 'tested:only' tests"

   elseif test.kind == "skip" then
      return "SKIP", "Test marked with 'tested:skip'"

   elseif test.options.run_when ~= nil and test.options.run_when == false then
      return "SKIP", "Condition in `run_when` returned false. Skipping test."

   elseif options and options.filter ~= nil and not string.find(test.name, options.filter) then
      return "FILTERED", "Test name does not match filter pattern '" .. options.filter .. "'"

   elseif options and options.tags_filter ~= nil then

      local tag_set = {}
      if test.options.tags then
         for _, tag in ipairs(test.options.tags) do tag_set[tag] = true end
      end

      if not options.tags_filter(tag_set) then
         return "FILTERED", "Test tags do not match tag filter expression"
      end
   end
   return nil, nil
end

local function captured_os_exit(code)
   local prefix = "os.exit()"
   if code then prefix = "os.exit(" .. tostring(code) .. ")" end
   error(prefix .. " intercepted — something tried to exit out of the process", 0)
end






local function wrap_assert(self, test_output)
   local original_assert = tested_class.assert
   local original_assert_nil = tested_class.assert_nil
   local counters = { total = 0, failed = 0 }

   local function record_result(ok, err, assertion, line_number)
      counters.total = counters.total + 1
      local assertion_result = {
         filename = self.filename,
         line_number = line_number,
         given = assertion.given,
         should = assertion.should,
      }
      if ok == false then
         counters.failed = counters.failed + 1
         assertion_result.result = "FAIL"
         assertion_result.error_message = err
         if assertion.debug_var ~= nil then
            if type(assertion.debug_var) == "table" then
               assertion_result.error_message = "debug_var: " .. inspect.inspect(assertion.debug_var, {})
            else
               assertion_result.error_message = "debug_var: " .. tostring(assertion.debug_var)
            end
         end
      else
         assertion_result.result = "PASS"
      end
      table.insert(test_output.assertion_results, assertion_result)
   end

   tested_class.assert = function(assertion)
      local ok, err = original_assert(assertion)
      record_result(ok, err, assertion, debug.getinfo(2, "l").currentline)
      return ok, err
   end

   tested_class.assert_nil = function(assertion)
      local ok, err = original_assert_nil(assertion)
      record_result(ok, err, assertion, debug.getinfo(2, "l").currentline)
      return ok, err
   end

   local function restore()
      tested_class.assert = original_assert
      tested_class.assert_nil = original_assert_nil
   end

   return counters, restore
end


local function swap_os_exit(test_fn)
   local original_os_exit
   if _VERSION == "Lua 5.1" then

      original_os_exit = getfenv(test_fn).os.exit
      getfenv(test_fn).os.exit = captured_os_exit
   else
      original_os_exit = os.exit
      os.exit = captured_os_exit
   end
   return original_os_exit
end

local function xpcall_handler(e)
   local msg = type(e) == "string" and (e) or tostring(e)
   return msg .. debug.traceback("", 2)
end

local function set_result(ok, err, total_assertions, assert_failed_count, test_output)
   if ok == false then
      test_output.result = "EXCEPTION"
      test_output.message = err

   elseif total_assertions == 0 then
      test_output.result = "UNKNOWN"
      test_output.message = "No assertions run during test"

   elseif assert_failed_count == 0 then
      test_output.result = "PASS"
      test_output.message = "All assertions have passed"

   else
      test_output.result = "FAIL"
      test_output.message = assert_failed_count .. " assertions have failed"
   end
end

local function restore_os_exit(test_fn, original)
   if _VERSION == "Lua 5.1" then
      getfenv(test_fn).os.exit = original
   else
      os.exit = original
   end
end


local function adjust_for_expected(expected, test_output)
   if expected ~= nil then
      if test_output.result == expected then
         if expected == "EXCEPTION" then
            test_output.result = "EXPECTED_EXCEPTION"
         elseif expected == "UNKNOWN" then
            test_output.result = "EXPECTED_UNKNOWN"
         elseif expected == "FAIL" then
            test_output.result = "EXPECTED_FAIL"
         end
      else
         test_output.message = "Expected test result to be " .. expected .. ", but came back as " .. test_output.result .. "\n" .. test_output.message
         test_output.result = "UNEXPECTED"
      end
   end
end

local function add_up_test_results(test_output, test_counts)
   if test_output.result == "PASS" then
      test_counts.passed = test_counts.passed + 1

   elseif test_output.result == "FAIL" then
      test_counts.failed = test_counts.failed + 1

   elseif test_output.result == "EXPECTED_FAIL" or test_output.result == "EXPECTED_EXCEPTION" or test_output.result == "EXPECTED_UNKNOWN" then
      test_counts.expected = test_counts.expected + 1

   elseif test_output.result == "EXCEPTION" or test_output.result == "UNKNOWN" or test_output.result == "UNEXPECTED" then
      test_counts.invalid = test_counts.invalid + 1

   elseif test_output.result == "SKIP" then
      test_counts.skipped = test_counts.skipped + 1

   elseif test_output.result == "FILTERED" then
      test_counts.filtered = test_counts.filtered + 1

   end
end

local function run_test(self, test, test_output)
   if self.before_each_fn then self.before_each_fn() end

   local assertions, restore = wrap_assert(self, test_output)
   local original_os_exit = swap_os_exit(test.fn)

   local ok, err = xpcall(test.fn, xpcall_handler)
   set_result(ok, err, assertions.total, assertions.failed, test_output)

   restore_os_exit(test.fn, original_os_exit)
   restore()


   adjust_for_expected(test.options.expected, test_output)

   if self.after_each_fn then self.after_each_fn() end
end

local function convert_to_test_options(options)
   local test_options
   if options then
      test_options = {
         random = options.random,
         filter = options.filter,
         clock_s = options.clock_s or os.clock,
         sleep_s = options.sleep_s or shared.blocking_sleep,
      }
      if options.tags then test_options.tags_filter = shared.create_tags_function(options.tags) end
   else
      test_options = {
         clock_s = os.clock,
         sleep_s = shared.blocking_sleep,
      }
   end
   return test_options
end

function tested:_run(options, filename)
   if options and options.random then
      math.randomseed(os.time())
      fisher_yates_shuffle(self.tests)
   end

   local test_results = {
      counts = { passed = 0, failed = 0, expected = 0, skipped = 0, filtered = 0, invalid = 0 },
      tests = {},


      filename = filename or self.filename,
      fully_tested = false,
      total_time = 0,
   }

   if self.before_fn then self.before_fn() end

   for i, test in ipairs(self.tests) do

      local retry_attempts = {}


      local test_result = { assertion_results = {}, name = test.name, options = test.options }

      local skip_result, skip_message = should_skip_test(test, self.run_only_tests, options)
      local start = options.clock_s()

      if skip_result then
         test_result.result = skip_result
         test_result.message = skip_message

      else
         run_test(self, test, test_result)

      end

      test_result.time = options.clock_s() - start

      local result = test_result.result
      local is_passing = result == "PASS" or result == "EXPECTED_FAIL" or result == "EXPECTED_EXCEPTION" or result == "EXPECTED_UNKNOWN"


      local retry_count = 0
      if test.options.retries and not skip_result and not is_passing and test.options.retries > 0 then
         while retry_count < test.options.retries do
            table.insert(retry_attempts, test_result)
            retry_count = retry_count + 1
            if test.options.retry_delay and options.sleep_s then
               options.sleep_s(test.options.retry_delay)
            end
            test_result = { assertion_results = {}, name = test.name, options = test.options }
            run_test(self, test, test_result)
         end
      end


      if retry_count > 0 then
         test_result.time = (options.clock_s() - start)
      end


      add_up_test_results(test_result, test_results.counts)


      test_result.retry_attempts = retry_attempts
      test_results.tests[i] = test_result
      test_results.total_time = test_results.total_time + test_result.time
   end

   if self.after_fn then self.after_fn() end

   if test_results.counts.failed == 0 and test_results.counts.invalid == 0 then
      test_results.fully_tested = true
   end

   return test_results
end

function tested:run(options, filename)
   assert(type(self) == "table", tested_object_call_error)
   local test_options = convert_to_test_options(options)
   return self:_run(test_options, filename)
end

function tested_class.run_tests(tests, options)
   local test_options = convert_to_test_options(options)

   local tests_output = {}
   for i, test in ipairs(tests) do
      tests_output[i] = test:_run(test_options)
   end

   return shared.combine_results(tests_output)
end

function tested_class.combine_results(tests_output)
   return shared.combine_results(tests_output)
end

function tested_class.format_results(tested_output, display_format, show)
   local formatter = require("tested.results." .. display_format)


   if not show then
      show = { "fail", "exception", "unknown", "unexpected" }
   end
   local show_all = false
   for _, display_option in ipairs(show) do if display_option == "all" then show_all = true; break end end
   if show_all then show = { "skip", "pass", "fail", "exception", "unknown", "expected", "unexpected" } end
   local to_display = shared.display_types(show)

   local output = {}

   output[1] = formatter.header(shared.version .. " (bundle)", {}, {})

   for i, test_result in ipairs(tested_output.module_results) do
      output[i + 1] = formatter.results(test_result, to_display)
   end

   table.insert(output, formatter.summary(tested_output))
   return table.concat(output)
end

function tested_class.format_result(test_result, display_format, show)
   local formatter = require("tested.results." .. display_format)


   if not show then
      show = { "fail", "exception", "unknown", "unexpected" }
   end
   local show_all = false
   for _, display_option in ipairs(show) do if display_option == "all" then show_all = true; break end end
   if show_all then show = { "skip", "pass", "fail", "exception", "unknown", "expected", "unexpected" } end
   local to_display = shared.display_types(show)

   return formatter.results(test_result, to_display)

end

return tested_class
