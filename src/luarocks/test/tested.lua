local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table; local _tl_table_unpack = unpack or table.unpack

local tested_backend = {}

local fs = require("luarocks.fs")
local deps = require("luarocks.deps")
local path = require("luarocks.path")
local dir = require("luarocks.dir")
local queries = require("luarocks.queries")

-- Auto-detection heuristic: tests/ directory containing *_test.lua or *_test.tl files.
-- Note: LuaRocks only checks hardcoded backends (busted, command) during auto-detection,
-- so this only fires if luarocks.test is patched to include "tested" in its type list.
-- Explicit `test = { type = "tested" }` in the rockspec is the supported path.
function tested_backend.detect_type()
   if fs.exists("tests") then
      local ok, lfs = pcall(require, "lfs")
      if ok then
         for filename in lfs.dir("tests") do
            if filename:match("_test%.lua$") or filename:match("_test%.tl$") then
               return true
            end
         end
      end
   end
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
   ok, err = fs.execute(tested_exe, _tl_table_unpack(args))
   if ok then
      return true
   else
      return nil, err or "test suite failed."
   end
end

return tested_backend
