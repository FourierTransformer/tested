local lanes = require("lanes").configure()
local logging = require("tested.libs.logging")

local logger = logging.get_logger("tested.libs.thread_pool")


local ThreadPool = {}















local _task_queue = "tasks"
local _result_queue = "results"









local function worker(num, linda)
   logger:info("Starting worker " .. num)
   local luacov_runner = require("luacov.runner")





   luacov_runner.init({ statsfile = num .. ".cov.out", tick = true, exclude = { "luarocks%/.+$", "tested%/.+$", "tested$" } })
   luacov_runner.pause()

   while true do
      logger:debug("Worker " .. num .. " waiting for task")

      local _queue, task_data = linda:receive(_task_queue)
      logger:debug("Worker " .. num .. " Got task " .. task_data.order)


      luacov_runner.resume()
      local success, result = pcall(task_data.func, table.unpack(task_data.args))
      luacov_runner.pause()

      local coverage_data = luacov_runner.data
      luacov_runner.data = {}

      logger:debug(
      "Worker " .. num .. " finished task " .. task_data.order ..
      ": " .. tostring(success) .. " " .. tostring(result))


      if success then
         linda:send(_result_queue, { result = result, code_coverage = coverage_data, order = task_data.order })
      else
         print("error", error)
         linda:send(_result_queue, { error = result, code_coverage = coverage_data, order = task_data.order })
      end
   end
end

function ThreadPool.init(workers)
   local instance = setmetatable({}, { __index = ThreadPool })
   instance.linda = lanes.linda()
   instance.workers = {}

   for i = 1, workers do

      local worker_lane = lanes.gen("*", worker)
      instance.workers[i] = worker_lane(i, instance.linda)
   end
   return instance
end

function ThreadPool:map(func, args_list, _timeout)
   local total_calls = #args_list
   logger:info("Sending " .. total_calls .. " tasks")
   for i = 1, total_calls do
      local task_data = {
         order = i,
         func = func,
         args = args_list[i],
      }


      self.linda:send(_task_queue, task_data)
   end

   logger:info("Waiting for results...")

   local i = 1
   local output = {}
   while true do
      i = i + 1
      local _queue, results = self.linda:receive(_result_queue)
      output[results.order] = results
      if i > #args_list then
         return output
      end
   end

end

function ThreadPool:shutdown(timeout)
   for i = 1, #self.workers do
      self.workers[i]:cancel("soft", timeout)
   end
end

return ThreadPool
