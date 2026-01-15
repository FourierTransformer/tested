local tested = require("tested")

local function sum(a: number, b: number): number
    return a + b
end

-- Your test code (unchanged)
tested.test("sum()", function()
    
    -- some setup could go here!
    -- this should be run before every assert!
    local sum = sum

    local thing = {
        given = "4 + 5",
        should = "9",
        expected = 9.0,
        actual = sum(4, 5)
    }
    tested.assert(thing)

    tested.assert({
        given = "3 + 4",
        should = "return 7",
        expected = 7.0,
        actual = sum(3,2)
    })

    thing.should = "return 120120901293"
    thing.expected = 120120901293
    tested.assert(thing)
end)

tested.conditional_test("conditional guy over here", true, function()
    tested.assert({
        given = "4 + 4",
        should = "8",
        expected = 8,
        actual = sum(4, 4)
    })
end)

tested.conditional_test("conditional guy should be skipped", false, function()
    tested.assert({
        given = "4 and 4",
        should = "return 8",
        expected = 8,
        actual = sum(4, 4)
    })
end)

tested.test("just a test!", function()
    tested.assert({
        given = "4 + 4",
        should = "return 8",
        expected = 8,
        actual = sum(4, 4)
    })
end)

tested.test("Throws exception in assert", function()
    tested.assert({
        given = "2 + 2",
        should = "raise unhandled excpetion!",
        expected = 4,
        actual = ('a' as integer) + 1
    })
end)

tested.test("Properly handles exception in assert", function()
    tested.assert({
        given = "2 + 2",
        should = "raise handled excpetion!",
        expected = false,
        actual = pcall(function () error("gets raised, but handled!") end)
    })
end)

tested.test("should return unknown since no tested.assert called", function() end)

return tested