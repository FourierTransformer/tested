local lanes = require("lanes").configure({demote_full_userdata=true})

-- very basic threadpool.
local record ThreadPool
    init: function(workers: integer): ThreadPool
    map: function<T>(self: ThreadPool, func: function(...: any): T, args_list: {{any}}, timeout?: number): {T}
    shutdown: function(self: ThreadPool, timeout?: number)
    workers: {lanes.Lane}
    linda: lanes.Linda
end

-- since these are used internally (and in worker, maybe don't put them in the threadpool?)
local _default_workers = 4
local _task_queue = "tasks"
local _result_queue = "results"


local record Task
    order: integer
    func: function
    args: table
end

local record Result
    error: string
    result: any
    order: integer
end

-- waits for a task, then executes it
local function worker(num: integer, linda: lanes.Linda)
    -- print("Starting worker " .. num)
    while true do
        -- print("worker " .. num .. " waiting for task")
        -- Get a task from the queue should blocking call
        local _queue, task_data = linda:receive(_task_queue) as (string, Task)
        -- print("Got task!")

        -- Execute the task
        local success, result = pcall(task_data.func, table.unpack(task_data.args))
        print("Task complete!", success, result)

        if success then
            linda:send(_result_queue, {result=result, order=task_data.order})
        else
            print("error", error)
            linda:send(_result_queue, {error = result, order=task_data.order})
        end
    end
end

function ThreadPool.init(workers?: integer): ThreadPool
    local self = setmetatable(ThreadPool, {})
    self.linda = lanes.linda()
    local threads = workers or _default_workers
    self.workers = {}

    for i = 1, threads do
        -- Create worker lanes with separate state
        local worker_lane = lanes.gen("*", worker)
        -- print("Creating worker " .. i)
        self.workers[i] = worker_lane(i, self.linda)
    end
    return self
end

function ThreadPool:map<T>(func: function(...: any): T, args_list: {{any}}, _timeout?: number): {T}
    local total_calls = #args_list
    -- print("Sending " .. total_calls .. " tasks")
    for i = 1, total_calls do
        local task_data = {
            order = i, 
            func = func,
            args = args_list[i]
        }

        print(task_data.args[1])

        -- Send task to queue
        self.linda:send(_task_queue, task_data)
    end

    print("Waiting for results...")

    local i = 1
    local output = {}
    while true do
        i = i + 1
        local _queue, results = self.linda:receive(_result_queue) as (string, Result)
        output[results.order] = results.result
        -- print("result", results.order, results.result)
        if i > #args_list then
            return output as {T}
        end
    end
    
end

function ThreadPool:shutdown(timeout?: number)
    for i = 1, #self.workers do
        self.workers[i]:cancel("hard", timeout)
    end
end

return ThreadPool
