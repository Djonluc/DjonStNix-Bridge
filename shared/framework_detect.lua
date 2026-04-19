local Framework = nil
local FrameworkObject = nil

local function DetectFramework()
    if Config.Framework ~= "auto" then
        Framework = Config.Framework
        return Framework
    end

    if GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
    elseif GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
    else
        Framework = 'standalone'
    end

    return Framework
end

function GetFramework()
    if not Framework then
        DetectFramework()
    end
    return Framework
end

function GetFrameworkObject()
    if FrameworkObject then return FrameworkObject end

    local fw = GetFramework()
    if fw == 'qb' then
        FrameworkObject = exports['qb-core']:GetCoreObject()
    elseif fw == 'qbox' then
        FrameworkObject = exports.qbx_core:GetCoreObject()
    elseif fw == 'esx' then
        -- Try modern export first
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and obj then
            FrameworkObject = obj
        else
            -- Fallback: classic event-based retrieval (older ESX versions)
            local fallbackObj = nil
            TriggerEvent('esx:getSharedObject', function(esxObj)
                fallbackObj = esxObj
            end)
            if fallbackObj then
                FrameworkObject = fallbackObj
            end
        end

        -- Safety: retry up to 5 seconds if ESX is starting but not ready yet
        if not FrameworkObject and GetResourceState('es_extended') == 'started' then
            local retries = 0
            while not FrameworkObject and retries < 50 do
                Wait(100)
                retries = retries + 1
                local retryOk, retryObj = pcall(function()
                    return exports['es_extended']:getSharedObject()
                end)
                if retryOk and retryObj then
                    FrameworkObject = retryObj
                end
            end
        end

        if not FrameworkObject then
            print("^1[DjonStNix-Bridge] CRITICAL: Failed to retrieve ESX shared object after all attempts!^7")
        end
    end

    return FrameworkObject
end

-- Export for scripts that need direct framework access (rare)
exports('GetFramework', function()
    return GetFramework()
end)

exports('GetFrameworkObject', function()
    return GetFrameworkObject()
end)

-- QBCore-style compatibility alias so downstream resources can ask Bridge
-- for the same core object shape they would normally get from qb-core.
exports('GetCoreObject', function()
    return GetFrameworkObject()
end)
