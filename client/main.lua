-- ==================================================
-- DjonStNix-Bridge CLIENT INITIALIZATION
-- ==================================================

-- local Core is already initialized in shared/exports.lua as a global

-- Wait for framework module to finish mapping
while not Core.FrameworkReady do Wait(10) end

-- Signal that client-side bridge is ready
Core.Ready = true

-- V2.2: Universal client-side listener for centralized ecosystem broadcasts
RegisterNetEvent('DjonStNix-Bridge:client:internal:Broadcast', function(eventName, payload)
    if not EventBus then return end
    EventBus.Emit(eventName, payload)
end)

print("^4[DjonStNix-Bridge]^7 Client-Side Core Ready. (Ready Flag: " .. tostring(Core.Ready) .. ")")
