local record util end

-- i generally don't like utils, but so it goes! if we get enough and they're groupable enough i'll
-- create a utils/str.tl or something
function util.get_file_extension(str: string): string
   return str:match("^.+(%..+)$")
end

return util