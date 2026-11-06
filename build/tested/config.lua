local logging = require("tested.libs.logging")
local types = require("tested.types")

local logger = logging.get_logger("tested.config")

local CONFIG_FILE = "tested.config.lua"

local config = {}







function config.load_config()
   local env = {}
   local chunk
   local err



   if type(jit) ~= "table" and _VERSION == "Lua 5.1" then
      logger:info("Loading config from Lua 5.1")

      chunk, err = loadfile(CONFIG_FILE)
      if chunk then setfenv(chunk, env) end
   else
      logger:info("Loading config...")
      chunk, err = loadfile("tested.config.lua", "t", env)
   end

   if not chunk then
      if not io.open(CONFIG_FILE, "r") then
         logger:info("Unable to load tested.config.lua, likely cannot be accessed: " .. err)
         return {}
      else
         error("Unable to load tested.config.lua: " .. err, 0)
      end
   end
   chunk()
   return env
end

return config
