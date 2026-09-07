local tested = require("tested")

local t = tested.new()

t:test("doesn't work with given and should being not strings!", function()
	tested.assert({
		given="true",
		should="1",
		expected=true,
		actual=true
	})
end)


t:test("output should clearly show just given", {tags={"demo"}}, function()
	tested.assert({
		given="true",
		expected=false,
		actual=true
	})
end)

t:test("output should clearly show just should", {tags={"demo"}}, function()
	tested.assert({
		should="true",
		expected=true,
		actual=false
	})
end)

return t
