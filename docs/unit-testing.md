# Unit Testing


## A basic test

## Testing tables

`tested.assert` can also deep compare tables, and will generate a little summary of the differences as well as print out the expected and actual table.

=== "Test"

    ```lua
    tested.test("table compare will error", function()
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
    
      tested.assert({
        given = "a basic table",
        should = "not be the same as the other table",
        expected = t1,
        actual = t2
      })
    end)
    ```

=== "Output"
    ```
    - tests/tables_test.tl (0.17ms)
      ✗ table compare will error (0.13ms)
       ✗ tests/tables_test.tl:27 - Given: a basic table  Should: not be the same as the other table
          - .config.crazy_table: Mising Key
          ~ .config.debug: Different Values
          ~ .name: Different Values (Expected: Alice  Actual: Bob)
          ~ .scores[2]: Different Values (Expected: 20  Actual: 25)
          + .email: Additional Key

          Actual:
          {
            age = 30,
            config = {
              debug = false,
              port = 8080
            },
            email = "bob@example.com",
            name = "Bob",
            scores = { 10, 25, 30 }
          }
    
          Expected:
          {
            age = 30,
            config = {
              crazy_table = { "hello", "world" },
              debug = true,
              port = 8080
            },
            name = "Alice",
            scores = { 10, 20, 30 }
          }
    ```
## Truthy/Falsy tests

Sometimes in Lua you want to check if _anything_ returned (like a `string.match` or that a value exists in a table), we've added in an `assert_truthy` and `assert_falsy` to help out in those cases.

We would recommend if you're looking for explicitly looking for `true` or `false`, maybe stick with the regular `assert` so your tests are more semantically correct, but if checking "exists" and "not exists", `assert_truthy` and `assert_falsy` are good candidates.

```lua
tested.test("truthy", function()
   tested.assert_truthy({given="empty string", actual=""})
   tested.assert_truthy({given="a number", actual=0})
   tested.assert_truthy({given="a function", actual=function() end})
   tested.assert_truthy({given="a table", actual={}})
   tested.assert_truthy({given="an unpack", actual=table.unpack({"a", "b"})})
   tested.assert_truthy({given="true boolean", actual=true})
   tested.assert_truthy({given="not false", actual=not false})
   tested.assert_truthy({given="not nil", actual=not nil})
   tested.assert_truthy({given="string.find he in hello", actual=string.find("hello", "he")})
end)

tested.test("falsy", function()
   local b
   tested.assert_falsy({given="nil", actual=nil})
   tested.assert_falsy({given="false", actual=false})
   tested.assert_falsy({given="unset variable", actual=b})
end)
```

## Testing exceptions
When writing assertions that check that an exception has been thrown, the `actual` should be a function taking no arguments, that when run raises an exception. `tested` also has the ability to capture an error (using `pcall` under the hood) and check if that returns as expected as well.

```lua
-- simple check that exception will be raised
tested.test("assert_throws_exception handles exception in assert", function()
    tested.assert_throws_exception({
        given = "an explicit error",
        actual = function() error("gets raised, but handled!") end
    })
end)

-- check that a specific exception was thrown
tested.test("example with exceptions and error checking", function()

    -- will throw the specific exception in "expected" below
    local function_that_throws = function()
        local options = {loadFromString=true, headers=false, fieldsToKeep={1, 2}}
        ftcsv.parse("apple>banana>carrot\ndiamond>emerald>pearl", ">", options)
    end
    tested.assert_throws_exception({
        given="no headers and no renaming takes place",
        expected="ftcsv: fieldsToKeep only works with header-less files when using the 'rename' functionality",
        actual=function_that_throws
    })
end)
```


## Skipping tests

If you need to have a test be skipped (for something is known broken) or want to _conditionally_ skip tests based on something that can be determined at runtime (LuaJIT, operating system, dependency present or not), there is `tested.skip` and `tested.conditional_test`:

```lua
tested.skip("skipping because tested.skip", function()
    tested.assert({expected = 8, actual = sum(4, 4)})
end)

-- the second argument to `conditional_test` takes in a boolean
-- true runs the test, false will skip it
tested.conditional_test("luajit only test", (type("jit") == "table"), function()
    tested.assert({expected = 8, actual = sum(5, 3) })
end)

```

## Only tests
There is also a `tested.only` which will only cause the tests marked with `tested.only` _in a test file_ to be run. This can be helpful if you need to debug a handful of tests and don't want to see the output of the other tests in the file (they will be marked as skipped). 

Since this only works on a _per-test file_ basis, it may also be useful to pass the specific test file to `tested` as well: `tested ./tests/file_with_only_test.lua`
```lua
-- this will be marked as skipped
tested.test("skipping because others are tested.only", function()
    tested.assert({expected = 8, actual = sum(4, 4)})
end)

-- only these two will be run in a specific file!
tested.only("this will run!", function()
    tested.assert({expected = 8, actual = sum(5, 3) })
end)

-- this also gets run since it is an only test
tested.only("this will also run!", function()
    tested.assert({expected = 8, actual = sum(2, 6) })
end)
```

## Invalid tests
If a test file has a test that throws an unhandled exception or `tested` finds a test without any asserts, they are considered "invalid", and will display as such in the results and will be listed in the summary as "invalid":

<code class="highlight md-code__content md-typeset overflow-auto">
<pre>
- tests/tested_test.tl (0.02ms)
  <span class="k">! Throws exception in assert (0.00ms)</span>
      tests/tested_test.tl:66: attempt to add a 'string' with a 'number'
      stack traceback:
        .../tested/lua/share/lua/5.4/tested/test_runner.lua:98: in field 'run'
        .../tested/lua/share/lua/5.4/tested/test_runner.lua:134: in function <.../tested/lua/share/lua/5.4/tested/test_runner.lua:125>
        (...tail calls...)
        [C]: in function 'pcall'
        .../tested/lua/share/lua/5.4/tested/libs/thread_pool.lua:59: in function <.../tested/lua/share/lua/5.4/tested/libs/thread_pool.lua:35>

  <span class="nf">? should return unknown since no tested.assert called (0.00ms)</span>
      No assertions run during test
</pre>
</code>

## On randomizing the order of tests
`tested` leaves it up to you on how you want to organize your unit tests. If you want a bunch of asserts in the same test, that's just fine!