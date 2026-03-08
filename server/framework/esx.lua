local ESX = nil

local function InitializeESX()
    ESX = GetFrameworkObject()
    if not ESX then return end

    -- Use global Core

    -- --- PLAYER ---
    Core.Player.GetPlayers = function()
        return ESX.GetPlayers()
    end

    Core.Player.GetPlayerData = function(src)
        local player = ESX.GetPlayerFromId(src)
        if not player then return nil end
        -- Basic normalization for QBCore-like access where possible
        return {
            source = src,
            citizenid = player.identifier,
            job = player.job,
            charinfo = { firstname = player.get('firstName') or "ESX", lastname = player.get('lastName') or "Player" }
        }
    end

    Core.Player.GetName = function(src)
        local player = ESX.GetPlayerFromId(src)
        if not player then return "Unknown" end
        local fname = player.get('firstName') or "ESX"
        local lname = player.get('lastName') or "Player"
        return fname .. " " .. lname
    end

    Core.Player.GetIdentifier = function(src)
        local player = ESX.GetPlayerFromId(src)
        return player and player.identifier or nil
    end

    Core.Player.GetJob = function(src)
        local player = ESX.GetPlayerFromId(src)
        return player and player.job or nil
    end

    Core.Player.IsOnDuty = function(src)
        local player = ESX.GetPlayerFromId(src)
        return player and player.job and player.job.onDuty or false
    end

    Core.Player.SetJob = function(src, jobName, grade)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        player.setJob(jobName, grade or 0)
        return true
    end

    Core.Player.IsAdmin = function(src)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        local group = player.getGroup()
        return group == 'admin' or group == 'superadmin'
    end

    -- --- MONEY ---
    Core.Money.GetMoney = function(src, account)
        local player = ESX.GetPlayerFromId(src)
        if not player then return 0 end

        -- Priority Check: DjonStNix-Banking
        if GetResourceState('DjonStNix-Banking') == 'started' then
            local citizenid = Core.Player.GetIdentifier(src)
            local accountId = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, account == 'bank' and 'checking' or 'savings') -- Default mapping
            if accountId then
                return exports['DjonStNix-Banking']:GetBalance(accountId) / 100
            end
        end

        local acc = player.getAccount(account == 'bank' and 'bank' or 'money')
        return acc and acc.money or 0
    end

    Core.Money.AddMoney = function(src, account, amount, reason)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end

        -- Priority Check: DjonStNix-Banking
        if GetResourceState('DjonStNix-Banking') == 'started' then
            local citizenid = Core.Player.GetIdentifier(src)
            local targetAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, account == 'bank' and 'checking' or 'savings')
            
            pcall(function()
                exports['DjonStNix-Banking']:ProcessTransaction(
                    nil, targetAcc, amount * 100, 'deposit', { reason = reason or "Bridge Deposit" }
                )
            end)
        end

        player.addAccountMoney(account == 'bank' and 'bank' or 'money', amount)
        return true
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        
        -- Priority Check: DjonStNix-Banking
        if GetResourceState('DjonStNix-Banking') == 'started' then
            local citizenid = Core.Player.GetIdentifier(src)
            local sourceAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, account == 'bank' and 'checking' or 'savings')
            
            local success, msg = exports['DjonStNix-Banking']:ProcessTransaction(
                sourceAcc, nil, amount * 100, 'withdraw', { reason = reason or "Bridge Withdraw" }
            )
            if not success then return false end
        end

        if player.getAccount(account == 'bank' and 'bank' or 'money').money >= amount then
            player.removeAccountMoney(account == 'bank' and 'bank' or 'money', amount)
            return true
        end
        return false
    end

    Core.Money.GetBalance = function(src, account)
        return Core.Money.GetMoney(src, account)
    end

    -- --- UI ---
    Core.UI.Notify = function(src, message, type)
        TriggerClientEvent('esx:showNotification', src, message)
    end

    -- --- ITEMS ---
    Core.Items.AddItem = function(src, item, amount, metadata)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        player.addInventoryItem(item, amount)
        return true
    end

    Core.Items.RemoveItem = function(src, item, amount)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        player.removeInventoryItem(item, amount)
        return true
    end

    Core.Items.HasItem = function(src, item)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        local invItem = player.getInventoryItem(item)
        return invItem and invItem.count >= 1
    end

    Core.Items.GetInventory = function(src)
        local player = ESX.GetPlayerFromId(src)
        return player and player.getInventory() or {}
    end

    Core.Items.RegisterUsableItem = function(item, cb)
        ESX.RegisterUsableItem(item, cb)
    end

    Core.Items.GetItemData = function(itemName)
        local item = ESX.GetItemLabel(itemName)
        return item and { name = itemName, label = item } or nil
    end

    -- --- REGISTRY ---
    Core.Registry.SearchCitizens = function(query)
        return MySQL.query.await('SELECT identifier as citizenid, firstname, lastname FROM users WHERE identifier LIKE ? OR firstname LIKE ? OR lastname LIKE ? LIMIT 20', {
            '%'..query..'%', '%'..query..'%', '%'..query..'%'
        })
    end

    Core.Registry.SearchVehicles = function(citizenid)
        return MySQL.query.await('SELECT plate, vehicle FROM owned_vehicles WHERE owner = ?', {citizenid})
    end

    -- --- VEHICLE ---
    Core.Vehicle.GetOwnedVehicles = function(identifier)
        return MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', {identifier})
    end

    Core.Vehicle.SetVehicleOwner = function(plate, identifier)
        return MySQL.update.await('UPDATE owned_vehicles SET owner = ? WHERE plate = ?', {identifier, plate})
    end

    Core.Vehicle.ValidateVehicleOwnership = function(src, plate)
        local identifier = Core.Player.GetIdentifier(src)
        local result = MySQL.single.await('SELECT 1 FROM owned_vehicles WHERE owner = ? AND plate = ?', {identifier, plate})
        return result ~= nil
    end
end

if GetFramework() == 'esx' then
    InitializeESX()
end
