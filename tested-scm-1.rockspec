rockspec_format = "3.0"

package = "tested"
version = "scm-1"

source = {
   url = "git+https://github.com/FourierTransformer/tested.git",
   branch = "main"
}

description = {
   summary = "A language server for the Teal language",
   detailed = "A language server for the Teal language",
   homepage = "https://github.com/FourierTransformer/tested",
   license = "MIT"
}

dependencies = {
   "luafilesystem",
   "argparse",
}

build = {
   type = "builtin",
   modules = {
      ["tested"] = "build/tested/tested.lua",
      ["tested.tested_types"] = "build/tested/tested_types.lua"
      -- many other files need to be added.
   },
   -- install = {
   --   bin = {
   --     'tested' = 'src/bin/tested'
   --   }
   -- }
}
