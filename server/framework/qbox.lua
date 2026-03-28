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

    Core.Player.GetSourceFromIdentifier = function(identifier)
        for _, src in ipairs(Core.Player.GetPlayers() or {}) do
            if Core.Player.GetIdentifier(src) == identifier then
                return src
            end
        end
        return nil
    end

    Core.Player.GetJob = function(src)
        local player = exports.qbx_core:GetPlayer(src)
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
    Core.Money.GetMoney = function(src, account)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return 0 end
        local moneyType = account == 'checking' and 'bank' or (account or 'bank')
        local bankAccountType = moneyType == 'savings' and 'savings' or ((moneyType == 'bank' or moneyType == 'checking') and 'checking' or nil)

        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' then
            local citizenid = Core.Player.GetIdentifier(src)
            local accountId = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            if accountId then
                return exports['DjonStNix-Banking']:GetBalance(accountId) / 100
            end
        end

        return player.PlayerData.money[moneyType] or 0
    end

    Core.Money.AddMoney = function(src, account, amount, reason, metadata)
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false end
        local moneyType = account == 'checking' and 'bank' or (account or 'bank')
        local bankAccountType = moneyType == 'savings' and 'savings' or ((moneyType == 'bank' or moneyType == 'checking') and 'checking' or nil)

        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' and not (metadata and metadata.skipBankingSync) then
            local citizenid = Core.Player.GetIdentifier(src)
            local targetAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)

            pcall(function()
                exports['DjonStNix-Banking']:ProcessTransaction(
                    nil, targetAcc, amount * 100, 'deposit', metadata or { reason = reason or "Bridge Deposit" }
                )
            end)
        end

        return player.Functions.AddMoney(moneyType, amount, reason or "djonstnix-bridge-deposit")
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason, metadata)
        local player = exports.qbx_core:GetPlayer(src)
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
end

if GetFramework() == 'qbox' then
    InitializeQBox()
end
