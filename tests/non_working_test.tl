local tested = require("tested")

tested.test("doesn't work with given and should being not strings!", function()
	tested.assert({
		given="true",
		should="1",
		expected=true,
		actual=true
	})
end)


tested.test("output should clearly show just given", function()
	tested.assert({
		given="true",
		expected=false,
		actual=true
	})
end)

tested.test("output should clearly show just should", function()
	tested.assert({
		should="true",
		expected=true,
		actual=false
	})
end)

return tested
