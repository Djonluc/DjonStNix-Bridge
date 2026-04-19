local ESX = nil

local function InitializeESX()
    ESX = GetFrameworkObject()

    -- Safety: if ESX object is still nil after GetFrameworkObject retries, wait here
    if not ESX then
        print("^3[DjonStNix-Bridge] ESX server: Waiting for shared object...^7")
        local retries = 0
        while not ESX and retries < 100 do
            Wait(100)
            retries = retries + 1
            ESX = GetFrameworkObject()
        end
    end

    if not ESX then
        print("^1[DjonStNix-Bridge] CRITICAL: ESX shared object unavailable on server! All ESX functions will be broken.^7")
        return
    end

    -- Use global Core

    -- --- PLAYER ---
    Core.Player.GetPlayers = function()
        return ESX.GetPlayers()
    end

    Core.Player.GetPlayer = function(src)
        return ESX.GetPlayerFromId(src)
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

    Core.Player.HasLicense = function(src, licenseType)
        local p = promise.new()
        TriggerEvent('esx_license:checkLicense', src, licenseType, function(has)
            p:resolve(has)
        end)
        return Citizen.Await(p)
    end

    Core.Player.SetMetaData = function(src, key, value)
        -- ESX mapping common ones to status
        if key == 'stress' then
            TriggerClientEvent('esx_status:set', src, 'stress', value * 10000)
            return true
        end
        return false
    end

    Core.Player.GetMetaData = function(src, key)
        if key == 'stress' then return 0 end
        return nil
    end

    -- --- MONEY ---
    Core.Money.GetMoney = function(src, account)
        local player = ESX.GetPlayerFromId(src)
        if not player then return 0 end
        local moneyType = account == 'cash' and 'money' or ((account == 'checking' or account == 'savings') and 'bank' or (account or 'bank'))
        local bankAccountType = moneyType == 'savings' and 'savings' or (moneyType == 'bank' and 'checking' or nil)

        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' then
            local citizenid = Core.Player.GetIdentifier(src)
            local accountId = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            if accountId then
                return exports['DjonStNix-Banking']:GetBalance(accountId) / 100
            end
        end

        local acc = player.getAccount(moneyType)
        return acc and acc.money or 0
    end

    Core.Money.AddMoney = function(src, account, amount, reason, metadata)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        local moneyType = account == 'cash' and 'money' or ((account == 'checking' or account == 'savings') and 'bank' or (account or 'bank'))
        local bankAccountType = moneyType == 'savings' and 'savings' or (moneyType == 'bank' and 'checking' or nil)

        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' and not (metadata and metadata.skipBankingSync) then
            local citizenid = Core.Player.GetIdentifier(src)
            local targetAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            
            pcall(function()
                exports['DjonStNix-Banking']:ProcessTransaction(
                    nil, targetAcc, amount * 100, 'deposit', metadata or { reason = reason or "Bridge Deposit" }
                )
            end)
        end

        player.addAccountMoney(moneyType, amount)
        return true
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason, metadata)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        local moneyType = account == 'cash' and 'money' or ((account == 'checking' or account == 'savings') and 'bank' or (account or 'bank'))
        local bankAccountType = moneyType == 'savings' and 'savings' or (moneyType == 'bank' and 'checking' or nil)
        
        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' and not (metadata and metadata.skipBankingSync) then
            local citizenid = Core.Player.GetIdentifier(src)
            local sourceAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            
            -- Strict Enforcement for Bank Accounts
            local meta = metadata or { reason = reason or "General Purchase" }
            if type(reason) == "table" then meta = reason end

            if bankAccountType == 'checking' and not meta.receipt then
                local invokingResource = GetInvokingResource() or "Unknown"
                print("^1[DjonStNix-Bridge] CRITICAL WARNING: Bank transaction missing receipt! Resource: " .. invokingResource .. "^7")

                -- Construct fallback receipt as per spec
                meta.receipt = {
                    source = "Unknown Transaction",
                    items = { { name = "Transaction", quantity = 1, unitPrice = amount, total = amount } },
                    subtotal = amount,
                    tax = 0,
                    total = amount,
                    date = os.date("%Y-%m-%d %H:%M:%S"),
                    flagged_fallback = true
                }
            end

            local success, msg = exports['DjonStNix-Banking']:ProcessTransaction(
                sourceAcc, nil, amount * 100, 'withdraw', meta
            )
            if not success then return false end
        end

        if player.getAccount(moneyType).money >= amount then
            player.removeAccountMoney(moneyType, amount)
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
        -- Prefer ox_inventory for metadata support (weapon serials, quality, etc.)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:AddItem(src, item, amount, metadata)
        end
        player.addInventoryItem(item, amount)
        return true
    end

    Core.Items.RemoveItem = function(src, item, amount, metadata)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:RemoveItem(src, item, amount, metadata)
        end
        player.removeInventoryItem(item, amount)
        return true
    end

    Core.Items.HasItem = function(src, item)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        if GetResourceState('ox_inventory') == 'started' then
            local search = exports.ox_inventory:Search(src, 'count', item)
            return search and search >= 1
        end
        local invItem = player.getInventoryItem(item)
        return invItem and invItem.count >= 1
    end

    Core.Items.GetInventory = function(src)
        local player = ESX.GetPlayerFromId(src)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:GetInventoryItems(src) or {}
        end
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

    Core.Functions.GetPlayer = function(src)
        return Core.Player.GetPlayer(src)
    end

    Core.Functions.GetPlayers = function()
        return Core.Player.GetPlayers()
    end

    Core.Functions.GetPlayerData = function(src)
        return Core.Player.GetPlayerData(src)
    end

    Core.Notify = function(src, msg, type)
        Core.UI.Notify(src, msg, type)
    end

    Core.RemoveMoney = function(src, account, amount, reason, metadata)
        return Core.Money.RemoveMoney(src, account, amount, reason, metadata)
    end

    Core.AddMoney = function(src, account, amount, reason, metadata)
        return Core.Money.AddMoney(src, account, amount, reason, metadata)
    end

    -- --- FUNCTIONS (CALLBACKS) ---
    Core.Functions.CreateCallback = function(name, cb)
        ESX.RegisterServerCallback(name, cb)
    end

    Core.Functions.TriggerCallback = function(name, source, cb, ...)
        -- Server-side TriggerCallback is rarely used, but mapped for parity
        print("^3[DjonStNix-Bridge] Warning: Server-side TriggerCallback called on ESX.^7")
    end

    -- --- ITEMS (Extended) ---
    Core.Items.GetItemCount = function(src, item)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:Search(src, 'count', item) or 0
        end
        local player = ESX.GetPlayerFromId(src)
        if not player then return 0 end
        local invItem = player.getInventoryItem(item)
        return invItem and invItem.count or 0
    end

    -- --- PLAYER (Extended) ---
    Core.Player.GetDutyCount = function(jobName)
        local count = 0
        local xPlayers = ESX.GetExtendedPlayers('job', jobName)
        for _, xPlayer in pairs(xPlayers) do
            count = count + 1
        end
        return count
    end

    -- --- SOURCE FROM IDENTIFIER ---
    Core.Player.GetSourceFromIdentifier = function(identifier)
        local xPlayers = ESX.GetPlayers()
        for _, playerId in ipairs(xPlayers) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer and xPlayer.identifier == identifier then
                return playerId
            end
        end
        return nil
    end

    -- --- PERMISSION HELPERS ---
    Core.Player.HasPermission = function(src, permList)
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        local group = player.getGroup()
        if type(permList) == "table" then
            for _, perm in ipairs(permList) do
                if group == perm then return true end
            end
            return false
        end
        return group == permList
    end

    print("^2[DjonStNix-Bridge]^7 ESX server-side module initialized successfully.")
end

if GetFramework() == 'esx' then
    InitializeESX()
end
