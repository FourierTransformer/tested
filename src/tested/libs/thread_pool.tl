local lanes = require("lanes").configure()
local logging = require("tested.libs.logging")
local type luacov_type = require("luacov.runner")

local logger = logging.get_logger("tested.libs.thread_pool")

-- very basic threadpool. I really wish I could've made this more generic, but time and limitations are real.
local record ThreadPool
   interface Result<T>
      error: string
      result: T
      order: integer
      code_coverage: table
   end

   init: function(workers: integer, run_coverage: boolean): ThreadPool
   map: function<T>(self: ThreadPool, func: function(...: any): T, args_list: {{any}}, display_func: function(T), timeout?: number): {Result<T>}
   shutdown: function(self: ThreadPool, timeout?: number)
   workers: {lanes.Lane}
   linda: lanes.Linda
end

-- since these are used internally (and in worker, maybe don't put them in the threadpool?)
local _task_queue = "tasks"
local _result_queue = "results"

-- for lua 5.1 and luajit?
global unpack: function
local _unpack = unpack or table.unpack

local record Task
   order: integer
   func: function
   args: table
end

-- waits for a task, then executes it
local function worker(num: integer, run_coverage: boolean, linda: lanes.Linda)
   logger:info("Starting worker " .. num)
   
   local luacov: luacov_type

   if run_coverage then
      -- I _really_ don't like instantiating luacov way out here.
      -- I tried to do some init/shutdown stuff in test_runner.tl,
      -- but ran into a bunch of issues wrt either lanes hanging or
      -- not having the statsfile get saved off correctly
      local luacov_runner = require("luacov.runner")
      luacov_runner.init({statsfile= num .. ".cov.out", exclude={"luarocks%/.+$", "tested%/.+$", "tested$"}})
      luacov_runner.pause()
      luacov = luacov_runner
   end
   
   while true do
      logger:debug("Worker " .. num .. " waiting for task")
      -- Get a task from the queue should be a blocking call
      local _queue, task_data = linda:receive(_task_queue) as (string, Task)
      logger:debug("Worker " .. num .. " Got task " .. task_data.order)

      -- Execute the task
      if run_coverage then luacov.resume() end
      local success, result = pcall(task_data.func, _unpack(task_data.args))
      if run_coverage then luacov.pause() end

      local coverage_data = {}
      if run_coverage then 
         coverage_data = luacov.data 
         luacov.data = {} 
      end

      if success then
         logger:debug(
            "Worker " .. num .. " finished task " .. task_data.order .. 
            ": " .. tostring(success) .. " " .. tostring(result)
         )
         linda:send(_result_queue, {result=result, code_coverage=coverage_data, order=task_data.order})
      else
         linda:send(_result_queue, {error = result, code_coverage=coverage_data, order=task_data.order})
      end
   end
end

function ThreadPool.init(workers: integer, run_coverage: boolean): ThreadPool
   local instance = setmetatable({}, {__index=ThreadPool}) as ThreadPool
   instance.linda = lanes.linda()
   instance.workers = {}

   for i = 1, workers do
      -- Create worker lanes with separate state
      local worker_lane = lanes.gen("*", worker)
      instance.workers[i] = worker_lane(i, run_coverage, instance.linda)
   end
   return instance
end

function ThreadPool:map<T>(
   func: function(...: any): T, 
   args_list: {{any}}, 
   display_func: function(T), 
   _timeout?: number
): {ThreadPool.Result<T>}

   local total_calls = #args_list
   logger:info("Sending " .. total_calls .. " tasks")
   for i = 1, total_calls do
      local task_data = {
         order = i, 
         func = func,
         args = args_list[i]
      }

      -- Send task to queue
      self.linda:send(_task_queue, task_data)
   end

   logger:info("Waiting for results...")

   local i = 1
   local output = {}
   while true do
      i = i + 1
      local _queue, results: string, ThreadPool.Result<T> = self.linda:receive(_result_queue) as (string, ThreadPool.Result<T>)
      if results.error then error(results.error) end
      output[results.order] = results
      display_func(results.result)
      if i > #args_list then
         return output
      end
   end
   
end

function ThreadPool:shutdown(timeout?: number)
   for i = 1, #self.workers do
      self.workers[i]:cancel("soft", timeout)
   end
end

return ThreadPool
