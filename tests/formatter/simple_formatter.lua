local formatter = {}

formatter.format = "simple"
formatter.allow_filtering = false

function formatter.header(version, filepaths, comments)
    return "CFMT_HEADER " .. version .. " " .. table.concat(filepaths, "|") .. "\n"
end

function formatter.results(tested_result, _)
    local lines = {"CFMT_FILE " .. tested_result.filename}
    for _, test in ipairs(tested_result.tests) do
        table.insert(lines, "CFMT_TEST " .. test.result .. " " .. test.name)
    end
    return table.concat(lines, "\n") .. "\n"
end

function formatter.summary(output)
    return "CFMT_SUMMARY total=" .. output.total_tests
        .. " passed=" .. output.total_counts.passed
        .. " failed=" .. output.total_counts.failed
        .. " skipped=" .. output.total_counts.skipped .. "\n"
end

return formatter
