local function GetLogColor(type)
    if type == 'info' then return "^4"
    elseif type == 'action' then return "^2"
    elseif type == 'transaction' then return "^3"
    elseif type == 'security' then return "^1"
    elseif type == 'debug' then return "^5"
    end
    return "^7"
end

function Log(type, message, data)
    if not Config.Logging.Enable then return end
    
    local color = GetLogColor(type)
    local timestamp = os.date("%H:%M:%S")
    local logString = ("%s[%s] [%s] %s %s"):format(color, timestamp, type:upper(), message, "^7")
    
    if Config.Logging.Console then
        print(logString)
        if data and Config.Debug then
            print(json.encode(data, {indent = true}))
        end
    end

    -- Future: Webhook and DB logging
end

-- Assemble Logging API
-- Assemble Logging API
-- Use global Core
Core.Logging.Log = Log
Core.Log = Log -- Shortcut for primary use
