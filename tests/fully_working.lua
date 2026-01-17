local tested = require("tested")

tested.test("just works!", function()
	tested.assert({
		given="nothing",
		should="just work!",
		expected=true,
		actual=true
	})
end)

tested.test("just works without given and should!", function()
	tested.assert({
		expected=true,
		actual=true
	})
end)

return tested
