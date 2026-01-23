local type types = require("tested.types")

local function load_lua_file(filepath: string): function(): any
    return assert(loadfile(filepath))
end

local record FileLoader is types.FileLoader
    load_file: function(filepath: string): any
    file_loader: {string: function(filepath: string): function()}
    register_handler: function(extension: string, loader: function(filepath: string): function(): any)
    load_and_register_handler: function(filepath: string)
end

FileLoader.file_loader = {
    [".lua"] = load_lua_file
}

local function get_file_extension(str: string): string
    return str:match("^.+(%..+)$")
end

function FileLoader.load_file(filepath: string): any
    local extension = get_file_extension(filepath)
    if FileLoader.file_loader[extension] then
        local loader = FileLoader.file_loader[extension](filepath)
        return loader() as any
    else
        error("Unable to load file of type: '" .. extension .. "'. It must be registered first")
    end

    error("No file loader found for format: " .. extension)
end

function FileLoader.register_handler(extension: string, loader: function(filepath: string): function(): any)
    FileLoader.file_loader[extension] = loader
end

function FileLoader.load_and_register_handler(filepath: string)
    local handler = FileLoader.load_file(filepath) as types.FileLoaderHandler
    FileLoader.register_handler(handler.extension, handler.loader) 
end

local tl_ok, tl = pcall(require, "tl")
if tl_ok then
    local function load_teal_file(filepath: string): function(): any
        -- very dirty hacks to turn filenames into requires.
        -- this is how I used to do it, and occaisionally go back to analyze differences
        -- local module = filepath:gsub("^./", "")
        -- module = module:gsub(".tl", "")
        -- module = module:gsub("/", ".")
        -- return function(): any return require(module) end

        local file = io.open(filepath, "rb")
        -- the '@' is a quick hack to get luacov to be able to analyze the lines of teal files!
        local load_function, errors = tl.load(file:read("*all"), "@" .. filepath)
        file:close()
        if not load_function then error(errors) end
        return load_function
    end
    FileLoader.file_loader[".tl"] = load_teal_file
end

-- ngl, this feels a little weird to do, but I really only want one shared instance of this across the app.
return FileLoader