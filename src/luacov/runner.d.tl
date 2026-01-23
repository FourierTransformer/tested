local interface LuacovConfig
    include: {string}
    exclude: {string}
    modules: {string:string}

    statsfile: string -- "luacov.stats.out"
    reportfile: string -- "luacov.report.out"
    tick: boolean -- false
    savestepsize: integer -- 100
    runreport: boolean -- false
    deletestats: boolean -- false
    codefromstrings: boolean -- false
    includeuntestedfiles: boolean --false
end

local record runner
    init: function(configuration?: LuacovConfig)
    shutdown: function()
    pause: function()
    resume: function()
    save_stats: function()
    data: table
end


return runner