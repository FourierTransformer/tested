local colors = require("tested.libs.ansicolors")



local Logging = {}

























local LoggerBase = {}
function LoggerBase:set_level(log_level)
   self.current_level = Logging.log_levels[log_level]
end

function LoggerBase:debug(message, ...)
   Logging._logger_handler("DEBUG", message, self.name, self.current_level, ...)
end

function LoggerBase:info(message, ...)
   Logging._logger_handler("INFO", message, self.name, self.current_level, ...)
end

function LoggerBase:warning(message, ...)
   Logging._logger_handler("WARNING", message, self.name, self.current_level, ...)
end

function LoggerBase:error(message, ...)
   Logging._logger_handler("ERROR", message, self.name, self.current_level, ...)
end

function LoggerBase:critical(message, ...)
   Logging._logger_handler("CRITICAL", message, self.name, self.current_level, ...)
end

Logging.loggers = {}
Logging.current_level = 30
Logging.log_levels = {
   ["DEBUG"] = 10,
   ["INFO"] = 20,
   ["WARNING"] = 30,
   ["ERROR"] = 40,
   ["CRITICAL"] = 50,
}
Logging.colors = {
   ["DEBUG"] = "dim",
   ["INFO"] = "cyan",
   ["WARNING"] = "yellow",
   ["ERROR"] = "red",
   ["CRITICAL"] = "bright red",
}

function Logging.get_logger(name)
   if Logging.loggers[name] then
      return Logging.loggers[name]
   end

   Logging.loggers[name] = setmetatable({}, { __index = LoggerBase })
   Logging.loggers[name].name = name

   return Logging.loggers[name]
end

function Logging.set_level(log_level)
   Logging.current_level = Logging.log_levels[log_level]
end

function Logging._logger_handler(message_level, message, logger_name, logger_log_level, ...)
   if Logging.log_levels[message_level] >= (logger_log_level or Logging.current_level) then
      Logging.handler(message_level, logger_name, string.format(message, ...))
   end
end

function Logging.handler(log_level, logger_name, message)
   local current_time = os.date("%Y-%m-%d %H:%M:%S")
   print(colors(string.format("%%{green}%s%%{reset} %%{%s}%s%%{reset} [%s] %s", current_time, Logging.colors[log_level], log_level, logger_name, message)))
end

return Logging
