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

-- Cycle tests
local cycle_a: {any:any} = {}
cycle_a["self"] = cycle_a

local cycle_b: {any:any} = {}
cycle_b["self"] = cycle_b

tested.test("self-referential tables with equivalent structure should be equal", function()
   tested.assert({
      given = "two tables that each contain a reference to themselves",
      should = "be considered structurally equal",
      expected = cycle_a,
      actual = cycle_b
   })
end)

local mutual_a: {any:any} = {}
local mutual_b: {any:any} = {}
mutual_a["other"] = mutual_b
mutual_b["other"] = mutual_a

local mutual_c: {any:any} = {}
local mutual_d: {any:any} = {}
mutual_c["other"] = mutual_d
mutual_d["other"] = mutual_c

tested.test("mutually-referential tables with equivalent structure should be equal", function()
   tested.assert({
      given = "two pairs of tables that reference each other",
      should = "be considered structurally equal",
      expected = mutual_a,
      actual = mutual_c
   })
end)

-- Cycle deeper in the tree: child holds a back-reference to its parent
local node_a: {any:any} = { name = "root", child = {} }
(node_a.child as {any:any})["parent"] = node_a

local node_b: {any:any} = { name = "root", child = {} }
(node_b.child as {any:any})["parent"] = node_b

tested.test("back-reference cycle two levels deep should be considered equal", function()
   tested.assert({
      given = "two trees where each child holds a reference back to its parent",
      should = "be considered structurally equal",
      expected = node_a,
      actual = node_b
   })
end)

-- __eq tests
local record Point
   x: number
   y: number
   _internal: string
   metamethod __eq: function(Point, Point): boolean
end

local point_mt: metatable<Point> = {
   __eq = function(a: Point, b: Point): boolean
      return a.x == b.x and a.y == b.y
   end
}

-- same logical value, but _internal differs — __eq should make them equal
local p1 = setmetatable({x=3, y=4, _internal="abc"} as Point, point_mt)
local p2 = setmetatable({x=3, y=4, _internal="xyz"} as Point, point_mt)

tested.test("tables with matching __eq should be considered equal", function()
   tested.assert({
      given = "two Point tables at the same coordinates with differing internal fields",
      should = "be equal according to their __eq metamethod",
      expected = p1,
      actual = p2
   })
end)

-- __eq returning false should still produce a failure, not a deep-field diff
local p3 = setmetatable({x=1, y=2} as Point, point_mt)
local p4 = setmetatable({x=9, y=9} as Point, point_mt)

tested.test("tables with non-matching __eq should be considered not equal", function()
   tested.assert({
      given = "two Point tables at different coordinates",
      should = "not be equal according to their __eq metamethod",
      expected = p3,
      actual = p4
   })
end)

-- deeply nested __eq tests
-- Shape has no __eq of its own; comparison falls through to deep_compare, which
-- then encounters Point fields that do have __eq
local p5 = setmetatable({x=3, y=4, _internal="abc"} as Point, point_mt)
local p6 = setmetatable({x=3, y=4, _internal="xyz"} as Point, point_mt)  -- same coords, differs only in _internal
local p7 = setmetatable({x=7, y=8} as Point, point_mt)                   -- different coords

local shape_a = { name = "circle", center = p5 }
local shape_b = { name = "circle", center = p6 }
local shape_c = { name = "circle", center = p7 }

tested.test("container table whose nested field has matching __eq should be equal", function()
   tested.assert({
      given = "two shapes whose center Points share coordinates but differ in _internal",
      should = "be equal because the nested Point's __eq only checks x and y",
      expected = shape_a,
      actual = shape_b
   })
end)

tested.test("container table whose nested field has non-matching __eq should not be equal", function()
   tested.assert({
      given = "two shapes whose center Points have different coordinates",
      should = "not be equal because the nested Point's __eq returns false",
      expected = shape_a,
      actual = shape_c
   })
end)

return tested
