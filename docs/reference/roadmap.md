# Roadmap

I'm planning to start off by seeing if `tested` catches on, and see what features/criticism/feedback people give and likely go from there. I'm planning to wait a bit (could be a year) before fully committing to a v1 and stabilizing the CLI and API.

## Planned Features (in no particular order)

- [x] Test options [#35](https://github.com/FourierTransformer/tested/issues/35)
    - [x] Expected Statuses
    - [x] `run_when` for conditional running tests
    - [x] `retries` and `retry_timeout` for automatically retrying failing tests
    - [x] tags for filtering
- [x] Lifecycle management (`before`, `after`, `before_each`, `after_each`)
- [ ] Spies
- [ ] Stubbing
- [ ] Mocking
- [x] A pure Lua distribution [#20](https://github.com/FourierTransformer/tested/issues/20)
    - Should allow for using `tested` embedding (on devices, maybe with Neovim and Love2d? )
- [x] File output (alongside terminal)
    - A cool fancy HTML output with the tests and coverage could be fun [#14](https://github.com/FourierTransformer/tested/issues/14)
    - [x] Likely JSON as well
- [ ] Test profiles

## Features requiring additional effort
These will most likely be implemented in the `tested` CLI only as they will require C modules.

- [ ] Parallel test using _subprocesses_
- [ ] Test timeouts [#3](https://github.com/FourierTransformer/tested/issues/3)
- [ ] Test watcher mode

If there are any things you would really want to see added to a Unit testing framework, feel free to [open up a discussion](https://github.com/FourierTransformer/tested/discussions/new/choose). I'm currently open to new ideas!