local lfs = require("lfs")
local tested = require("tested_core")
local tl = require("tl")

-- since a lot of the tests are written in teal
tl.loader()

local function find_tests(files, test_path)
   for file in lfs.dir(test_path) do
      if not file:find("^%.") then
         local f = test_path..'/'..file
         local attr = lfs.attributes(f)
         if attr then
            if attr.mode == "directory" then
               find_tests(files, f)

            else
               local _, _, extension = file:find("^[^%.].-_test(%..-)$")
               if extension and attr.mode == "file" and (extension == ".lua" or extension == ".tl") then
                  table.insert(files, f)
               end
            end
         end
      end
   end
end

local files = {}
find_tests(files, "tests")

local tests = {}
for _, filename in ipairs(files) do
   local no_extension = filename:gsub(".lua$", "")
   no_extension = no_extension:gsub(".tl$", "")
   local lua_module = no_extension:gsub("/", ".")

   local test = require(lua_module)
   table.insert(tests, test)
end

local test_results = tested.run_tests(tests, {tags="(not demo) and (not teal_loader)"})
print(tested.format_results(test_results, "terminal"))

if test_results.all_fully_tested then
   os.exit(0)
else
   os.exit(1)
end
