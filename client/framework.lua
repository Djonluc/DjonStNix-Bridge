local function RegisterFramework()
    -- Ensure global Core is initialized from shared/exports.lua
    while not Core or not Core.Functions do Wait(10) end
    
    local fw = GetFramework()

    if fw == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        
        Core.Player.GetPlayerData = function()
            return QBCore.Functions.GetPlayerData()
        end

        Core.Player.GetJob = function()
            local data = QBCore.Functions.GetPlayerData()
            return data and data.job or nil
        end

        -- --- FUNCTIONS ---
        Core.Functions.TriggerCallback = function(name, cb, ...)
            QBCore.Functions.TriggerCallback(name, cb, ...)
        end

        Core.Functions.CreateCallback = function(name, cb)
            QBCore.Functions.CreateClientCallback(name, cb)
        end
    elseif fw == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()

        Core.Player.GetPlayerData = function()
            return ESX.GetPlayerData()
        end

        Core.Player.GetJob = function()
            local data = ESX.GetPlayerData()
            return data and data.job or nil
        end

        -- --- FUNCTIONS ---
        Core.Functions.TriggerCallback = function(name, cb, ...)
            ESX.TriggerServerCallback(name, cb, ...)
        end
    else
        -- Standalone / Fallback
        Core.Functions.TriggerCallback = function(name, cb, ...)
            -- In standalone, we might use simple events if no callback system exists
            -- But we map it to avoid nil errors
            print("^3[DjonStNix-Bridge] Warning: TriggerCallback called in standalone mode.^7")
            cb(nil)
        end
    end
    
    Core.FrameworkReady = true
end

CreateThread(function()
    RegisterFramework()
end)
