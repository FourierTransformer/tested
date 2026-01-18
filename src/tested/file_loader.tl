local tl = require("tl")
-- tl.loader()

local function load_lua_file(_file: FILE, filepath: string): function(): any
    -- local module = filepath:gsub(".lua$", "")
    -- module = module:gsub("/", ".")
    -- return function(): any
    --     return require(module)
    -- end
    return assert(loadfile(filepath))
end

local function load_teal_file(file: FILE, filepath: string): function(): any
    -- local module = filepath:gsub(".tl$", "")
    -- module = module:gsub("/", ".")
    -- return function(): any
    --     return require(module)
    -- end

    local load_function, errors = tl.load(file:read("*all"), filepath)
    if not load_function then error(errors) end
    return load_function
end

local record FileLoader
    load_file: function(filepath: string, loading_from?: string): any
    file_loader: {string: function(file: FILE, filepath: string): function()}
end

FileLoader.file_loader = {
    [".lua"] = load_lua_file,
    [".tl"] = load_teal_file
}

local function get_file_extension(str: string): string
    return str:match("^.+(%..+)$")
end

function FileLoader.load_file(filepath: string, loading_from?: string): any

    -- possibly only need this for custom formatter, might move this out of here!
    local file = io.open(filepath, "rb")
    if not file then
        local error_message = "file not found: " .. filepath
        if loading_from then
            error_message = "While " .. loading_from .. ", " .. error_message
        end
        error(error_message)
    end

    local extension = get_file_extension(filepath)
    if FileLoader.file_loader[extension] then
        local loader = FileLoader.file_loader[extension](file, filepath)
        return loader() as any
    end

    file:close()
    error("No file loader found for format: " .. extension)
end

return FileLoader