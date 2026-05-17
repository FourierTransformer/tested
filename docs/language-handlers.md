# Additional Language Handlers
`tested` supports running unit tests for languages written that are Lua-compatible. It just need to be made aware how to load those files into a Lua environement.


## Setting up a language handler
Currently a new language hanlder involves creating a Lua table with the following attributes and returning it:

- `extension: string` - a string representing the file extension
- `loader: function(filepath: string): function(): any` - a function that can load the file. It should raise an error if something goes wrong, and return a loader function that when called, returns the module in Lua. This is for loading tests written in a different language.
- `setup: function()` - this is run before tests get executed to support any language features that are needed for running a test itself.

### The loader
The loader sets up loading files given the specific extension. Since it is designed for use with `tested` it can load [test files](./unit-testing.md#tests) or [custom formatters](./custom-formatter.md). Both are zero-argument loading from files that return tables. So any files written in another language would have to be setup that way as well.

### The setup

In parallel mode, it's worth noting that the setup function is called _once_ for each worker thread, being executed inside of a Lua lane. In parallel mode (`-n 0` or `--thread 0`), the setup function should only be called once. Because of supporting parallel execution, the setup function can't have any _upvalues_ to C (this I think _could_ be supported if truly needed). In the example below, `tl.loader()` is invoked which modifies `package.loaders` (or `package.searchers` for LuaJIT/5.1) to support `require`ing Teal files from other Teal files.

### Example Language Handler

The Teal handler:
```lua
local teal_handler = {}

teal_handler.extension = ".tl"

teal_handler.loader = function(filepath)
   local tl = require("tl")

   local file, err = io.open(filepath, "rb")
   if not file then error("Cannot load filepath: '" .. filepath .. "' with error: " .. err) end
   local file_contents = file:read("*all")
   file:close()
   -- the '@' is to get luacov to be able to analyze the lines of teal files!
   local load_function, errors = tl.load(file_contents, "@" .. filepath)
   if not load_function then error(errors) end
   return load_function
end

teal_handler.setup = function()
   local tl = require("tl")
   tl.loader()
end

return teal_handler
```

Since it is early days, the attributes required in a handler could change (or be expanded upon), but the goal is to always be _easily extendible_.

## Loading a language handler
Currently the CLI can be used to load one or more custom handlers, either using `--language-handler` or `-x`. It should also be able to load from either a filepath or a Lua module:

```shell
tested --language-handler ./new-handler.lua -x handler_as_module
```

## Some notes on code coverage

In the Teal loader example above (which is already [builtin to `tested`]()), we setup the `@` before the filename so the file got loaded in a way to indicate that it was a file on disk. This (along with `tl.loader` properly handling the load of additional Teal files) allows `luacov` to provide coverage for Teal files.

Unfortunately, I'm not sure what the best way to handle this for other languages that compile to Lua, but extra care should be given if attempting to get code coverage to work. There are likely some ways to support it for not-as-directly compiled to Lua languages (mapping files?), but that might be an exercise left to the reader :P. If you have some ideas on how to solve or want to help add another compiled language - feel free to open up a [discussion](https://github.com/FourierTransformer/tested/discussions).
