# Additional Language Handlers
`tested` supports running unit tests for languages written that are Lua-compatible. It just need to be made aware how to load those files into a Lua environement.


## Setting up a format handler
Currently a new format hanlder involves creating a Lua table with the following attributes:


- `extension: string` - a string representing the file extension
- `loader: function(filepath: string): function(): any` - a function that can load the file. It should raise an error if something goes wrong, and return a loader function that when called, returns the module in Lua.


A very basic Lua handler:
```lua
local handler = {extension = ".lua"}

function handler.loader(filepath)
    print("Loading from my custom format loader!")
    return assert(loadfile(filepath))
end

return handler
```

Since it is early days, the attributes required in a handler could change (or be expanded upon), but the goal is to always be _easily extendible_.

## Loading a format handler
Currently the CLI can be used to load one or more custom handlers, either using `--format-handler` or `-x`. It should also be able to load from either a filepath or a Lua module:

```shell
tl --format-handler ./new-handler.lua -x handler_as_module
```

## Some notes on code coverage

Below is an example load function for [Teal](https://teal-language.org) files (this is already builtin to `tested`). Teal handles a lot of the loading a file correctly into the Lua space, but to get code coverage to work, we had to add a `@` before the filename so the file got loaded in a way to indicate that it was a file on disk.

```lua
function handler.loader(filepath: string): function(): any
    local file = io.open(filepath, "rb")
    -- the '@' is needed for luacov to be able to analyze the lines of teal files!
    local load_function, errors = tl.load(file:read("*all"), "@" .. filepath)
    file:close()
    if not load_function then error(errors) end
    return load_function
end
```

I'm not sure what the best way to handle this for other languages that transpile to Lua, so code coverage may or may not work. There are likely some ways to support it for not-as-directly transpiled to Lua languages, but that might be an exercise left to the reader :P. If you have soe ideas or want to help add another transpiled language - feel free to open up a [discussion](https://github.com/FourierTransformer/tested/discussions).
