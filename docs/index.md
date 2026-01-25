# `tested`

`tested` is a new Lua (and [Teal](https://teal-language.org)!) unit testing framework! It's designed to be simple to use, fast, provide enough information to make results actionable, and one day run everywhere Lua does. It's still early days, but I think it could see some use and am excited to share it!

## Installation
```bash
luarocks install tested
```

## Example Test
=== "Test"
    ```lua title="valid_utf8_test.lua"
    local tested = require("tested")
    local utf8validator = require("utf8validator")

    tested.test("should support ascii", function()
       local start_seq = tonumber("00000000", 2)
       local end_seq = tonumber("01111111", 2)

       for i = start_seq, end_seq do
          tested.assert({
            given="string.char " .. i,
            should="support ascii char",
            expected=true,
            actual=utf8validator(string.char(i))
        })
       end
       
    end)

    tested.test("should support two bytes", function()
       local start_seq = tonumber("11000010", 2)
       local end_seq = tonumber("11011111", 2)

       local start_seq_2nd = tonumber("10000000", 2)
       local end_seq_2nd = tonumber("10111111", 2)
       for i = start_seq, end_seq do
          for j = start_seq_2nd, end_seq_2nd do
             tested.assert_truthy({
                given = "string.char " .. i .. " " .. j,
                should = "support two bytes",
                actual=utf8validator(string.char(i, j))
            })
          end
       end
    end)

    return tested
    ```

=== "Output"


## Inspiration


## Does the Lua ecosystem need _another_ unit testing framework?
This is honestly a question that went through my mind many times while working on `tested`. [busted](https://github.com/lunarmodules/busted) already handles unit testing for many projects. Major thanks to everyone who's helped maintain it over the years, it's no easy feat keeping things going. I've used it for years and it's always worked for what I needed.

`tested` mostly grew out of my desire to _build_ a unit testing framework - with as few external libraries as possible. If it ends up being a library that only I use, that's okay with me. I had a lot of fun making it, and the journey was definitely worth it!

### busted comparison

| Feature | `tested` | busted |
| ------- | -------- | ------ |
| Dependencies | 8 | 12 |
| Time to install | TBD | 31.77 |
| Time to run ftcsv tests | 82ms | 102ms |
| Time to run ftcsv tests w/coverage | 423ms | 1.5s |
| Single-threaded time to run ftcsv tests w/coverage | 600ms | 1.5s |
| Custom Formatters | ✅ | ✅ |
| Extendible to Lua-compat Languages | ✅ | ✅ |
| Mocks | ❌ | ✅ |
| Spies | ❌ | ✅ |
| Ecosystem of extensions | ❌ | ✅ |

- The times/dependencies for busted include installing luacov
- `tested` runs tests multi-threaded, but busted does not