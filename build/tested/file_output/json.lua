
local dkjson = require("tested.libs.dkjson")

local json = {}

json.format = "json"

local function mark_options_as_objects(runner_output)
   for _, module_result in ipairs(runner_output.module_results) do
      for _, test in ipairs(module_result.tests) do
         setmetatable(test.options, { __jsontype = 'object' })
      end
   end
end

function json.header(_version, _filepaths, _comments)
   return ""
end

function json.results(_tested_result, _test_types_to_display)
   return ""
end

function json.summary(runner_output)
   mark_options_as_objects(runner_output)
   return dkjson.encode(runner_output, { indent = true })
end


return json
