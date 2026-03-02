-- Client implementation
local function Notify(message, type)
    local framework = GetFramework()
    if framework == 'qb' then
        exports['qb-core']:Notify(message, type)
    elseif framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        ESX.ShowNotification(message)
    else
        -- Fallback
        SetNotificationTextEntry("STRING")
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

RegisterNetEvent('DjonStNix-Bridge:client:Notify', function(message, type)
    Notify(message, type)
end)

Core.Notify = function(src, msg, type) Notify(msg, type) end
