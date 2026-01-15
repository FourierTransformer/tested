local tested = require("tested")

local t1 = {
  name = 'Alice',
  age = 30,
  scores = {10, 20, 30},
  config = { debug = true, port = 8080, crazy_table = {"hello", "world"} }
}

local t2 = {
  name = 'Bob',
  age = 30,
  scores = {10, 25, 30},
  config = { debug = false, port = 8080 },
  email = 'bob@example.com'
}


local t3 = {
  name = 'Alice',
  age = 30,
  scores = {10, 20, 30},
  config = { debug = true, port = 8080, crazy_table = {"hello", "world"} }
}

tested.test("table compare will error", function()
  tested.assert({
    given = "a basic table",
    should = "not be the same as the other table",
    expected = t1,
    actual = t2
  })

end)

tested.test("table compare should work", function()
  tested.assert({
    given = "a basic table",
    should = "be the same as the other table",
    expected = t1,
    actual = t3
  })
end)

return tested