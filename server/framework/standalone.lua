local function InitializeStandalone()
    -- Use global Core

    -- --- PLAYER ---
    Core.Player.GetPlayers = function()
        return GetPlayers()
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

    Core.Money.AddMoney = function(src, account, amount, reason)
        print(("^3[DjonStNix-Bridge Standalone]^7 AddMoney %s to %s (No framework)"):format(amount, src))
        return true
    end

    Core.Money.RemoveMoney = function(src, account, amount, reason) return true end
    Core.Money.GetBalance = function(src, account) return 0 end

    -- --- ITEMS ---
    Core.Items.AddItem = function(src, item, amount) return true end
    Core.Items.RemoveItem = function(src, item, amount) return true end
    Core.Items.HasItem = function(src, item) return false end
    Core.Items.GetInventory = function(src) return {} end
    Core.Items.RegisterUsableItem = function(item, cb)
        print(("^3[DjonStNix-Bridge Standalone]^7 RegisterUsableItem '%s' (No framework)"):format(item))
    end
end

if GetFramework() == 'standalone' then
    InitializeStandalone()
end
