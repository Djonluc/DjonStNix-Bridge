function HasPermission(src, permission)
    local framework = GetFramework()
    -- Use global Core
    local permissions = type(permission) == 'table' and permission or { permission }

    local function hasAnyPermission(checkFn)
        for _, entry in ipairs(permissions) do
            if entry and checkFn(entry) then
                return true
            end
        end
        return false
    end
    
    -- Admin Overrides (Basic example)
    if framework == 'qb' then
        return hasAnyPermission(function(entry)
            return QBCore.Functions.HasPermission(src, entry)
        end) or QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        local group = xPlayer.getGroup()
        return group == 'admin' or group == 'superadmin'
    end
    
    return false
end

function RequirePermission(src, permission)
    if not HasPermission(src, permission) then
        Core.UI.Notify(src, "Insufficient Permissions", "error")
        return false
    end
    return true
end

-- Assemble Permissions API
-- Use global Core
Core.Player.HasPermission = HasPermission
Core.Security.RequirePermission = RequirePermission
