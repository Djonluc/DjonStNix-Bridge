local QBox = nil

local function InitializeQBox()
    QBox = GetFrameworkObject()
    if not QBox then return end

    -- Use global Core

    -- QBox uses QBCore style for most things but has specific qbx_core exports
    -- We'll mirror the QB bridge but use qbx specific items where applicable
    
    -- QBox uses QBCore style for most things but has specific qbx_core exports
    
    Core.Player.GetPlayers = function()
        return exports.qbx_core:GetPlayers()
    end

    Core.Player.GetPlayer = function(src)
        return exports.qbx_core:GetPlayer(src)
    end

    Core.Player.GetPlayerData = function(src)
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData or nil
    end

    Core.Player.GetIdentifier = function(src)
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid or nil
    end

    Core.Player.GetName = function(src)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return "Unknown" end
        return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    end

    Core.Player.GetJob = function(src)
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.job or nil
    end

    Core.Player.HasLicense = function(src, license)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false end
        local meta = player.PlayerData.metadata
        local licenses = meta and (meta['licenses'] or meta['licences'])
        return licenses and (licenses[license] == true) or false
    end

    Core.Player.IsOnDuty = function(src)
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.job.onduty or false
    end

    Core.Player.SetJob = function(src, jobName, grade)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false end
        player.Functions.SetJob(jobName, grade or 0)
        return true
    end

    Core.Player.IsAdmin = function(src)
        return exports.qbx_core:HasPermission(src, 'admin') or exports.qbx_core:HasPermission(src, 'god')
    end

    -- --- MONEY ---
    Core.Money.AddMoney = function(src, account, amount, reason)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false end
        return player.Functions.AddMoney(account or 'bank', amount, reason or "djonstnix-bridge-deposit")
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false end
        if player.PlayerData.money[account or 'bank'] < amount then return false end
        return player.Functions.RemoveMoney(account or 'bank', amount, reason or "djonstnix-bridge-withdraw")
    end

    Core.Money.GetBalance = function(src, account)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return 0 end
        return player.PlayerData.money[account or 'bank'] or 0
    end

    -- --- ITEMS (ox_inventory — standard for QBox) ---
    Core.Items.AddItem = function(src, item, amount, metadata)
        return exports['ox_inventory']:AddItem(src, item, amount, metadata)
    end

    Core.Items.RemoveItem = function(src, item, amount)
        return exports['ox_inventory']:RemoveItem(src, item, amount)
    end

    Core.Items.HasItem = function(src, item)
        return exports['ox_inventory']:GetItemCount(src, item) >= 1
    end

    Core.Items.GetInventory = function(src)
        return exports['ox_inventory']:GetInventory(src) or {}
    end

    Core.Items.RegisterUsableItem = function(item, cb)
        -- QBox typically uses ox_inventory usable items
        if GetResourceState('ox_inventory') == 'started' then
            exports['ox_inventory']:RegisterUsableItem(item, cb)
        end
    end
end

if GetFramework() == 'qbox' then
    InitializeQBox()
end
