local QBCore = nil

local function InitializeQB()
    QBCore = GetFrameworkObject()
    if not QBCore then return end

    -- QBCore = GetFrameworkObject() -- Already handled by GetFrameworkObject in InitializeQB scope? 
    -- Actually QBCore is local to the file, InitializeQB is called synchronously.

    -- --- PLAYER ---
    Core.Player.GetPlayer = function(src)
        return QBCore.Functions.GetPlayer(src)
    end

    Core.Player.GetPlayers = function()
        return QBCore.Functions.GetPlayers()
    end

    Core.Player.GetPlayerData = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData or nil
    end

    Core.Player.GetIdentifier = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid or nil
    end

    Core.Player.GetSourceFromIdentifier = function(identifier)
        local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
        return player and player.PlayerData.source or nil
    end

    Core.Player.GetName = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return "Unknown" end
        return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    end

    Core.Player.GetJob = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.job or nil
    end

    Core.Player.IsOnDuty = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.job.onduty or false
    end

    Core.Player.HasLicense = function(src, license)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        return player.PlayerData.metadata and player.PlayerData.metadata['licences'] and player.PlayerData.metadata['licences'][license]
    end

    -- --- MONEY ---
    Core.Money.GetMoney = function(src, account)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return 0 end
        return player.PlayerData.money[account or 'bank'] or 0
    end

    Core.Money.AddMoney = function(src, account, amount, reason)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        return player.Functions.AddMoney(account or 'bank', amount, reason or "djonstnix-bridge-deposit")
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        if player.PlayerData.money[account or 'bank'] < amount then return false end
        return player.Functions.RemoveMoney(account or 'bank', amount, reason or "djonstnix-bridge-withdraw")
    end

    Core.Money.GetBalance = function(src, account)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return 0 end
        return player.PlayerData.money[account or 'bank'] or 0
    end

    -- --- UI ---
    Core.UI.Notify = function(src, message, type)
        TriggerClientEvent('QBCore:Notify', src, message, type)
    end

    -- --- ITEMS ---
    Core.Items.AddItem = function(src, item, amount, metadata)
        return exports['qb-inventory']:AddItem(src, item, amount, nil, metadata)
    end

    Core.Items.RemoveItem = function(src, item, amount)
        return exports['qb-inventory']:RemoveItem(src, item, amount)
    end

    Core.Items.HasItem = function(src, item)
        return exports['qb-inventory']:HasItem(src, item, 1)
    end

    Core.Items.GetItemData = function(itemName)
        return QBCore.Shared.Items[itemName] or nil
    end

    Core.Items.GetInventory = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.items or {}
    end

    Core.Items.RegisterUsableItem = function(item, cb)
        QBCore.Functions.CreateUseableItem(item, cb)
    end

    -- --- REGISTRY ---
    Core.Registry.SearchCitizens = function(query)
        return MySQL.query.await('SELECT citizenid, charinfo, metadata FROM players WHERE citizenid LIKE ? OR JSON_EXTRACT(charinfo, "$.firstname") LIKE ? OR JSON_EXTRACT(charinfo, "$.lastname") LIKE ? LIMIT 20', {
            '%'..query..'%', '%'..query..'%', '%'..query..'%'
        })
    end

    Core.Registry.SearchVehicles = function(citizenid)
        return MySQL.query.await('SELECT plate, vehicle FROM player_vehicles WHERE citizenid = ?', {citizenid})
    end

    -- --- JOB ---
    Core.Player.SetJob = function(src, jobName, grade)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        player.Functions.SetJob(jobName, grade or 0)
        return true
    end

    Core.Player.IsAdmin = function(src)
        return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
    end

    -- --- VEHICLE ---
    Core.Vehicle.GetOwnedVehicles = function(identifier)
        return MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {identifier})
    end

    Core.Vehicle.SetVehicleOwner = function(plate, identifier)
        return MySQL.update.await('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', {identifier, plate})
    end

    Core.Vehicle.ValidateVehicleOwnership = function(src, plate)
        local identifier = Core.Player.GetIdentifier(src)
        local result = MySQL.single.await('SELECT 1 FROM player_vehicles WHERE citizenid = ? AND plate = ?', {identifier, plate})
        return result ~= nil
    end

    -- --- VEHICLE DATA ---
    Core.Vehicle.GetVehicleData = function(model)
        return QBCore.Shared.Vehicles[model] or nil
    end

    Core.Vehicle.GetVehiclePrice = function(model)
        local data = Core.Vehicle.GetVehicleData(model)
        return data and data.price or 0
    end

    Core.Vehicle.GetVehicleLabel = function(model)
        local data = Core.Vehicle.GetVehicleData(model)
        if data then return data.name or data.model end
        return model
    end

    -- --- FUNCTIONS (CALLBACKS) ---
    Core.Functions.CreateCallback = function(name, cb)
        QBCore.Functions.CreateCallback(name, cb)
    end

    Core.Functions.TriggerCallback = function(name, source, cb, ...)
        QBCore.Functions.TriggerCallback(name, source, cb, ...)
    end

    -- --- CONVENIENCE WRAPPERS ---
    -- These allow downstream scripts to use short-form calls  
    Core.Notify = function(src, msg, type)
        TriggerClientEvent('QBCore:Notify', src, msg, type)
    end

    Core.RemoveMoney = function(src, account, amount, reason)
        return Core.Money.RemoveMoney(src, account, amount, reason)
    end

    Core.AddMoney = function(src, account, amount, reason)
        return Core.Money.AddMoney(src, account, amount, reason)
    end

    Core.Player.GetLicense = function(src)
        local identifiers = GetPlayerIdentifiers(src)
        for _, id in ipairs(identifiers) do
            if string.find(id, 'license:') then
                return id
            end
        end
        return nil
    end
end

if GetFramework() == 'qb' then
    InitializeQB()
end
