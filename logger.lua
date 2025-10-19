-- ===========================
-- NOCTIS LOGGER SYSTEM - FIXED
-- ===========================

local Logger = {}
Logger.__index = Logger

-- Log levels
Logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    NONE = 5  -- Disable all logging
}

-- Default configuration
Logger.config = {
    level = Logger.LEVELS.INFO,
    showTimestamp = true,
    showLevel = true,
    prefix = "[Noctis]",
    colors = {
        DEBUG = Color3.fromRGB(86, 156, 214),    -- Light Blue
        INFO = Color3.fromRGB(78, 201, 176),     -- Green
        WARN = Color3.fromRGB(220, 220, 170),    -- Yellow
        ERROR = Color3.fromRGB(242, 119, 122),   -- Red
        RESET = Color3.fromRGB(255, 255, 255)    -- White
    }
}

-- Create new logger instance
function Logger.new(moduleName)
    local self = setmetatable({}, Logger)
    self.moduleName = moduleName or "Main"
    return self
end

-- Format message with timestamp and level
function Logger:formatMessage(level, message)
    local parts = {}
    
    if self.config.showTimestamp then
        table.insert(parts, os.date("[%H:%M:%S]"))
    end
    
    if self.config.prefix then
        table.insert(parts, self.config.prefix)
    end
    
    if self.config.showLevel then
        local levelName = ""
        for name, value in pairs(self.LEVELS) do
            if value == level then
                levelName = name
                break
            end
        end
        table.insert(parts, string.format("[%s]", levelName))
    end
    
    if self.moduleName and self.moduleName ~= "Main" then
        table.insert(parts, string.format("[%s]", self.moduleName))
    end
    
    table.insert(parts, tostring(message))
    
    return table.concat(parts, " ")
end

-- Get color for log level
function Logger:getColor(level)
    if level == self.LEVELS.DEBUG then
        return self.config.colors.DEBUG
    elseif level == self.LEVELS.INFO then
        return self.config.colors.INFO
    elseif level == self.LEVELS.WARN then
        return self.config.colors.WARN
    elseif level == self.LEVELS.ERROR then
        return self.config.colors.ERROR
    else
        return self.config.colors.RESET
    end
end

-- Log debug message
function Logger:debug(message, ...)
    if self.config.level <= self.LEVELS.DEBUG then
        local formatted = self:formatMessage(self.LEVELS.DEBUG, string.format(message, ...))
        print(formatted)
    end
end

-- Log info message
function Logger:info(message, ...)
    if self.config.level <= self.LEVELS.INFO then
        local formatted = self:formatMessage(self.LEVELS.INFO, string.format(message, ...))
        print(formatted)
    end
end

-- Log warning message
function Logger:warn(message, ...)
    if self.config.level <= self.LEVELS.WARN then
        local formatted = self:formatMessage(self.LEVELS.WARN, string.format(message, ...))
        warn(formatted)
    end
end

-- Log error message
function Logger:error(message, ...)
    if self.config.level <= self.LEVELS.ERROR then
        local formatted = self:formatMessage(self.LEVELS.ERROR, string.format(message, ...))
        warn("ERROR: " .. formatted)
    end
end

-- Log success message
function Logger:success(message, ...)
    if self.config.level <= self.LEVELS.INFO then
        local formatted = self:formatMessage(self.LEVELS.INFO, "✅ " .. string.format(message, ...))
        print(formatted)
    end
end

-- Log with custom level
function Logger:log(level, message, ...)
    if self.config.level <= level then
        local formatted = self:formatMessage(level, string.format(message, ...))
        
        if level >= self.LEVELS.WARN then
            warn(formatted)
        else
            print(formatted)
        end
    end
end

-- Set global log level
function Logger.setLevel(level)
    if type(level) == "string" then
        level = string.upper(level)
        if Logger.LEVELS[level] then
            Logger.config.level = Logger.LEVELS[level]
        end
    else
        Logger.config.level = level
    end
end

-- Enable/disable logging completely
function Logger.setEnabled(enabled)
    Logger.config.level = enabled and Logger.LEVELS.INFO or Logger.LEVELS.NONE
end

-- Quick disable all logging for production
function Logger.disableAll()
    Logger.config.level = Logger.LEVELS.NONE
end

-- Quick enable for development
function Logger.enableAll()
    Logger.config.level = Logger.LEVELS.DEBUG
end

-- Get current log level name
function Logger.getCurrentLevel()
    for name, value in pairs(Logger.LEVELS) do
        if value == Logger.config.level then
            return name
        end
    end
    return "UNKNOWN"
end

-- Create table logger for debugging
function Logger:table(data, title)
    if self.config.level <= self.LEVELS.DEBUG then
        title = title or "TABLE DEBUG"
        print(self:formatMessage(self.LEVELS.DEBUG, "=== " .. title .. " ==="))
        
        local function printTable(t, indent)
            indent = indent or 0
            for key, value in pairs(t) do
                if type(value) == "table" then
                    print(string.rep("  ", indent) .. tostring(key) .. ":")
                    printTable(value, indent + 1)
                else
                    print(string.rep("  ", indent) .. tostring(key) .. ": " .. tostring(value))
                end
            end
        end
        
        printTable(data)
        print(self:formatMessage(self.LEVELS.DEBUG, "=== END " .. title .. " ==="))
    end
end

-- Global logger instance
_G.Logger = Logger

return Logger