# Teal Support

`tested` is built from the ground up with with Teal and makes it a first class citizen. Unit tests can be written in Teal and all the functionality (including code coverage!) works across both languages wonderfully. However, there are a couple of things to keep in mind when using `tested` with Teal projects. 

## Build, then Test
If you have a Teal project and are writing your unit tests in Teal, _every_ test file will compile the Teal as it gets loaded.

Example Teal unit test:
```lua
local utf8validator = require("utf8validator") -- will compile the `utf8validator` module
local tested = require("tested")

tested.test("should support ascii", function()
   local start_seq = tonumber("00000000", 2)
   local end_seq = tonumber("01111111", 2)

   for i = start_seq, end_seq do
      tested.assert({
      	given="string.char " .. i,
      	should="support ascii char",
      	expected=true,
      	actual=utf8validator(string.char(i))
      })
   end

end)

return tested
```

Assuming I had multiple unit test files that all pull in `utf8validator`, every one of them will re-compile the `utf8validator.tl` file, which can slow down the test suite. If this slowdown is of particular concern, you should instead compile your Teal code first **and write your test files in Lua**. It really depends on how large your Teal project is, how many test files you have, and how you interface with them.

For example, if you are doing TDD, you may want to accept the performance loss and use Teal unit test files so that `tested` is _always_ using the Teal files as a source. If you have a large benchmarking test suite, it may make more sense to compile and then test.

In the future, I may consider adding in some way to avoid that additional compilation, so any Teal modules only get compiled once (I'm not even sure the best way to handle this considering we're using threads, if you have any suggestions, feel free to put in in a [discussion](https://github.com/FourierTransformer/tested/discussions)) but it sort've goes against the ethos of unit testing should be isolated if `require`'d modules start being shared.