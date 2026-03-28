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

    Core.Player.HasJob = function(src, jobName, level)
        local job = Core.Player.GetJob(src)
        if not job or not jobName then return false end
        if string.lower(job.name or '') ~= string.lower(jobName) then return false end

        if level ~= nil then
            return tonumber(job.grade and job.grade.level or job.grade or 0) >= tonumber(level)
        end

        return true
    end

    Core.Player.IsOnDuty = function(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.job.onduty or false
    end

    Core.Player.HasLicense = function(src, license)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        local metadata = player.PlayerData.metadata
        if not metadata then return false end
        
        local hasLicense = (metadata['licences'] and metadata['licences'][license]) or (metadata['licenses'] and metadata['licenses'][license])
        return hasLicense == true
    end

    -- --- MONEY ---
    Core.Money.GetMoney = function(src, account)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return 0 end

        local moneyType = account == 'checking' and 'bank' or (account or 'bank')
        local bankAccountType = moneyType == 'savings' and 'savings' or ((moneyType == 'bank' or moneyType == 'checking') and 'checking' or nil)

        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' then
            local citizenid = Core.Player.GetIdentifier(src)
            local accountId = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            if accountId then
                return exports['DjonStNix-Banking']:GetBalance(accountId) / 100 -- Convert cents to dollars
            end
        end

        return player.PlayerData.money[moneyType] or 0
    end

    Core.Money.AddMoney = function(src, account, amount, reason, metadata)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        local moneyType = account == 'checking' and 'bank' or (account or 'bank')
        local bankAccountType = moneyType == 'savings' and 'savings' or ((moneyType == 'bank' or moneyType == 'checking') and 'checking' or nil)

        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' and not (metadata and metadata.skipBankingSync) then
            local citizenid = Core.Player.GetIdentifier(src)
            local targetAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            
            pcall(function()
                exports['DjonStNix-Banking']:ProcessTransaction(
                    nil, targetAcc, amount * 100, 'deposit', metadata or { reason = reason or "Bridge Deposit" }
                )
            end)
            -- We still sync with framework for secondary storage/UI compatibility
        end

        return player.Functions.AddMoney(moneyType, amount, reason or "djonstnix-bridge-deposit")
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason, metadata)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        local moneyType = account == 'checking' and 'bank' or (account or 'bank')
        local bankAccountType = moneyType == 'savings' and 'savings' or ((moneyType == 'bank' or moneyType == 'checking') and 'checking' or nil)
        if player.PlayerData.money[moneyType] < amount then return false end

        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' and not (metadata and metadata.skipBankingSync) then
            local citizenid = Core.Player.GetIdentifier(src)
            local sourceAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            
            -- Strict Enforcement for Bank Accounts
            local meta = metadata or { reason = reason or "General Purchase" }
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
            -- Framework sync happens below
        end

        return player.Functions.RemoveMoney(moneyType, amount, reason or "djonstnix-bridge-withdraw")
    end

    Core.Money.GetBalance = function(src, account)
        return Core.Money.GetMoney(src, account)
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

    Core.Items.GetItemCount = function(src, item)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:Search(src, 'count', item) or 0
        end
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return 0 end
        local itemData = player.Functions.GetItemByName(item)
        return itemData and itemData.amount or 0
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

    Core.Functions.GetPlayer = function(src)
        return Core.Player.GetPlayer(src)
    end

    Core.Functions.GetPlayers = function()
        return Core.Player.GetPlayers()
    end

    Core.Functions.GetPlayerData = function(src)
        return Core.Player.GetPlayerData(src)
    end

    -- --- CONVENIENCE WRAPPERS ---
    -- These allow downstream scripts to use short-form calls  
    Core.Notify = function(src, msg, type)
        TriggerClientEvent('QBCore:Notify', src, msg, type)
    end

    Core.RemoveMoney = function(src, account, amount, reason, metadata)
        return Core.Money.RemoveMoney(src, account, amount, reason, metadata)
    end

    Core.AddMoney = function(src, account, amount, reason, metadata)
        return Core.Money.AddMoney(src, account, amount, reason, metadata)
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

    -- --- BANKING COMPATIBILITY (qb-banking) ---
    -- The Bridge handles framework-native callbacks so the module remains clean.
    
    QBCore.Functions.CreateCallback('qb-banking:server:openBank', function(source, cb)
        if GetResourceState('DjonStNix-Banking') ~= 'started' then return cb({}, {}, {}) end
        local identifier = Core.Player.GetIdentifier(source)
        local data = exports['DjonStNix-Banking']:GetPlayerDashboardData(identifier, source)
        
        local legacyAccounts = {}
        local legacyStatements = {}

        if data.personal then
            table.insert(legacyAccounts, {
                account_name = 'checking',
                account_type = 'checking',
                account_balance = data.personal.balance / 100
            })
            legacyStatements['checking'] = {}
            for _, tx in ipairs(data.transactions or {}) do
                table.insert(legacyStatements['checking'], {
                    amount = tx.amount / 100,
                    reason = tx.metadata and tx.metadata.reason or "Transaction",
                    statement_type = tx.action_type,
                    date = tx.created_at_ms or (os.time() * 1000)
                })
            end
        end

        for _, bus in ipairs(data.businesses or {}) do
            table.insert(legacyAccounts, {
                account_name = bus.accountId,
                account_type = 'job',
                account_balance = bus.balance / 100,
                citizenid = identifier
            })
        end

        cb(legacyAccounts, legacyStatements, QBCore.Functions.GetPlayer(source).PlayerData)
    end)

    QBCore.Functions.CreateCallback('qb-banking:server:openATM', function(source, cb)
        if GetResourceState('DjonStNix-Banking') ~= 'started' then return cb({}, {}, {}) end
        local identifier = Core.Player.GetIdentifier(source)
        local bankCards = QBCore.Functions.GetPlayer(source).Functions.GetItemsByName('bank_card')
        local symbols = {}
        if bankCards then
            for _, card in ipairs(bankCards) do
                if card.info and card.info.cardPin then table.insert(symbols, card.info.cardPin) end
            end
        end

        local data = exports['DjonStNix-Banking']:GetPlayerDashboardData(identifier, source)
        local legacyAccounts = {}
        if data.personal then
            table.insert(legacyAccounts, {
                account_name = 'checking',
                account_type = 'checking',
                account_balance = data.personal.balance / 100
            })
        end

        cb(legacyAccounts, QBCore.Functions.GetPlayer(source).PlayerData, symbols)
    end)

    QBCore.Functions.CreateCallback('qb-banking:server:withdraw', function(source, cb, data)
        if GetResourceState('DjonStNix-Banking') ~= 'started' then return cb({success=false}) end
        local amountCents = math.floor(tonumber(data.amount) * 100)
        local accountId = data.accountName == 'checking' and nil or data.accountName
        
        local success, msg = exports['DjonStNix-Banking']:ProcessTransaction(accountId, nil, amountCents, 'withdraw', { reason = data.reason or "ATM Withdrawal" })
        if success then
            Core.Money.AddMoney(source, 'cash', tonumber(data.amount), "ATM Withdrawal")
            Core.Money.RemoveMoney(source, 'bank', tonumber(data.amount), "ATM Withdrawal", { skipBankingSync = true })
            cb({ success = true })
        else
            cb({ success = false, message = msg })
        end
    end)

    QBCore.Functions.CreateCallback('qb-banking:server:deposit', function(source, cb, data)
        if GetResourceState('DjonStNix-Banking') ~= 'started' then return cb({success=false}) end
        local amountCents = math.floor(tonumber(data.amount) * 100)
        local accountId = data.accountName == 'checking' and nil or data.accountName
        if Core.Money.GetBalance(source, 'cash') < tonumber(data.amount) then return cb({success=false, message="Insufficient Cash"}) end

        local success, msg = exports['DjonStNix-Banking']:ProcessTransaction(nil, accountId, amountCents, 'deposit', { reason = data.reason or "ATM Deposit" })
        if success then
            Core.Money.RemoveMoney(source, 'cash', tonumber(data.amount), "ATM Deposit")
            Core.Money.AddMoney(source, 'bank', tonumber(data.amount), "ATM Deposit", { skipBankingSync = true })
            cb({ success = true })
        else
            cb({ success = false, message = msg })
        end
    end)
end


if GetFramework() == 'qb' then
    InitializeQB()
end
