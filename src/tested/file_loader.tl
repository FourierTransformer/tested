local type types = require("tested.types")
local logging = require("tested.libs.logging")

local logger = logging.get_logger("tested.file_loader")

local function load_lua_file(filepath: string): function(): any
   return assert(loadfile(filepath))
end

local record file_loader is types.FileLoader
   load_file: function(filepath: string): any
   loader: {string: function(filepath: string): function()}
   setups: {function}
   register_handler: function(extension: string, loader: function(filepath: string): function(): any, setup: function)
   load_and_register_handler: function(filepath: string)
end

local function get_file_extension(str: string): string
   return str:match("^.+(%..+)$")
end

file_loader.loader = {
   [".lua"] = load_lua_file
}
file_loader.setups = {}

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

function file_loader.register_handler(extension: string, loader: function(filepath: string): function(): any, setup: function)
   file_loader.loader[extension] = loader
   if setup then
      table.insert(file_loader.setups, setup)
   end
end

function file_loader.load_and_register_handler(filepath: string)
   local handler = file_loader.load_file(filepath) as types.LanguageHandler
   file_loader.register_handler(handler.extension, handler.loader, handler.setup)
end

function file_loader.register_language_handlers(handlers: {string})
   for _, handler in ipairs(handlers) do
      logger:info("Registering language handler: %s", handler)
      local ok, module_language_handler = pcall(require, handler) as (boolean, types.LanguageHandler)
      -- try as a module
      if ok then
          file_loader.register_handler(module_language_handler.extension, module_language_handler.loader, module_language_handler.setup)
      else
         -- fallback as a file
         file_loader.load_and_register_handler(handler)
      end
   end
end

return file_loader
