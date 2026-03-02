local Integrations = {}

local function CheckIntegration(resource)
    local state = GetResourceState(resource)
    Integrations[resource] = (state == 'started' or state == 'starting')
    return Integrations[resource]
end

function RefreshIntegrations()
    CheckIntegration('DjonStNix-Banking')
    CheckIntegration('DjonStNix-Shops')
    CheckIntegration('DjonStNix-Government')
    CheckIntegration('ps-dispatch')
    CheckIntegration('ox_inventory')
    CheckIntegration('qb-inventory')
    CheckIntegration('qs-inventory')
    CheckIntegration('ox_target')
    CheckIntegration('qb-target')
end

function IsResourceRunning(resource)
    if Integrations[resource] == nil then
        return CheckIntegration(resource)
    end
    return Integrations[resource]
end

function GetIntegrationStatus()
    RefreshIntegrations()
    return Integrations
end

-- Refresh periodically or on demand
CreateThread(function()
    while true do
        RefreshIntegrations()
        Wait(5000) -- Refresh every 5 seconds to catch newly started resources
    end
end)

exports('IsResourceRunning', IsResourceRunning)
exports('GetIntegrationStatus', GetIntegrationStatus)
