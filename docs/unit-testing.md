# Unit Testing
`tested` as a framework, tries to let you _just write tests_. If you want multiple asserts in one test, go for it. Dynamically generate tests? No Problem! `tested` aims to be flexible enough to work with a wide variety of testing scenarios and philosophies.

## Tests

Below is an example of basic test comparing two tables, `tested.assert` will deep compare the tables, and generate a little summary of the differences as well as print out the expected and actual table.

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

### Table cycle compare
`tested` can also check for cycles within a table. It performs a basic structural check to ensure the _structure_ of the cycles are the same. So, if you're writing an assertion that compares tables, you should mirror the cycle in the `expected` table. If you instead reference the `actual` table's cycle it will be considerd a failure.

Example of a working cycle test:
```lua
tested.test("tables with self-cycles, but the same structure should be equal", function()
   local cycle_a: {any:any} = {}
   cycle_a["self"] = cycle_a

   local cycle_b: {any:any} = {}
   cycle_b["self"] = cycle_b

   tested.assert({
      given = "two tables that each contain a reference to themselves",
      should = "be considered structurally equal",
      expected = cycle_a,
      actual = cycle_b
   })
end)
```


### Skipping & Only tests

For quick debugging purposes, there are `tested.skip` and `tested.only`. These allow you to quickly isolate testing when running selective tests a particular file. For things that are going to broken longer term, you should set the `expected` option.


`tested.skip`:
```lua
tested.skip("skipping because tested.skip", function()
    tested.assert({expected = 8, actual = sum(4, 4)})
end)
```

There is also a `tested.only` which will only cause the tests marked with `tested.only` _in a test file_ to be run. This can be helpful if you need to debug a handful of tests and don't want to see the output of the other tests in the file (they will be marked as skipped).

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

Both of these work on a _per-test file_ basis, so it may also be useful to pass the specific test file that you are working with to `tested` as well: `tested ./tests/file_with_only_test.lua`



## Test Options

### Conditional Skipping
If you want to _conditionally_ skip tests based on something that can be determined at runtime (LuaJIT, operating system, dependency present or not), there is the `run_when` options

```lua
-- the `run_when` option takes in a boolean where true runs the test, false will skip it
tested.test("luajit only test", {run_when=(type(jit) == "table")}, function()
    tested.assert({expected = 8, actual = sum(5, 3) })
end)

```

### Expected Results
If there are tests that are going to be broken for an extended period of time (ex: dependencies outside of your control, waaayy out future feature, a bug fix in a future sprint) you can set the `expected` option:

```lua
tested.test("expected exception: throws as expected", {expected="EXCEPTION"}, function()
   error("this exception is expected")
end)
```

The values `expected` can be are:
- `FAIL`  - for tests that will simply just fail
- `EXCEPTION` - for tests that raise an error
- `UNKNOWN` - for tests with no assertions written

This will hide the test result from the default output, _however_, if the value of the test differs from the `expected` value, it **will** show up in the testing output and is considered `UNEXPECTED`:

```lua
-- this will show up in the tested output with an error message indicating that it's passed but has expected to fail.
tested.test("unexpected: expected fail but test passes", {expected="FAIL"}, function()
   tested.assert({
      given = "1 + 1",
      should = "equal 2",
      expected = 2,
      actual = 1 + 1
   })
end)
```



## Assertions

### Truthy/Falsy tests

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

### Testing exceptions
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

## Test Lifecycle
`tested` has support for a couple of test lifecycle methods. They allow you to register a function to run `before` any tests within the file have fun, `after` all tests have run, `before_each` test, and `after_each` test. If a test is skipped for any reason (`test.skip`, `run_when` is `false`, filtering, etc) the `before_each` and `after_each` will **not** be run. Test lifecycle hooks can be useful if you want to setup/teardown connections/services/configs, create or clean up temporary files, or even one day setup stubs and mocks!

Here's a simple example of what can be done:

```lua
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

-- before_each and after_each will not run on skipped tests!
tested.test("this test is skipped", { run_when = false }, function() end)
```

## Data/table driven tests
Since `tested` is designed to be inherently composable, so data driven or parametric tests just work with standard Lua conventions. Either entire `tested.test` or `tested.assert` can be wrapped, and as long as a good test name (for `tested.test`) or `given` (for `tested.assert`) are provided, the output will show exactly where things have failed.

=== "Test"

    ```lua
    local tested = require("tested")

    -- 1000 individual tests: most pass, a few fail sporadically (multiples of 97)
    for i = 1, 1000 do
        tested.test("test #" .. i, function()
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
    tested.test("1000 asserts with sporadic failures", function()
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

    ```

=== "Output"
    ```
    tested v0.2.0  tests/litmus_test.tl

    - tests/litmus_test.tl (3.14ms)
      ✗ test #97 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 97  Should: double i
          Actual: 195
          Expected: 194

      ✗ test #194 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 194  Should: double i
          Actual: 389
          Expected: 388

      ✗ test #291 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 291  Should: double i
          Actual: 583
          Expected: 582

      ✗ test #388 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 388  Should: double i
          Actual: 777
          Expected: 776

      ✗ test #485 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 485  Should: double i
          Actual: 971
          Expected: 970

      ✗ test #582 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 582  Should: double i
          Actual: 1165
          Expected: 1164

      ✗ test #679 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 679  Should: double i
          Actual: 1359
          Expected: 1358

      ✗ test #776 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 776  Should: double i
          Actual: 1553
          Expected: 1552

      ✗ test #873 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 873  Should: double i
          Actual: 1747
          Expected: 1746

      ✗ test #970 (0.00ms)
       ✗ tests/litmus_test.tl:9 - Given: i = 970  Should: double i
          Actual: 1941
          Expected: 1940

      ✗ 1000 asserts with sporadic failures (1.88ms)
       ✗ tests/litmus_test.tl:24 - Given: i = 113  Should: square i
          Actual: 12768
          Expected: 12769
       ✗ tests/litmus_test.tl:24 - Given: i = 226  Should: square i
          Actual: 51075
          Expected: 51076
       ✗ tests/litmus_test.tl:24 - Given: i = 339  Should: square i
          Actual: 114920
          Expected: 114921
       ✗ tests/litmus_test.tl:24 - Given: i = 452  Should: square i
          Actual: 204303
          Expected: 204304
       ✗ tests/litmus_test.tl:24 - Given: i = 565  Should: square i
          Actual: 319224
          Expected: 319225
       ✗ tests/litmus_test.tl:24 - Given: i = 678  Should: square i
          Actual: 459683
          Expected: 459684
       ✗ tests/litmus_test.tl:24 - Given: i = 791  Should: square i
          Actual: 625680
          Expected: 625681
       ✗ tests/litmus_test.tl:24 - Given: i = 904  Should: square i
          Actual: 817215
          Expected: 817216


    Test Summary for 1001 tests (3.14ms):
      Run: 990 passed, 11 failed
    Other: 0 skipped, 0 invalid
    ```


## Invalid tests
If a test file has a test that throws an unhandled exception, `tested` finds a test without any asserts, or a test with `expected` set returns without that result, they are considered "invalid", and will display as such in the results and will be listed in the summary as "invalid".

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
