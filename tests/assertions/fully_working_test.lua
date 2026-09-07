local tested = require("tested")

local t = tested.new()

t:test("just works!", function()
	tested.assert({
		given="nothing",
		should="just work!",
		expected=true,
		actual=true
	})
end)

t:test("just works without given and should!", function()
	tested.assert({
		expected=true,
		actual=true
	})
end)

return t
