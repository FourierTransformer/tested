local colors = require("tested.libs.ansicolors")



local logging = {}

























local LoggerBase = {}
function LoggerBase:set_level(log_level)
   self.current_level = logging.log_levels[log_level]
end

function LoggerBase:debug(message, ...)
   logging._logger_handler("DEBUG", message, self.name, self.current_level, ...)
end

function LoggerBase:info(message, ...)
   logging._logger_handler("INFO", message, self.name, self.current_level, ...)
end

function LoggerBase:warning(message, ...)
   logging._logger_handler("WARNING", message, self.name, self.current_level, ...)
end

function LoggerBase:error(message, ...)
   logging._logger_handler("ERROR", message, self.name, self.current_level, ...)
end

function LoggerBase:critical(message, ...)
   logging._logger_handler("CRITICAL", message, self.name, self.current_level, ...)
end

logging.loggers = {}
logging.current_level = 30
logging.log_levels = {
   ["DEBUG"] = 10,
   ["INFO"] = 20,
   ["WARNING"] = 30,
   ["ERROR"] = 40,
   ["CRITICAL"] = 50,
}
logging.colors = {
   ["DEBUG"] = "dim",
   ["INFO"] = "cyan",
   ["WARNING"] = "yellow",
   ["ERROR"] = "red",
   ["CRITICAL"] = "bright red",
}

function logging.get_logger(name)
   if logging.loggers[name] then
      return logging.loggers[name]
   end

   logging.loggers[name] = setmetatable({}, { __index = LoggerBase })
   logging.loggers[name].name = name

   return logging.loggers[name]
end

function logging.set_level(log_level)
   logging.current_level = logging.log_levels[log_level]
end

function logging._logger_handler(message_level, message, logger_name, logger_log_level, ...)
   if logging.log_levels[message_level] >= (logger_log_level or logging.current_level) then
      logging.handler(message_level, logger_name, string.format(message, ...))
   end
end

function logging.handler(log_level, logger_name, message)
   local current_time = os.date("%Y-%m-%d %H:%M:%S")
   print(colors(string.format("%%{green}%s%%{reset} %%{%s}%s%%{reset} [%s] %s", current_time, logging.colors[log_level], log_level, logger_name, message)))
end

return logging
