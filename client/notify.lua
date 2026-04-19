-- Client implementation
local function Notify(message, type)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = 'System',
            description = message,
            type = type or 'info'
        })
        return
    end

    local framework = GetFramework()
    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions and QBCore.Functions.Notify then
            QBCore.Functions.Notify(message, type or 'primary')
        else
            TriggerEvent('QBCore:Notify', message, type or 'primary')
        end
    elseif framework == 'esx' then
        local ESX = GetFrameworkObject and GetFrameworkObject() or exports['es_extended']:getSharedObject()
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(message)
        else
            TriggerEvent('esx:showNotification', message)
        end
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
