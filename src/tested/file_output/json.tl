local type types = require("tested.types")

-------------------------------------------------------------------------------
-- JSON Encoder from rxi/json.lua - used under MIT License
-------------------------------------------------------------------------------

local encode: function(val: table, stack?: table): string

local enum ESCAPE_CHAR
  "\\"
  "\""
  "\b"
  "\f"
  "\n"
  "\r"
  "\t"
end

local escape_char_map: {ESCAPE_CHAR:string} = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv: {string:string} = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c: ESCAPE_CHAR): string
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(_val: nil): string
  return "null"
end


local function encode_table(val: table, stack: table): string
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val as {any} then
      error("invalid table: sparse array")
    end
    -- Encode
    for _, v in ipairs(val as {table}) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val as {table:table}) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val: string): string
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val: number): string
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map: {string:any} = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val: table, stack?: table): string
  local t = type(val)
  local f = type_func_map[t] as function(table, table)
  if f then
    return f(val, stack) as string
  end
  error("unexpected type '" .. t .. "'")
end


-------------------------------------------------------------------------------
-- Below is standard `tested` licensed code
-------------------------------------------------------------------------------

local record json is types.ResultFormatter where self.format == "json" end

json.format = "json"


function json.header(_version: string, _filepaths: {string}, _comments: {string}): string
    return ""
end

function json.results(_tested_result: types.TestedOutput, _test_types_to_display: {types.TestResult: boolean}): string
    return ""
end

function json.summary(runner_output: types.TestRunnerOutput): string
    return encode(runner_output as table)
end


return json