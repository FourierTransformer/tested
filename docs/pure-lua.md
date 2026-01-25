# Pure-lua mode

We're not quite here yet, but one day I want to be able to just run `lua test_file.lua` and provide (enough of) `tested` as a single file that can just be placed into any project running anywhere. I'm trying to design it that way, but right now, it needs a couple more things:

- A bundler that creates a version of the code without the CLI
    - The CLI is the only thing that requires any c modules, the only other dependencies (luacov and Teal) are designed to be optional.
    - Also, the parallel unit testing would not be needed for running a single file.
    - Likely would only ship some of the output formatters (maybe just `plain`?)
- The ability to set some configuration options within a testfile itself

If this is truly something you would need, [+1 the issue!](https://github.com/FourierTransformer/tested/issues/20)