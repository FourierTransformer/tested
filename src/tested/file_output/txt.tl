-- this is just the plain results formatter
local plain = require("tested.results.plain")
local type types = require("tested.types")

local record txt is types.ResultFormatter where self.format == "txt" end

txt.format = "txt"
txt.header = plain.header
txt.results = plain.results
txt.summary = plain.summary

return txt