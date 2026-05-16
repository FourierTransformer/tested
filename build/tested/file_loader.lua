

local function load_lua_file(filepath)
   return assert(loadfile(filepath))
end

local file_loader = {}







local function get_file_extension(str)
   return str:match("^.+(%..+)$")
end

file_loader.loader = {
   [".lua"] = load_lua_file,
}
file_loader.setups = {}

function file_loader.load_file(filepath)
   local extension = get_file_extension(filepath)
   if file_loader.loader[extension] then
      local loader = file_loader.loader[extension](filepath)
      return loader()
   else
      error("Unable to load file of type: '" .. extension .. "'. It must be registered first")
   end

   error("No file loader found for format: " .. extension)
end

function file_loader.register_handler(extension, loader, setup)
   file_loader.loader[extension] = loader
   if setup then
      table.insert(file_loader.setups, setup)
   end
end

function file_loader.load_and_register_handler(filepath)
   local handler = file_loader.load_file(filepath)
   file_loader.register_handler(handler.extension, handler.loader, handler.setup)
end

local tl_ok, tl = pcall(require, "tl")
if tl_ok then
   local function load_teal_file(filepath)
      local file, err = io.open(filepath, "rb")
      if not file then error("Cannot load filepath: '" .. filepath .. "' with error: " .. err) end
      local file_contents = file:read("*all")
      file:close()

      local load_function, errors = tl.load(file_contents, "@" .. filepath)
      if not load_function then error(errors) end
      return load_function
   end
   file_loader.loader[".tl"] = load_teal_file

   table.insert(file_loader.setups, function()
      local tl2 = require("tl")
      tl2.loader()


   end)
end

return file_loader
