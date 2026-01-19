
























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
