EventBus = {}
local Handlers = {}

function EventBus.Emit(eventName, payload)
    if Config.Debug then
        print(("^4[DjonStNix-Bridge EventBus]^7 Emitting: %s"):format(eventName))
    end
    TriggerEvent('DjonStNix-Bridge:internal:' .. eventName, payload)
end

function EventBus.On(eventName, handler)
    AddEventHandler('DjonStNix-Bridge:internal:' .. eventName, function(payload)
        handler(payload)
    end)
end

-- Global Event Bus for cross-resource communication without TriggerEvent boilerplate
exports('Emit', function(eventName, payload)
    EventBus.Emit(eventName, payload)
end)

exports('On', function(eventName, handler)
    EventBus.On(eventName, handler)
end)
