local colors = require("tested.libs.ansicolors")

-- very quick 'n dirty logger. Based off of python's, with a lot less features :P

local record Logging
   enum level
      "DEBUG" "INFO" "WARNING" "ERROR" "CRITICAL"
   end

   interface Logger
      current_level: integer
      name: string
      set_level: function(self: Logger, log_level: level)
      debug: function(self: Logger, message: string)
      info: function(self: Logger, message: string)
      warning: function(self: Logger, message: string)
      error: function(self: Logger, message: string)
      critical: function(self: Logger, message: string)
   end

   loggers: {string: Logger}

   current_level: integer
   log_levels: {level: integer}
   colors: {level: string}

   _logger_handler: function(message_level: level, message: string, logger_name: string, logger_log_level?: integer)
   handler: function(log_level: Logging.level, logger_name: string, message: string)
end

local LoggerBase: Logging.Logger = {}
function LoggerBase:set_level(log_level: Logging.level)
   self.current_level = Logging.log_levels[log_level]
end

function LoggerBase:debug(message: string)
   Logging._logger_handler("DEBUG", message, self.name, self.current_level)
end

function LoggerBase:info(message: string)
   Logging._logger_handler("INFO", message, self.name, self.current_level)
end

function LoggerBase:warning(message: string)
   Logging._logger_handler("WARNING", message, self.name, self.current_level)
end

function LoggerBase:error(message: string)
   Logging._logger_handler("ERROR", message, self.name, self.current_level)
end

function LoggerBase:critical(message: string)
   Logging._logger_handler("CRITICAL", message, self.name, self.current_level)
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

function Logging.get_logger(name: string): Logging.Logger
   if Logging.loggers[name] then
      return Logging.loggers[name]
   end

   Logging.loggers[name] = setmetatable({}, {__index=LoggerBase})
   Logging.loggers[name].name = name

   return Logging.loggers[name]
end

function Logging.set_level(log_level: Logging.level)
   Logging.current_level = Logging.log_levels[log_level]
end

function Logging._logger_handler(message_level: Logging.level, message: string, logger_name: string, logger_log_level?: integer)
   if Logging.log_levels[message_level] >= (logger_log_level or Logging.current_level) then
      Logging.handler(message_level, logger_name, message)
   end
end

function Logging.handler(log_level: Logging.level, logger_name: string, message: string)
   local current_time = os.date("%Y-%m-%d %H:%M:%S")
   print(colors(string.format("%%{green}%s%%{reset} %%{%s}%s%%{reset} [%s] %s", current_time, Logging.colors[log_level], log_level, logger_name, message)))
end

return Logging
