local tested = require("tested")

local t = tested.new()

-- Natural completion with no assertions: expect UNKNOWN
t:test("natural completion - no assertions", {expected="UNKNOWN"}, function()
    local x = 1 + 1
end)

-- error() unhandled: pcall in tested catches it → EXCEPTION
t:test("unhandled error() call", {expected="EXCEPTION"}, function()
    error("something went wrong")
end)

-- Lua assert() with nil: same as error() under the hood → EXCEPTION
t:test("assert() with nil condition", {expected="EXCEPTION"}, function()
    local file = io.open("/nonexistent/path/file.txt", "r")
    assert(file, "could not open file")
end)

-- Indexing nil: runtime error, pcall catches it → EXCEPTION
t:test("nil indexing runtime crash", {expected="EXCEPTION"}, function()
    local a = nil
    print(a.value)
end)

-- load() returns nil + message for bad syntax; calling nil is itself a runtime error → EXCEPTION
t:test("calling result of load() with syntax error", {expected="EXCEPTION"}, function()
    local chunk = load("if true print('hello') end")
    chunk()
end)

-- error() with a table value: pcall catches it but the error object is not a string
t:test("error() with non-string table object", {expected="EXCEPTION"}, function()
    error({ code = 42, msg = "structured error" })
end)

-- os.exit() is now intercepted and raised as an error so tested can report it.
t:test("os.exit(0) terminates the host process", {expected="EXCEPTION"}, function()
    os.exit(0)
end)

-- os.exit() is now intercepted and raised as an error so tested can report it.
t:test("os.exit() terminates the host process", {expected="EXCEPTION"}, function()
    os.exit()
end)

return t
