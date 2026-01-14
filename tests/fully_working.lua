local tested = require("tested.tested")

tested.test("just works!", function()
	tested.assert({
		given="nothing",
		should="just work!",
		expected=true,
		actual=true
	})
end)

return tested
