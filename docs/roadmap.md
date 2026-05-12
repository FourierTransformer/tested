# Roadmap

I'm planning to start off by seeing if `tested` catches on, and see what features/criticism/feedback people give and likely go from there. I'm planning to wait a bit (could be a year) before fully committing to a v1 and stabilizing the CLI and API.

Things that I am one day planning to add (in no particular order):

- [ ] Test options [#35](https://github.com/FourierTransformer/tested/issues/35)
    - [x] Expected Statuses
    - [x] `run_when` for conditional running tests
    - [ ] `retries` and (maybe) `retry_timeout` for automatically retrying failing tests
    - [ ] tags for filtering
- [x] Lifecycle management (`before`, `after`, `before_each`, `after_each`)
- [ ] Table driven assertion (no more for loops around asserts!)
- [ ] Stubbing
- [ ] Mocking
- [ ] A [pure Lua](./pure-lua.md) single-file (maybe two files) distribution [#20](https://github.com/FourierTransformer/tested/issues/20)
    - Should allow for embedding (on devices, maybe with Neovim and Love2d? )
- [ ] File output (alongside terminal)
    - A cool fancy HTML output with the tests and coverage could be fun [#14](https://github.com/FourierTransformer/tested/issues/14)
    - Likely JSON as well
- [ ] Test timeouts [#3](https://github.com/FourierTransformer/tested/issues/3)

If there are any things you would really want to see added to a Unit testing framework, feel free to [open up a discussion](https://github.com/FourierTransformer/tested/discussions/new/choose). I'm currently open to new ideas!