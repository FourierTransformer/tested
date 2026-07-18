# Teal Support

`tested` is built from the ground up with Teal and makes it a first class citizen. Be sure to have Teal [installed](https://teal-language.org/#download) when using `tested` with Teal so it will get auto-enabled. Unit tests can be written in Teal and all the functionality (including code coverage!) works across both languages wonderfully. However, there are a couple of things to keep in mind when using `tested` with Teal projects.

## Good to know
With the way Teal support has been added, `tl.loader()` gets called before running unit tests. This allows Teal files to be `require`'d if they are in the search path. `tl.loader()` adds the Teal package searcher into position two of `package.loaders`, which means if a Teal file and a Lua file are at the same path, the Teal file will be loaded first.

The `package.loaders` also gets backed up and restored between test files, because of this, for each test _file_, any referenced Teal file will get re-compiled which can slow down unit tests. If you're unit testing has begun slowing down your workflows, it might be an idea to write the unit tests in Lua so only (the compiled) Lua files would get loaded.