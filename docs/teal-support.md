# Teal Support

`tested` is built from the ground up with Teal and makes it a first class citizen. Be sure to have Teal [installed](https://teal-language.org/#download) when using `tested` with Teal so it will get auto-enabled. Unit tests can be written in Teal and all the functionality (including code coverage!) works across both languages wonderfully. However, there are a couple of things to keep in mind when using `tested` with Teal projects.

## Good to know
With the way Teal support has been added, `tl.loader()` gets called before running unit tests. This allows Teal files to be `require`'d if they are in the search path. `tl.loader()` adds the Teal package searcher into position two of `package.loaders`, which means if a Teal file and a Lua file are at the same path, the Teal file will be loaded first.

This also means that even if you write your test in Lua, but have it referencing a Teal library, it will use the Teal version of that library. For many situations this might not matter, since they are functionally the same, but it does mean that the Teal version will be re-compiled once per test file, which _could_ cause some performance issues for large Teal test suites. To at least partially mitigate this, `tested` (currently) compiles Teal files, but is set to not type-check them, to offer some time savings.

So yeah, currently two problems around this:

1. Lua files can "accidentally" load Teal modules
2. Teal files _always_ get re-compiled slowing down unit tests

If this is something you run into and is causing problems (or you have some ideas around it), [let us know](https://github.com/FourierTransformer/tested/issues/46) since we are considering some options there.
