local tl = require("tl")
local path = require("path")

local function load_lua_file(_file, filepath)
   return assert(loadfile(filepath))
end

local function load_teal_file(file, filepath)
   local load_function, errors = tl.load(file:read("*all"), filepath)
   if not load_function then error(errors) end
   return load_function
end

local file_loader = {
   [".lua"] = load_lua_file,
   [".tl"] = load_teal_file,
}

local function load_file(filepath, loading_from)
   local file = io.open(filepath, "rb")
   if not file then
      local error_message = "file not found: " .. filepath
      if loading_from then
         error_message = "While " .. loading_from .. ", " .. error_message
      end
      error(error_message)
   end

   local extension = path.suffix(filepath)
   if file_loader[extension] then
      local loader = file_loader[extension](file, filepath)
      return loader()
   end

   file:close()
   error("No file loader found for format: " .. extension)
end

return load_file
