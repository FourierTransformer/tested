local record path

    metamethod __call: function(...: string): string

    ansi: function()
    ansi: function(number)
    ansi: function(string): string
    utf8: function()
    utf8: function(string): string
    alt: function(...: string): string
    abs: function(...: string): string
    rel: function(path: string, dir?: boolean): string
    fnmatch: function(string, pattern: string): boolean
    match: function(path: string, pattern: string): boolean
    drive: function(...: string): string
    root: function(...: string): string
    anchor: function(...: string): string
    parent: function(...: string): string
    name: function(...: string): string
    stem: function(...: string): string
    suffix: function(...: string): string
    suffixes: function(...: string): (function(): integer, string)
    parts: function(...: string): (function(): integer, string)
    exists: function(...: string): boolean
    resolve: function(...: string): string
    cwd: function(): string
    bin: function(): string
    isdir: function(...: string): boolean
    islink: function(...: string): boolean
    isfile: function(...: string): boolean
    ismount: function(...: string): boolean

    record fs
        dir: function(...: string): (function(): string, string)
        scandir: function(string, depth?: integer): (function(): string, string) -- can technically be ...: string
        glob: function(string, depth?: integer): (function(): string, string) -- can technically be ...: string
        chdir: function(...: string): string
        mkdir: function(...: string): string
        rmdir: function(...: string): string
        makedirs: function(...: string): string
        remvoedirs: function(...: string): string
        unlockdirs: function(...: string): string
        tmpdir: function(prefix: string): string
        ctime: function(...: string): integer
        mtime: function(...: string): integer
        atime: function(...: string): integer
        size: function(...: string): integer
        touch: function(string, atime?: integer, mtime?: integer): string -- can technically be ...: string
        remove: function(...: string): string
        copy: function(source: string, target: string): boolean
        rename: function(source: string, target: string): boolean
        symlink: function(source: string, target: string, isdir?: boolean): boolean
        exists: function(...: string): boolean
        getcwd: function() : string
        binpath: function() : string
        isdir: function(...: string): boolean
        islink: function(...: string): boolean
        isfile: function(...: string): boolean
        ismount: function(...: string): boolean
    end

    record env
        get: function(key: string): string
        set: function(key: string, value: string): string
        expand: function(...: string): string
        uname: function(): string
    end

    record info
        altsep: string
        curdir: string
        devnull: string
        extsep: string
        pardir: string
        pathsep: string
        platform: string
        sep: string
        version: string
    end

end

return path