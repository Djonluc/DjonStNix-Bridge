local function InitializeStandalone()
    -- Use global Core

    -- --- PLAYER ---
    Core.Player.GetPlayers = function()
        return GetPlayers()
    end

    Core.Player.GetPlayer = function(src)
        return { source = src }
    end

    Core.Player.GetPlayerData = function(src)
        return { source = src, citizenid = GetPlayerIdentifier(src, 0), job = { name = "unemployed", label = "Unemployed", grade = 0 } }
    end

    Core.Player.GetName = function(src)
        return GetPlayerName(src) or "Standalone User"
    end

    Core.Player.GetIdentifier = function(src)
        return GetPlayerIdentifier(src, 0)
    end

    Core.Player.GetJob = function(src)
        return { name = "unemployed", label = "Unemployed", grade = 0 }
    end

    Core.Player.SetJob = function(src, jobName, grade)
        print(("^3[DjonStNix-Bridge Standalone]^7 SetJob called for %s → %s (No framework)"):format(src, jobName))
        return true
    end

    Core.Player.IsOnDuty = function(src) return false end
    Core.Player.IsAdmin = function(src) return false end

    -- --- MONEY ---
    Core.Money.GetMoney = function(src, account) return 0 end

    Core.Money.AddMoney = function(src, account, amount, reason, metadata)
        print(("^3[DjonStNix-Bridge Standalone]^7 AddMoney %s to %s (No framework)"):format(amount, src))
        return true
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason, metadata)
        local moneyType = account or 'bank'
        local bankAccountType = moneyType == 'savings' and 'savings' or ((moneyType == 'bank' or moneyType == 'checking') and 'checking' or nil)

        -- Priority Check: DjonStNix-Banking
        if bankAccountType and GetResourceState('DjonStNix-Banking') == 'started' and not (metadata and metadata.skipBankingSync) then
            local citizenid = Core.Player.GetIdentifier(src)
            local sourceAcc = exports['DjonStNix-Banking']:GetAccountByCitizenId(citizenid, bankAccountType)
            
            -- Strict Enforcement for Bank Accounts
            local meta = metadata or { reason = reason or "General Purchase" }
            if (not account or account == 'bank') and not meta.receipt then
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

        print(("^3[DjonStNix-Bridge Standalone]^7 RemoveMoney %s from %s (No framework)"):format(amount, src))
        return true
    end
    Core.Money.GetBalance = function(src, account) return 0 end

    -- --- ITEMS ---
    Core.Items.AddItem = function(src, item, amount) return true end
    Core.Items.RemoveItem = function(src, item, amount) return true end
    Core.Items.HasItem = function(src, item) return false end
    Core.Items.GetInventory = function(src) return {} end
    Core.Items.RegisterUsableItem = function(item, cb)
        print(("^3[DjonStNix-Bridge Standalone]^7 RegisterUsableItem '%s' (No framework)"):format(item))
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

if GetFramework() == 'standalone' then
    InitializeStandalone()
end
