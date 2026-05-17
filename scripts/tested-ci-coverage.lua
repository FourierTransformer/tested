-- prepend build file location so luacov will pick this up instead
package.path = "./build/?.lua;" .. package.path

local luacov = require("luacov")

-- could probably do this via a Lua API one day! That day is not today...
require("tested.main")
