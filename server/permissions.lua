function HasPermission(src, permission)
    local framework = GetFramework()
    -- Use global Core
    
    -- Admin Overrides (Basic example)
    if framework == 'qb' then
        return QBCore.Functions.HasPermission(src, permission) or QBCore.Functions.HasPermission(src, 'admin')
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin'
    end
    
    return false
end

function RequirePermission(src, permission)
    if not HasPermission(src, permission) then
        exports['DjonStNix-Bridge']:Notify(src, "Insufficient Permissions", "error")
        return false
    end
    return true
end

-- Assemble Permissions API
-- Use global Core
Core.Player.HasPermission = HasPermission
Core.Security.RequirePermission = RequirePermission
