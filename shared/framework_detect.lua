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
        FrameworkObject = exports['es_extended']:getSharedObject()
    end

    return FrameworkObject
end

-- Export for scripts that need direct framework access (rare)
exports('GetFramework', function()
    return GetFramework()
end)
