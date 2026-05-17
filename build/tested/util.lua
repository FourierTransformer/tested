local util = {}



function util.get_file_extension(str)
   return str:match("^.+(%..+)$")
end

function util.is_valid_filename(str)
   return not not str:match("^[%w_/%\\%.%-]+$")
end

function util.is_valid_lua_module_name(str)
   return not not str:match("^[%a_][%w_%.]*$")
end

return util
