-- a sort've high performance string builder interface
-- intentionally not a class to even reduce table creation counts (which may going a little far...)

local record tadd
   buffer: {string}
   clear: function()
   add: function(...: string)
   new: function(...: string)
   tostring: function(): string
end

tadd.buffer = {}

function tadd.clear()
   for i=1, #tadd.buffer do
      tadd.buffer[i] = nil
   end
end

-- so the vararg stuff feels a little weird to me, but i kinda like the interface usage!
-- also for the vararg style, this method benchmarked the fastest
function tadd.add(...: string)
   local table_size = #tadd.buffer
   for i = 1, select("#", ...) do
      tadd.buffer[table_size + i] = select(i, ...)
   end
end

function tadd.new(...: string)
   tadd.clear()
   tadd.add(...)
end

function tadd.tostring(): string
   local output = table.concat(tadd.buffer)
   tadd.clear()
   return output
end

return tadd