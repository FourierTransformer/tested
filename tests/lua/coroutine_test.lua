local tested = require("tested")

tested.test("basic create and resume runs the function", function()
    local result = nil
    local co = coroutine.create(function() result = 42 end)
    tested.assert({ given = "status before first resume", should = "be suspended", expected = "suspended", actual = coroutine.status(co) })
    coroutine.resume(co)
    tested.assert({ given = "result after resume", should = "be 42", expected = 42, actual = result })
    tested.assert({ given = "status after completion", should = "be dead", expected = "dead", actual = coroutine.status(co) })
end)

tested.test("yield passes values back to the resume caller", function()
    local co = coroutine.create(function()
        coroutine.yield(10)
        coroutine.yield(20)
        coroutine.yield(30)
    end)
    local ok1, v1 = coroutine.resume(co)
    local ok2, v2 = coroutine.resume(co)
    local ok3, v3 = coroutine.resume(co)
    tested.assert({ given = "first resume ok",  expected = true, actual = ok1 })
    tested.assert({ given = "first yield value",  expected = 10, actual = v1 })
    tested.assert({ given = "second yield value", expected = 20, actual = v2 })
    tested.assert({ given = "third yield value",  expected = 30, actual = v3 })
end)

tested.test("resume passes values back into the coroutine via yield", function()
    local received = {}
    local co = coroutine.create(function()
        local a = coroutine.yield()
        local b = coroutine.yield()
        received = { a, b }
    end)
    coroutine.resume(co)
    coroutine.resume(co, "hello")
    coroutine.resume(co, "world")
    tested.assert({ given = "first received value",  expected = "hello", actual = received[1] })
    tested.assert({ given = "second received value", expected = "world", actual = received[2] })
end)

tested.test("status transitions: suspended → suspended at yield → dead", function()
    local co = coroutine.create(function() coroutine.yield() end)
    tested.assert({ given = "before first resume",  expected = "suspended", actual = coroutine.status(co) })
    coroutine.resume(co)
    tested.assert({ given = "paused at yield",      expected = "suspended", actual = coroutine.status(co) })
    coroutine.resume(co)
    tested.assert({ given = "after completion",     expected = "dead",      actual = coroutine.status(co) })
end)

tested.test("error inside coroutine does not propagate to caller", function()
    local co = coroutine.create(function() error("something went wrong") end)
    local ok, err = coroutine.resume(co)
    tested.assert({ given = "resume ok flag",   expected = false, actual = ok })
    tested.assert_truthy({ given = "error message", actual = err })
    tested.assert({ given = "status after error", expected = "dead", actual = coroutine.status(co) })
end)

tested.test("resuming a dead coroutine returns false", function()
    local co = coroutine.create(function() end)
    coroutine.resume(co)
    local ok, err = coroutine.resume(co)
    tested.assert({ given = "resume ok flag",   expected = false, actual = ok })
    tested.assert_truthy({ given = "cannot resume dead coroutine message", actual = err })
end)

tested.test("coroutine.wrap creates a simple callable generator", function()
    local gen = coroutine.wrap(function()
        coroutine.yield("a")
        coroutine.yield("b")
        coroutine.yield("c")
    end)
    tested.assert({ given = "first call",  expected = "a", actual = gen() })
    tested.assert({ given = "second call", expected = "b", actual = gen() })
    tested.assert({ given = "third call",  expected = "c", actual = gen() })
end)

tested.test("coroutine as a for-iterator produces a sequence", function()
    local function range(n)
        return coroutine.wrap(function()
            for i = 1, n do coroutine.yield(i) end
        end)
    end
    local result = {}
    for v in range(5) do table.insert(result, v) end
    tested.assert({ given = "generated sequence", expected = { 1, 2, 3, 4, 5 }, actual = result })
end)

tested.test("producer-consumer pattern with coroutines", function()
    local produced = {}
    local consumed = {}

    local producer = coroutine.create(function()
        for i = 1, 3 do
            table.insert(produced, i)
            coroutine.yield(i)
        end
    end)

    while coroutine.status(producer) ~= "dead" do
        local ok, val = coroutine.resume(producer)
        if ok and val ~= nil then
            table.insert(consumed, val)
        end
    end

    tested.assert({ given = "produced values", expected = { 1, 2, 3 }, actual = produced })
    tested.assert({ given = "consumed values", expected = { 1, 2, 3 }, actual = consumed })
end)

tested.test("multiple coroutines interleave cooperatively", function()
    local log = {}

    local co1 = coroutine.create(function()
        table.insert(log, "co1-a")
        coroutine.yield()
        table.insert(log, "co1-b")
    end)
    local co2 = coroutine.create(function()
        table.insert(log, "co2-a")
        coroutine.yield()
        table.insert(log, "co2-b")
    end)

    coroutine.resume(co1)
    coroutine.resume(co2)
    coroutine.resume(co1)
    coroutine.resume(co2)

    tested.assert({ given = "interleaved execution log",
        expected = { "co1-a", "co2-a", "co1-b", "co2-b" },
        actual   = log })
end)

return tested
