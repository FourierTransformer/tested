local type types = require("tested.types")
local dkjson = require("tested.libs.dkjson")

local record json is types.ResultFormatter where self.format == "json" end

json.format = "json"

local function mark_options_as_objects(runner_output: types.TestRunnerOutput)
   for _, module_result in ipairs(runner_output.module_results) do
      for _, test in ipairs(module_result.tests) do
         setmetatable(test.options as table, {__jsontype = 'object'} as metatable<table>)
      end
   end
end

function json.header(_version: string, _filepaths: {string}, _comments: {string}): string
    return ""
end

function json.results(_tested_result: types.TestedOutput, _test_types_to_display: {types.TestResult: boolean}): string
    return ""
end

function json.summary(runner_output: types.TestRunnerOutput): string
    mark_options_as_objects(runner_output)
    return dkjson.encode(runner_output as table, {indent=true})
end


return json
