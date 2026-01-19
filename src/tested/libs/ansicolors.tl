-- ansicolors.lua v1.0.2 (2012-08)

-- Copyright (c) 2009 Rob Hoelz <rob@hoelzro.net>
-- Copyright (c) 2011 Enrique García Cota <enrique.garcia.cota@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.


-- support detection
local function isWindows(): boolean
  return type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1,1) == '\\'
end

-- hacked in to get the windows detection code to work
local interface flag
  has_all_of: function(flag, any): boolean
end

local interface system
  COF_VIRTUAL_TERMINAL_PROCESSING: any
  getconsoleflags: function(FILE): flag
end

local enabled = not isWindows()
if isWindows() then 
  enabled = os.getenv("ANSICON") as boolean
  if not enabled then
    local ok, sys = pcall(require, "system") as (boolean, system)
    if ok and sys.getconsoleflags then
      local flags = sys.getconsoleflags(io.stdout)
      if flags then
        enabled = flags:has_all_of(sys.COF_VIRTUAL_TERMINAL_PROCESSING)
      end
    end
  end
end


local keys: {string: integer} = {
  -- reset
  reset =      0,

  -- misc
  bright     = 1,
  dim        = 2,
  underline  = 4,
  blink      = 5,
  reverse    = 7,
  hidden     = 8,

  -- foreground colors
  black     = 30,
  red       = 31,
  green     = 32,
  yellow    = 33,
  blue      = 34,
  magenta   = 35,
  cyan      = 36,
  white     = 37,

  -- background colors
  blackbg   = 40,
  redbg     = 41,
  greenbg   = 42,
  yellowbg  = 43,
  bluebg    = 44,
  magentabg = 45,
  cyanbg    = 46,
  whitebg   = 47
}

local escapeString = string.char(27) .. '[%dm'
local function escapeNumber(number): string
  return escapeString:format(number)
end

local function escapeKeys(str: string): string

  if not enabled then return "" end

  local buffer = {}
  local number: integer
  for word in str:gmatch("%w+") do
    number = keys[word]
    assert(number, "Unknown key: " .. word)
    table.insert(buffer, escapeNumber(number) )
  end

  return table.concat(buffer)
end

local function replaceCodes(str: string): string
  str = string.gsub(str,"(%%{(.-)})", function(_, found: string): string return escapeKeys(found) end )
  return str
end

-- public

local function ansicolors( str: string ): string
  str = tostring(str or '')

  return replaceCodes('%{reset}' .. str .. '%{reset}')
end

local record colors
  noReset: function(str: string): string
  enable: function(val: any)
  metamethod __call: function(colors, string): string
end

colors.noReset = replaceCodes
colors.enable = function(val) enabled = not not val end


local colors_mt: metatable<colors>
colors_mt = {
  __call = function(_self: colors, str: string): string
    return ansicolors(str)
  end
}

return setmetatable(colors, colors_mt)

-- return setmetatable({
--   noReset = replaceCodes,
--   enable = function(val) enabled = not not val end,
-- }, {
--   __call = function(_, str: string): string
--     return ansicolors(str) 
--   end,
-- })
