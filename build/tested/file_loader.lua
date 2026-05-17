
local logging = require("tested.libs.logging")

local logger = logging.get_logger("tested.file_loader")

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
   if not (type(handler.extension) == "string" and type(handler.loader) == "function") then
      error("The language handler '" .. filepath .. "' should return a table with at least 'extension' and 'loader' populated to be a valid language handler.")
   end
   file_loader.register_handler(handler.extension, handler.loader, handler.setup)
end

function file_loader.register_language_handlers(handlers)
   for _, handler in ipairs(handlers) do
      logger:info("Registering language handler: %s", handler)
      local ok, module_language_handler = pcall(require, handler)

      if ok then
         if not (type(module_language_handler.extension) == "string" and type(module_language_handler.loader) == "function") then
            error("The language handler '" .. handler .. "' should return a table with at least 'extension' and 'loader' populated to be a valid language handler.")
         end
         file_loader.register_handler(module_language_handler.extension, module_language_handler.loader, module_language_handler.setup)
      else

         file_loader.load_and_register_handler(handler)
      end
   end
end

return file_loader
