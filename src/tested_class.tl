local record Assertion<T>
	given: string
	should: string
	expected: T
	actual: T
end

local enum TestType
	"test"
	"skip"
	"only"
	"conditional_test"
	"conditional_skip"
end

local record Test
	kind: TestType
	name: string
	fn: function()
end

local record Tested
	tests: {Test}
	run_only_tests: boolean
	assert: function<T>(assertion: Assertion<T>): boolean, string
	test: function(name: string, fn: function())
	skip: function(name: string, fn: function())
	only: function(name: string, fn: function())
	conditional_test: function(name: string, condition: boolean, fn: function())
end

return {Tested=Tested, Test=Test, Assertion=Assertion}