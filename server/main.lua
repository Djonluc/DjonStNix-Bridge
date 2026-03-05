-- ==============================================================================
-- 👑 DJONSTNIX BRANDING
-- ==============================================================================
-- DEVELOPED BY: DjonStNix (DjonLuc)
-- GITHUB: https://github.com/Djonluc
-- DISCORD: https://discord.gg/s7GPUHWrS7
-- YOUTUBE: https://www.youtube.com/@Djonluc
-- EMAIL: djonstnix@gmail.com
-- LICENSE: MIT License (c) 2026 DjonStNix (DjonLuc)
-- ==============================================================================

-- ==================================================
-- DjonStNix-Bridge MASTER SERVER ENTRY
-- ==================================================

CreateThread(function()
    print("^4" .. [[
  _____  _             ____       _     _               
 |  __ \(_)           |  _ \     (_)   | |              
 | |  | |_  ___  _ __ | |_) |_ __ _  __| | __ _  ___ 
 | |  | | |/ _ \| '_ \|  _ <| '__| |/ _` |/ _` |/ _ \
 | |__| | | (_) | | | | |_) | |  | | (_| | (_| |  __/
 |_____/| |\___/|_| |_|____/|_|  |_|\__,_|\__, |\___|
       _/ |                                __/ |      
      |__/                                |___/       
    ]] .. "^7")
    
    print(("^4[%s]^7 v%s — Initializing Master Architecture..."):format(Config.BrandName, Config.Version or "1.0.0"))
    
    local framework = GetFramework()
    print(("^4[%s]^7 Framework Detected: ^2%s^7"):format(Config.BrandName, framework))
    
    -- [[ STRICT BOOT VALIDATION ]] --
    local missingDeps = {}
    if GetResourceState('oxmysql') ~= 'started' then table.insert(missingDeps, "oxmysql") end
    
    if #missingDeps > 0 then
        print(("^1[CRITICAL ERROR] DjonStNix-Bridge has Halted Boot Sequence!^7"):format())
        print(("^1[MISSING DEPENDENCIES]^7 You must start the following before Bridge: ^3%s^7"):format(table.concat(missingDeps, ", ")))
        return -- Halt loading of integration states
    end
    -- [[ END BOOT VALIDATION ]] --

    Wait(500)
    RefreshIntegrations()
    RefreshFeatures()

    -- Log detected capabilities
    local f = Core.Features
    local caps = {}
    if f.hasInventory    then caps[#caps+1] = "Inventory" end
    if f.hasTarget       then caps[#caps+1] = "Target" end
    if f.hasOxLib        then caps[#caps+1] = "ox_lib" end
    if f.hasBanking      then caps[#caps+1] = "Banking" end
    if f.hasShops        then caps[#caps+1] = "Shops" end
    if f.hasDispatch     then caps[#caps+1] = "Dispatch" end
    print(("^4[%s]^7 Feature Gates: ^2%s^7"):format(Config.BrandName, #caps > 0 and table.concat(caps, ", ") or "None"))
    
    Core.Ready = true
    print(("^2[DjonStNix-Bridge]^7 v%s — Core.Ready is now TRUE."):format(Config.Version or "1.0.0"))

    -- [[ OS BOOT GRAPH REPORT (Delayed to allow scripts to load) ]] --
    SetTimeout(2500, function()
        print("\n^4====================================")
        print("    DjonStNix Ecosystem Boot Report")
        print("====================================^7")
        print("  ^2DjonStNix-Bridge         [✓]^7")

        local function checkDep(name)
            local state = GetResourceState(name)
            if state == 'started' then
                print(("  ^2%-24s [✓]^7"):format(name))
            else
                print(("  ^1%-24s [✗] (%s)^7"):format(name, state))
            end
        end

        checkDep('DjonStNix-Banking')
        checkDep('djonstnix-economy')
        checkDep('DjonStNix-Shops')
        checkDep('djonstnix-vehicles')
        checkDep('DjonStNix-Transactions')
        checkDep('djonstnix-analytics')
        checkDep('DjonStNix-Billing')
        checkDep('DjonStNix-Identity')
        checkDep('DjonStNix-AssetRegistry')
        print("^4====================================^7\n")
    end)
end)

-- ==================================================
-- PHASE 25: MDT PROFILE AGGREGATOR
-- ==================================================
--- Universal citizen dossier for Police MDT systems.
--- Usage: exports['DjonStNix-Bridge']:GetPlayerProfile(citizenid)
exports('GetPlayerProfile', function(citizenid)
    if not citizenid then return nil end
    local profile = { citizenid = citizenid }

    -- 1. Bank Accounts & Balances
    if GetResourceState('DjonStNix-Banking') == 'started' then
        pcall(function()
            local accs = MySQL.query.await('SELECT account_id, account_name, account_type, balance FROM djonstnix_bank_accounts WHERE owner_id = ?', { citizenid })
            profile.accounts = accs or {}
        end)
    end

    -- 2. Unpaid Invoices
    if GetResourceState('DjonStNix-Billing') == 'started' then
        pcall(function()
            local invs = MySQL.query.await('SELECT invoice_id, total, issuer_type, issuer_id, status, created_at FROM djonstnix_invoices WHERE target_id = ? AND status = "pending"', { citizenid })
            profile.invoices = invs or {}
        end)
    end

    -- 3. Licenses & Documents
    if GetResourceState('DjonStNix-Identity') == 'started' then
        pcall(function()
            profile.licenses = exports['DjonStNix-Identity']:GetAll(citizenid)
        end)
    end

    -- 4. Registered Assets
    if GetResourceState('DjonStNix-AssetRegistry') == 'started' then
        pcall(function()
            profile.assets = exports['DjonStNix-AssetRegistry']:GetPlayerAssets(citizenid)
        end)
    end

    return profile
end)
