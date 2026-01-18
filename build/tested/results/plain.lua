local terminal = require("tested.results.terminal")


local plain = {}



plain.format = "plain"


terminal.colors.enable(false)
plain.header = terminal.header
plain.results = terminal.results
plain.summary = terminal.summary

return terminal
