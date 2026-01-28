


local tadd = {}







tadd.buffer = {}

function tadd.clear()
   for i = 1, #tadd.buffer do
      tadd.buffer[i] = nil
   end
end



function tadd.add(...)
   local table_size = #tadd.buffer
   for i = 1, select("#", ...) do
      tadd.buffer[table_size + i] = select(i, ...)
   end
end

function tadd.new(...)
   tadd.clear()
   tadd.add(...)
end

function tadd.tostring()
   local output = table.concat(tadd.buffer)
   tadd.clear()
   return output
end

return tadd
