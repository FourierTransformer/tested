rockspec_format = "3.0"

package = "tested"
version = "scm-1"

source = {
   url = "git+https://github.com/FourierTransformer/tested.git",
   branch = "main"
}

description = {
   summary = "A Unit Testing Framework for the Teal and Lua",
   homepage = "https://github.com/FourierTransformer/tested",
   license = "MIT"
}

dependencies = {
   "luafilesystem",
   "argparse",
   "tl==0.24.8" -- could maybe include tl?
}

build = {
   type = "builtin",
   modules = {
      tested = "build/tested.lua",

      ["tested.assert_table"] = "build/tested/assert_table.lua",
      ["tested.display"] = "build/tested/display.lua",
      ["tested.inspect"] = "build/tested/inspect.lua",
      ["tested.main"] = "build/tested/main.lua",
      ["tested.test_runner"] = "build/tested/test_runner.lua",
      ["tested.types"] = "build/tested/types.lua",
   },
   install = {
      bin = {
         'src/bin/tested'
      },
      lua = {
         "src/tested.tl",

         ["tested.assert_table"] = "src/tested/assert_table.tl",
         ["tested.display"] = "src/tested/display.tl",
         ["tested.inspect"] = "src/tested/inspect.tl",
         ["tested.main"] = "src/tested/main.tl",
         ["tested.test_runner"] = "src/tested/test_runner.tl",
         ["tested.types"] = "src/tested/types.tl",
      }
   }
}
