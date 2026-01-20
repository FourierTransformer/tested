

local function load_lua_file(filepath)
   return assert(loadfile(filepath))
end

local FileLoader = {}






FileLoader.file_loader = {
   [".lua"] = load_lua_file,
}

local function get_file_extension(str)
   return str:match("^.+(%..+)$")
end

function FileLoader.load_file(filepath)
   local extension = get_file_extension(filepath)
   if FileLoader.file_loader[extension] then
      local loader = FileLoader.file_loader[extension](filepath)
      return loader()
   else
      error("Unable to load file of type: '" .. extension .. "'. It must be registered first")
   end

   error("No file loader found for format: " .. extension)
end

function FileLoader.register_handler(extension, loader)
   FileLoader.file_loader[extension] = loader
end

function FileLoader.load_and_register_handler(filepath)
   local handler = FileLoader.load_file(filepath)
   FileLoader.register_handler(handler.extension, handler.loader)
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
   FileLoader.file_loader[".tl"] = load_teal_file
end


return FileLoader
