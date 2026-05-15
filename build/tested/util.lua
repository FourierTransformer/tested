local util = {}



function util.get_file_extension(str)
   return str:match("^.+(%..+)$")
end

return util
