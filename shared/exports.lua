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
    Core.Plugins = {}
    Core.Utils = {}
    Core.UI = {
        Notify = function(src, msg, type) 
            if src == -1 then
                TriggerClientEvent('DjonStNix-Bridge:client:Notify', -1, msg, type)
            else
                TriggerClientEvent('DjonStNix-Bridge:client:Notify', src, msg, type)
            end
        end,
        Broadcast = function(msg, type)
            TriggerClientEvent('DjonStNix-Bridge:client:Notify', -1, msg, type)
        end
    }
    Core.Functions = {}
    Core.Ready = false
    
    -- Shared Utilities (Late-mapped to ensure they exist)
    Core.IsResourceRunning = function(...) return IsResourceRunning(...) end
    Core.GetIntegrationStatus = function(...) return GetIntegrationStatus(...) end
    Core.Emit = EventBus.Emit
    Core.On = EventBus.On

    -- SDK Extensions
    Core.Utils.PrintBanner = function(resource, version)
        print("^5================================================^0")
        print("^3  👑 DJONSTNIX ECOSYSTEM^0")
        print("^5================================================^0")
        print("^2  Resource : ^7" .. (resource or GetCurrentResourceName()))
        print("^2  Version  : ^7" .. (version or "1.0.0"))
        print("^2  Author   : ^7DjonLuc (@DjonStNix)")
        print("^5================================================^0")
    end

    Core.Plugins.Register = function(name, pluginTable)
        if not name or not pluginTable then return false end
        Core.Registry.Plugins = Core.Registry.Plugins or {}
        Core.Registry.Plugins[name] = pluginTable
        print(("^2[DjonStNix-Bridge]^7 Plugin Registered: ^3%s^7 (v%s)"):format(name, pluginTable.version or "1.0"))
        
        -- Emit generic registration event
        Core.Emit('bridge:plugin:registered', { name = name, version = pluginTable.version })
        return true
    end
    
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

--- Global broadcast which triggers both server-side and client-side (to all)
exports('BroadcastEvent', function(eventName, payload)
    EventBus.Emit(eventName, payload)
    TriggerClientEvent('DjonStNix-Bridge:client:internal:Broadcast', -1, eventName, payload)
end)

-- Initialize Core immediately
InitializeCore()
