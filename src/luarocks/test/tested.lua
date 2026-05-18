-- this is modified from the busted test runner in the LuaRocks source - MIT

local _table_unpack = unpack or table.unpack

local tested_backend = {}

local fs = require("luarocks.fs")
local deps = require("luarocks.deps")
local path = require("luarocks.path")
local dir = require("luarocks.dir")
local queries = require("luarocks.queries")

-- I don't think the auto-detect will work unless LuaRocks is patched, so just going to omit for now.
-- People will just have to manually select it, which I think is fine
function tested_backend.detect_type()
   return false
end

function tested_backend.run_tests(test, args)
   if not test then
      test = {}
   end

   local ok, ver, where = deps.fulfill_dependency(queries.new("tested"), nil, nil, nil, "test_dependencies")
   if not ok then
      return nil, ver
   end

   local tested_exe
   if test.tested_executable then
      tested_exe = test.tested_executable
   else
      tested_exe = dir.path(path.root_dir(where), "bin", "tested")
      if not fs.exists(tested_exe) then
         return nil, "'tested' executable not found at: " .. tested_exe
      end
   end

   local err
   ok, err = fs.execute(tested_exe, _table_unpack(args))
   if ok then
      return true
   else
      return nil, err or "test suite failed."
   end
end

return tested_backend
