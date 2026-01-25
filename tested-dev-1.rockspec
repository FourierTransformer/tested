rockspec_format = "3.0"

package = "tested"
version = "dev-1"

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
   "luacov",
   "tl==0.24.8",
   "lanes==3.17.2"
}

build = {
   type = "cyan",
   install = {
      bin = {
         'src/bin/tested'
      },
   }
}
