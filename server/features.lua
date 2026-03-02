-- ==================================================
-- DjonStNix-Bridge FEATURE GATES
-- Auto-populated capability table for graceful degradation.
-- ==================================================

Core.Features = {}

function RefreshFeatures()
    local fw = GetFramework()

    Core.Features = {
        -- Framework
        framework       = fw,
        isQB            = (fw == 'qb'),
        isQBox          = (fw == 'qbox'),
        isESX           = (fw == 'esx'),
        isStandalone    = (fw == 'standalone'),

        -- Inventory
        hasOxInventory  = GetResourceState('ox_inventory') == 'started',
        hasQBInventory  = GetResourceState('qb-inventory') == 'started',
        hasQSInventory  = GetResourceState('qs-inventory') == 'started',
        hasInventory    = (GetResourceState('ox_inventory') == 'started'
                       or GetResourceState('qb-inventory') == 'started'
                       or GetResourceState('qs-inventory') == 'started'),

        -- Target
        hasOxTarget     = GetResourceState('ox_target') == 'started',
        hasQBTarget     = GetResourceState('qb-target') == 'started',
        hasTarget       = (GetResourceState('ox_target') == 'started'
                       or GetResourceState('qb-target') == 'started'),

        -- UI Libraries
        hasOxLib        = GetResourceState('ox_lib') == 'started',

        -- DjonStNix Ecosystem
        hasBanking      = GetResourceState('DjonStNix-Banking') == 'started',
        hasShops        = GetResourceState('DjonStNix-Shops') == 'started',
        hasGovernment   = GetResourceState('DjonStNix-Government') == 'started',

        -- External
        hasDispatch     = GetResourceState('ps-dispatch') == 'started',
    }

    return Core.Features
end

exports('GetFeatures', function()
    return RefreshFeatures()
end)
