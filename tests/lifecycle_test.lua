local tested = require("tested")

local counts = { before = 0, after = 0, before_each = 0, after_each = 0 }

tested.before(function() counts.before = counts.before + 1 end)
tested.after(function() counts.after = counts.after + 1 end)
tested.before_each(function() counts.before_each = counts.before_each + 1 end)
tested.after_each(function() counts.after_each = counts.after_each + 1 end)

tested.test("before runs once before first test", function()
    tested.assert({ given = "before count",       should = "be 1",  expected = 1, actual = counts.before })
    tested.assert({ given = "after count",         should = "be 0",  expected = 0, actual = counts.after })
    tested.assert({ given = "before_each count",   should = "be 1",  expected = 1, actual = counts.before_each })
    tested.assert({ given = "after_each count",    should = "be 0",  expected = 0, actual = counts.after_each })
end)

tested.test("after_each runs after first test, before_each runs again", function()
    tested.assert({ given = "before count",       should = "still be 1", expected = 1, actual = counts.before })
    tested.assert({ given = "after count",         should = "still be 0", expected = 0, actual = counts.after })
    tested.assert({ given = "before_each count",   should = "be 2",       expected = 2, actual = counts.before_each })
    tested.assert({ given = "after_each count",    should = "be 1",       expected = 1, actual = counts.after_each })
end)

tested.test("this test is skipped", { run_when = false }, function() end)

tested.test("before_each and after_each do not run for skipped tests", function()
    tested.assert({ given = "before_each count", should = "be 3 not 4", expected = 3, actual = counts.before_each })
    tested.assert({ given = "after_each count",  should = "be 2 not 3", expected = 2, actual = counts.after_each })
end)

tested.test("before_each is one ahead of after_each within a running test body", function()
    tested.assert({ given = "before_each count", should = "be 4", expected = 4, actual = counts.before_each })
    tested.assert({ given = "after_each count",  should = "be 3", expected = 3, actual = counts.after_each })
end)

tested.test("after has not run during any test", function()
    tested.assert({ given = "after count",  should = "be 0", expected = 0, actual = counts.after })
    tested.assert({ given = "before count", should = "be 1", expected = 1, actual = counts.before })
end)

return tested
