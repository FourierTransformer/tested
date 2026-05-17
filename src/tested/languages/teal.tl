local type types = require("tested.types")

local record teal_handler is types.LanguageHandler
end

teal_handler.extension = ".tl"

teal_handler.loader = function(filepath: string): function(): any
   local tl = require("tl")

   local file, err = io.open(filepath, "rb")
   if not file then error("Cannot load filepath: '" .. filepath .. "' with error: " .. err) end
   local file_contents = file:read("*all")
   file:close()
   -- the '@' is a quick hack to get luacov to be able to analyze the lines of teal files!
   local load_function, errors = tl.load(file_contents, "@" .. filepath)
   if not load_function then error(errors) end
   return load_function
end

teal_handler.setup = function()
   local tl = require("tl")
   tl.loader()
end

return teal_handler