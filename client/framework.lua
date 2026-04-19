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
        -- Use the hardened GetFrameworkObject which handles retries and fallbacks
        local ESX = GetFrameworkObject()

        -- Safety: if ESX object is still nil, wait for it
        if not ESX then
            print("^3[DjonStNix-Bridge] Waiting for ESX shared object on client...^7")
            local retries = 0
            while not ESX and retries < 100 do
                Wait(100)
                retries = retries + 1
                ESX = GetFrameworkObject()
            end
        end

        if not ESX then
            print("^1[DjonStNix-Bridge] CRITICAL: ESX shared object unavailable on client after 10s! Shop interactions will fail.^7")
            -- Map stubs to prevent nil errors, but functionality will be broken
            Core.Player.GetPlayerData = function() return nil end
            Core.Player.GetJob = function() return nil end
            Core.Functions.TriggerCallback = function(name, cb, ...) 
                print("^1[DjonStNix-Bridge] ERROR: TriggerCallback called but ESX is not available!^7")
                cb(nil)
            end
        else
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

-- --- ITEMS (Client Side) ---
Core.Items.HasItem = function(itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', itemName)
        return type(count) == 'number' and count > 0
    elseif GetFramework() == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local has = false
        QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result) has = result end, itemName)
        Wait(500)
        return has
    elseif GetFramework() == 'esx' then
        -- Client-side ESX doesn't have a synchronous HasItem, typically checked server-side.
        -- We return true here as a fallback, or we'd need an async callback built-in.
        return true
    end
    return true
end

CreateThread(function()
    RegisterFramework()
end)
