local record util end

-- i generally don't like utils, but so it goes! if we get enough and they're groupable enough i'll
-- create a utils/str.tl or something
function util.get_file_extension(str: string): string
   return str:match("^.+(%..+)$")
end

function util.is_valid_filename(str: string): boolean
   return not not str:match("^[%w_/%\\%.%-]+$")
end

function util.is_valid_lua_module_name(str: string): boolean
   return not not str:match("^[%a_][%w_%.]*$")
end

return util