

local function load_lua_file(filepath)
   return assert(loadfile(filepath))
end

local file_loader = {}






file_loader.loader = {
   [".lua"] = load_lua_file,
}

local function get_file_extension(str)
   return str:match("^.+(%..+)$")
end

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

function file_loader.register_handler(extension, loader)
   file_loader.loader[extension] = loader
end

function file_loader.load_and_register_handler(filepath)
   local handler = file_loader.load_file(filepath)
   file_loader.register_handler(handler.extension, handler.loader)
end

local tl_ok, tl = pcall(require, "tl")
if tl_ok then
   local function load_teal_file(filepath)
      local file = io.open(filepath, "rb")

      local load_function, errors = tl.load(file:read("*all"), "@" .. filepath)
      file:close()
      if not load_function then error(errors) end
      return load_function
   end
   file_loader.loader[".tl"] = load_teal_file
end

return file_loader
