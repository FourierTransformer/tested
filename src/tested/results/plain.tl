local terminal = require("tested.results.terminal")
local type types = require("tested.types")

local record plain is types.ResultFormatter where self.format == "plain"

end

plain.format = "plain"

-- just disable terminal, but output the same thing
terminal.colors.enable(false)
plain.header = terminal.header
plain.results = terminal.results
plain.summary = terminal.summary

return terminal