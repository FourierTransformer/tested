local lanes = require("lanes").configure({ demote_full_userdata = true })


local ThreadPool = {}








local _default_workers = 4
local _task_queue = "tasks"
local _result_queue = "results"















local function worker(num, linda)

   while true do


      local _queue, task_data = linda:receive(_task_queue)



      local success, result = pcall(task_data.func, table.unpack(task_data.args))
      print("Task complete!", success, result)

      if success then
         linda:send(_result_queue, { result = result, order = task_data.order })
      else
         print("error", error)
         linda:send(_result_queue, { error = result, order = task_data.order })
      end
   end
end

function ThreadPool.init(workers)
   local self = setmetatable(ThreadPool, {})
   self.linda = lanes.linda()
   local threads = workers or _default_workers
   self.workers = {}

   for i = 1, threads do

      local worker_lane = lanes.gen("*", worker)

      self.workers[i] = worker_lane(i, self.linda)
   end
   return self
end

function ThreadPool:map(func, args_list, _timeout)
   local total_calls = #args_list

   for i = 1, total_calls do
      local task_data = {
         order = i,
         func = func,
         args = args_list[i],
      }

      print(task_data.args[1])


      self.linda:send(_task_queue, task_data)
   end

   print("Waiting for results...")

   local i = 1
   local output = {}
   while true do
      i = i + 1
      local _queue, results = self.linda:receive(_result_queue)
      output[results.order] = results.result

      if i > #args_list then
         return output
      end
   end

end

function ThreadPool:shutdown(timeout)
   for i = 1, #self.workers do
      self.workers[i]:cancel("hard", timeout)
   end
end

return ThreadPool
