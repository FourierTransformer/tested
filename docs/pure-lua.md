# Pure Lua Mode
The `tested` framework has been designed have a pure Lua API with no external dependencies. Because of this, `tested` can be fully run within any Lua environment, and we even provide a single-file Lua distribution that has as much as the `tested` functionality as possible. _Only the CLI_ requires additional dependencies to function (mostly around OS calls).

In theory this should allow `tested` to work with Neovim, LÖVE, and other embedded environments! We haven't tried it with any other environment yet, but if you've had success, please [let us know!](https://github.com/FourierTransformer/tested/discussions/categories/show-and-tell).

## Single File Distribution
In situations (like embedded applications or devices) where you don't have access to a full LuaRocks install, we provide a `testedb.lua` file that includes everything to run tested from the API.

## Using the `tested` API

## Feature Comparison

| Feature | Lua API | tested CLI |
| ------- | -------- | ------------ |
| Tests + Asserts | ✅ | ✅ |
| Lifecycle Managment | ✅ | ✅ |
| Tags + Filters | ✅ | ✅ |
| Terminal/Plain/TAP Output | ✅ | ✅ |
| Custom Formatter | ❌ | ✅ |
| Custom timers | ✅ | ❌ |
| Code Coverage | ❌ | ✅ |
| Text/JSON Output to File | ❌ | ✅ |
| Additional Language Handlers | ❌ | ✅ |
| Automatic Test Finding | ❌ | ✅ |
| Full Test Isolation | ❌ | ⚠️ |

### On Test Isolation
Ideally when running tests, each test file should be in its own isolated testing environment. In Lua this can be particularly tricky, since there isn't really a safe way to unload C modules. So, at best, you can unload Lua modules, but have to let C modules persist, which is how the `tested` CLI operates today.

For using `tested` from the Lua API directly, we currently _do not_ unload any modules between tests. Mostly because even doing that in an unknown environment could cause issues. Unfortunately this is an exercise left to the reader for those who truly need it.