local colors = require("tested.libs.ansicolors")

-- very quick 'n dirty logger. Based off of python's, with a lot less features :P

local record logging
   enum level
      "DEBUG" "INFO" "WARNING" "ERROR" "CRITICAL"
   end

   interface Logger
      current_level: integer
      name: string
      set_level: function(self: Logger, log_level: level)
      debug: function(self: Logger, message: string, ...: any)
      info: function(self: Logger, message: string, ...: any)
      warning: function(self: Logger, message: string, ...: any)
      error: function(self: Logger, message: string, ...: any)
      critical: function(self: Logger, message: string, ...: any)
   end

   loggers: {string: Logger}

   current_level: integer
   log_levels: {level: integer}
   colors: {level: string}

   _logger_handler: function(message_level: level, message: string, logger_name: string, logger_log_level?: integer, ...: any)
   handler: function(log_level: logging.level, logger_name: string, message: string)
end

local LoggerBase: logging.Logger = {}
function LoggerBase:set_level(log_level: logging.level)
   self.current_level = logging.log_levels[log_level]
end

function LoggerBase:debug(message: string, ...: any)
   logging._logger_handler("DEBUG", message, self.name, self.current_level, ...)
end

function LoggerBase:info(message: string, ...: any)
   logging._logger_handler("INFO", message, self.name, self.current_level, ...)
end

function LoggerBase:warning(message: string, ...: any)
   logging._logger_handler("WARNING", message, self.name, self.current_level, ...)
end

function LoggerBase:error(message: string, ...: any)
   logging._logger_handler("ERROR", message, self.name, self.current_level, ...)
end

function LoggerBase:critical(message: string, ...: any)
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

function logging.get_logger(name: string): logging.Logger
   if logging.loggers[name] then
      return logging.loggers[name]
   end

   logging.loggers[name] = setmetatable({}, {__index=LoggerBase})
   logging.loggers[name].name = name

   return logging.loggers[name]
end

function logging.set_level(log_level: logging.level)
   logging.current_level = logging.log_levels[log_level]
end

function logging._logger_handler(message_level: logging.level, message: string, logger_name: string, logger_log_level?: integer, ...: any)
   if logging.log_levels[message_level] >= (logger_log_level or logging.current_level) then
      logging.handler(message_level, logger_name, string.format(message, ...))
   end
end

function logging.handler(log_level: logging.level, logger_name: string, message: string)
   local current_time = os.date("%Y-%m-%d %H:%M:%S")
   print(colors(string.format("%%{green}%s%%{reset} %%{%s}%s%%{reset} [%s] %s", current_time, logging.colors[log_level], log_level, logger_name, message)))
end

return logging
