Core = {}
EventBus = {}

-- ==================================================
-- INTERNAL EVENT BUS
-- ==================================================

function EventBus.Emit(eventName, payload)
    TriggerEvent('DjonStNix-Bridge:internal:' .. eventName, payload)
end

function EventBus.On(eventName, handler)
    AddEventHandler('DjonStNix-Bridge:internal:' .. eventName, function(payload)
        handler(payload)
    end)
end

-- ==================================================
-- MASTER CORE API OBJECT
-- ==================================================

function InitializeCore()
    -- These will be populated by server/framework files
    Core.Player = {}
    Core.Money = {}
    Core.Items = {}
    Core.Vehicle = {}
    Core.Society = {}
    Core.Security = {}
    Core.Logging = {}
    Core.Registry = {}
    Core.UI = {}
    Core.Functions = {}
    Core.Ready = false
    
    -- Shared Utilities (Late-mapped to ensure they exist)
    Core.IsResourceRunning = function(...) return IsResourceRunning(...) end
    Core.GetIntegrationStatus = function(...) return GetIntegrationStatus(...) end
    Core.Emit = EventBus.Emit
    Core.On = EventBus.On
    
    return Core
end

exports('GetCore', function()
    while not Core.Ready do Wait(100) end
    return Core
end)

exports('Emit', function(eventName, payload)
    EventBus.Emit(eventName, payload)
end)

exports('On', function(eventName, handler)
    EventBus.On(eventName, handler)
end)

-- Initialize Core immediately
InitializeCore()
