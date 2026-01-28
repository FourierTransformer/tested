local type types = require("tested.types")

local function load_lua_file(filepath: string): function(): any
   return assert(loadfile(filepath))
end

local record file_loader is types.FileLoader
   load_file: function(filepath: string): any
   loader: {string: function(filepath: string): function()}
   register_handler: function(extension: string, loader: function(filepath: string): function(): any)
   load_and_register_handler: function(filepath: string)
end

file_loader.loader = {
   [".lua"] = load_lua_file
}

local function get_file_extension(str: string): string
   return str:match("^.+(%..+)$")
end

function file_loader.load_file(filepath: string): any
   local extension = get_file_extension(filepath)
   if file_loader.loader[extension] then
      local loader = file_loader.loader[extension](filepath)
      return loader() as any
   else
      error("Unable to load file of type: '" .. extension .. "'. It must be registered first")
   end

   error("No file loader found for format: " .. extension)
end

function file_loader.register_handler(extension: string, loader: function(filepath: string): function(): any)
   file_loader.loader[extension] = loader
end

function file_loader.load_and_register_handler(filepath: string)
   local handler = file_loader.load_file(filepath) as types.FileLoaderHandler
   file_loader.register_handler(handler.extension, handler.loader) 
end

local tl_ok, tl = pcall(require, "tl")
if tl_ok then
   local function load_teal_file(filepath: string): function(): any
      local file = io.open(filepath, "rb")
      -- the '@' is a quick hack to get luacov to be able to analyze the lines of teal files!
      local load_function, errors = tl.load(file:read("*all"), "@" .. filepath)
      file:close()
      if not load_function then error(errors) end
      return load_function
   end
   file_loader.loader[".tl"] = load_teal_file
end

return file_loader