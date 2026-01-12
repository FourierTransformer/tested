local tested = require("src.tested")

local function sum(a, b)
   return a + b
end


tested.test("sum()", function()



   local sum = sum

   local thing = {
      given = "4 + 5",
      should = "be 9",
      expected = 9.0,
      actual = sum(4, 5),
   }
   tested.assert(thing)

   tested.assert({
      given = "3 + 4",
      should = "be 7",
      expected = 7.0,
      actual = sum(3, 2),
   })

   thing.should = "120120901293"
   thing.expected = 120120901293
   tested.assert(thing)
end)

tested.conditional_test("some conditional guy over here", true, function()
   tested.assert({
      given = "4 + 4",
      should = "8",
      expected = 8,
      actual = sum(4, 4),
   })
end)

tested.conditional_test("some conditional guy should be skipped", false, function()
   tested.assert({
      given = "4 + 4",
      should = "8",
      expected = 8,
      actual = sum(4, 4),
   })
end)

tested.only("some other guy!", function()
   tested.assert({
      given = "4 + 4",
      should = "8",
      expected = 8,
      actual = sum(4, 4),
   })
end)

tested.only("Throws exception in assert", function()
   tested.assert({
      given = "2 + 2",
      should = "raise unhandled excpetion!",
      expected = 4,
      actual = ('a') + 1,
   })
end)


local test_runner = require("src.test_runner")
test_runner.run(tested)
