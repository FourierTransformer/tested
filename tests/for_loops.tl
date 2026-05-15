local tested = require("tested")

-- 1000 individual tests: most pass, a few fail sporadically (multiples of 97)
for i = 1, 1000 do
    tested.test("test #" .. i, {tags={"demo"}}, function()
        local expected = i * 2
        -- fail at multiples of 97 by returning wrong value
        local actual = (i % 97 == 0) and (expected + 1) or expected
        tested.assert({
            given = "i = " .. i,
            should = "double i",
            expected = expected,
            actual = actual,
        })
    end)
end

-- single test with 1000 asserts: fails sporadically (multiples of 113)
tested.test("1000 asserts with sporadic failures", {tags={"demo"}}, function()
    for i = 1, 1000 do
        local expected = i * i
        -- fail at multiples of 113 by returning a wrong value
        local actual = (i % 113 == 0) and (expected - 1) or expected
        tested.assert({
            given = "i = " .. i,
            should = "square i",
            expected = expected,
            actual = actual,
        })
    end
end)

return tested
