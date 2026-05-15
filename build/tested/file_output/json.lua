





local encode











local escape_char_map = {
   ["\\"] = "\\",
   ["\""] = "\"",
   ["\b"] = "b",
   ["\f"] = "f",
   ["\n"] = "n",
   ["\r"] = "r",
   ["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
   escape_char_map_inv[v] = k
end


local function escape_char(c)
   return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(_val)
   return "null"
end


local function encode_table(val, stack)
   local res = {}
   stack = stack or {}


   if stack[val] then error("circular reference") end

   stack[val] = true

   if rawget(val, 1) ~= nil or next(val) == nil then

      local n = 0
      for k in pairs(val) do
         if type(k) ~= "number" then
            error("invalid table: mixed or invalid key types")
         end
         n = n + 1
      end
      if n ~= #val then
         error("invalid table: sparse array")
      end

      for _, v in ipairs(val) do
         table.insert(res, encode(v, stack))
      end
      stack[val] = nil
      return "[" .. table.concat(res, ",") .. "]"

   else

      for k, v in pairs(val) do
         if type(k) ~= "string" then
            error("invalid table: mixed or invalid key types")
         end
         table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
      end
      stack[val] = nil
      return "{" .. table.concat(res, ",") .. "}"
   end
end


local function encode_string(val)
   return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)

   if val ~= val or val <= -math.huge or val >= math.huge then
      error("unexpected number value '" .. tostring(val) .. "'")
   end
   return string.format("%.14g", val)
end


local type_func_map = {
   ["nil"] = encode_nil,
   ["table"] = encode_table,
   ["string"] = encode_string,
   ["number"] = encode_number,
   ["boolean"] = tostring,
}


encode = function(val, stack)
   local t = type(val)
   local f = type_func_map[t]
   if f then
      return f(val, stack)
   end
   error("unexpected type '" .. t .. "'")
end






local json = {}

json.format = "json"


function json.header(_version, _filepaths, _comments)
   return ""
end

function json.results(_tested_result, _test_types_to_display)
   return ""
end

function json.summary(runner_output)
   return encode(runner_output)
end


return json
