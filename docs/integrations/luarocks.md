# LuaRocks

For folks who use LuaRocks for project management and want to utilize `luarocks test` - `tested` can easily be setup to run within LuaRocks. All you have to do is add the following to your rockspec file:

```lua
test_dependencies = {
   "tested == 0.5.0", -- should be pinned to the specific version
}

test = {
   type = "tested",
   flags = { "-c" } -- "-c" enables code coverage, but any other CLI flags (or none) can be specified
}
```

The flags get passed to the [CLI](../reference/cli.md), each flag and value should be sent in as it's own string:

```lua
test = {
   type = "tested",
   flags = { "-c", "--tags", "ci" } -- runs tests tagged with ci
}
```