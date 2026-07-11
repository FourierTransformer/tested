local tested = require("tested")

-- Regression test: teal_handler.setup() installs tl.loader() at package.searchers
-- position 2, which lets require() resolve .tl files. That setup must only run
-- for .tl test files, so a .lua test file should never be able to require a
-- module that exists only as a .tl file.
tested.test("lua test files cannot accidentally load teal-only modules", function()
    tested.assert_throws_exception({
        given = "a .lua test file requiring a module that only exists as a .tl file",
        should = "fail, since the teal loader is not set up for .lua test files",
        actual = function() require("tests.lua.teal_only_dependency") end
    })
end)

return tested
