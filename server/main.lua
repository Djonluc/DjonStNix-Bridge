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

local function GetStartedResource(candidates)
    for _, resourceName in ipairs(candidates) do
        if GetResourceState(resourceName) == 'started' then
            return resourceName
        end
    end
    return nil
end

CreateThread(function()
    Wait(100)
    Core.Utils.PrintBanner("DjonStNix-Bridge", "2.0.0")
    
    local framework = GetFramework()
    print(("^4[DjonStNix-Bridge]^7 Framework Detected: ^2%s^7"):format(framework))
    
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
    
    -- [[ GOVERNMENT INTEGRATION ]] --
    Core.Government.GetTaxConfig = function()
        if GetResourceState('DjonStNix-Government') == 'started' then
            return exports['DjonStNix-Government']:GetTaxConfig()
        end
        return { enabled = false, rates = {} }
    end

    Core.Government.RegisterWeapon = function(src, weaponModel, serialNumber)
        if GetResourceState('DjonStNix-Government') == 'started' then
            return exports['DjonStNix-Government']:RegisterWeapon(src, weaponModel, serialNumber)
        end
        return false
    end

    -- [[ PHONE INTEGRATION ]] --
    Core.Phone.SendMail = function(src, data)
        if not src or not data then return end
        local p = Config.Phone
        if p == "auto" then
            if IsResourceRunning('qb-phone') then p = "qb-phone"
            elseif IsResourceRunning('lb-phone') then p = "lb-phone"
            elseif IsResourceRunning('qs-smartphone') then p = "qs-phone"
            elseif IsResourceRunning('gksphone') then p = "gksphone"
            else p = "none" end
        end

        local sender = data.sender or Config.PhoneSettings.DefaultSender
        local subject = data.subject or Config.PhoneSettings.DefaultSubject
        local message = data.message or "No message content."

        if p == "qb-phone" then
            TriggerClientEvent('qb-phone:client:NewMail', src, {
                sender = sender,
                subject = subject,
                message = message,
                button = data.button or {}
            })
        elseif p == "lb-phone" then
            exports["lb-phone"]:SendMail(src, {
                sender = sender,
                subject = subject,
                message = message,
            })
        elseif p == "qs-phone" then
            exports['qs-smartphone']:SendEmail(src, {
                sender = sender,
                subject = subject,
                message = message,
                image = data.image or '/html/img/mail.png'
            })
        elseif p == "gksphone" then
            TriggerServerEvent('gksphone:NewMail', src, sender, subject, message)
        end
    end

    Core.Phone.SendNotification = function(src, data)
        if not src or not data then return end
        local p = Config.Phone
        if p == "auto" then
            if IsResourceRunning('qb-phone') then p = "qb-phone"
            elseif IsResourceRunning('lb-phone') then p = "lb-phone"
            elseif IsResourceRunning('qs-smartphone') then p = "qs-phone"
            elseif IsResourceRunning('gksphone') then p = "gksphone"
            else p = "none" end
        end

        local title = data.title or Config.PhoneSettings.DefaultSender
        local content = data.content or data.message or ""
        local icon = data.icon or Config.PhoneSettings.DefaultIcon

        if p == "qb-phone" then
            TriggerClientEvent('qb-phone:client:CustomNotification', src, title, content, icon, '#f4b400', 8000)
        elseif p == "lb-phone" then
            exports["lb-phone"]:SendNotification(src, {
                app = "System",
                title = title,
                content = content,
                duration = 8000
            })
        elseif p == "qs-phone" then
            TriggerClientEvent('qs-smartphone:client:CustomNotification', src, {
                title = title,
                text = content,
                icon = icon
            })
        end
    end

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
        checkDep(GetStartedResource({'DjonStNix-economy', 'djonstnix-economy', 'DjonStNix-Economy'}) or 'DjonStNix-economy')
        checkDep('DjonStNix-Shops')
        checkDep(GetStartedResource({'DjonStNix-vehicles', 'djonstnix-vehicles'}) or 'DjonStNix-vehicles')
        checkDep(GetStartedResource({'DjonStNix-analytics', 'djonstnix-analytics'}) or 'DjonStNix-analytics')
        checkDep('DjonStNix-Government')
        checkDep('DjonStNix-AssetRegistry')
        print("^4====================================^7\n")
    end)
end)

-- ==================================================
-- SDK UTILITY COMMANDS
-- ==================================================

RegisterCommand('dsn-plugins', function(source, args, rawCommand)
    if source ~= 0 and not Core.Player.IsAdmin(source) then return end
    
    local plugins = Core.Registry.Plugins or {}
    local count = 0
    for _ in pairs(plugins) do count = count + 1 end
    
    print("^5====================================^0")
    print("^3  DJONSTNIX SDK PLUGINS (" .. count .. ")^0")
    print("^5====================================^0")
    if count == 0 then
        print("  ^7No external plugins registered.")
    else
        for name, data in pairs(plugins) do
            print(("^2- %-20s ^7v%-8s ^3(%s)^7"):format(name, data.version or "1.0", data.author or "Unknown"))
        end
    end
    print("^5====================================^0")
end, false)

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
            local accs = MySQL.query.await('SELECT account_id, account_name, account_type, balance FROM djonstnix_bank_accounts WHERE citizenid = ?', { citizenid })
            profile.accounts = accs or {}
        end)
    end

    -- 2. Unpaid Invoices
    if GetResourceState('DjonStNix-Banking') == 'started' then
        pcall(function()
            local invs = MySQL.query.await([[
                SELECT invoice_id, amount, society, biller_citizenid, status, created_at
                FROM djonstnix_bank_invoices
                WHERE billed_citizenid = ? AND status = "unpaid"
            ]], { citizenid })
            profile.invoices = invs or {}
        end)
    end

    -- 3. Government Profile (Identity, Licenses, Assets)
    if GetResourceState('DjonStNix-Government') == 'started' then
        pcall(function()
            local govProfile = exports['DjonStNix-Government']:GetCitizenProfile(citizenid)
            if govProfile then
                profile.licenses = govProfile.licenses
                profile.assets = govProfile.assets
                profile.government = {
                    firstname = govProfile.firstname,
                    lastname = govProfile.lastname,
                    dob = govProfile.dob,
                    gender = govProfile.gender
                }
            end
        end)
    end

    return profile
end)

-- ==================================================
-- PLAYER LOADED HOOKS
-- ==================================================

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player then return end
    EventBus.Emit('player:loaded', { source = Player.PlayerData.source, identifier = Player.PlayerData.citizenid })
end)

AddEventHandler('esx:playerLoaded', function(source, player)
    if not player then return end
    EventBus.Emit('player:loaded', { source = source, identifier = player.identifier })
end)

AddEventHandler('qbx_core:server:playerLoaded', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    EventBus.Emit('player:loaded', { source = source, identifier = player.PlayerData.citizenid })
end)

-- ==================================================
-- SYSTEM DIAGNOSTICS
-- ==================================================

RegisterCommand('dsn-status', function(source, args, rawCommand)
    if source ~= 0 and not Core.Player.IsAdmin(source) then return end
    
    print("\n^5====================================")
    print("    DJONSTNIX ECOSYSTEM STATUS")
    print("====================================^0")
    
    local framework = GetFramework()
    print(("^2- Framework :^7 %-20s [✓]"):format(framework))
    
    local f = Core.Features
    local caps = {}
    if f.hasInventory    then caps[#caps+1] = "Inv" end
    if f.hasTarget       then caps[#caps+1] = "Target" end
    if f.hasBanking      then caps[#caps+1] = "Bank" end
    if f.hasShops        then caps[#caps+1] = "Shops" end
    print(("^2- Features  :^7 %-20s"):format(table.concat(caps, ", ")))

    print("^5------------------------------------^0")
    
    local resources = {
        'DjonStNix-Bridge',
        'DjonStNix-Banking',
        GetStartedResource({'DjonStNix-economy', 'djonstnix-economy', 'DjonStNix-Economy'}) or 'DjonStNix-economy',
        'DjonStNix-Shops',
        'DjonStNix-Government',
        'DjonStNix-Launderer',
        GetStartedResource({'DjonStNix-vehicles', 'djonstnix-vehicles'}) or 'DjonStNix-vehicles'
    }
    
    for _, res in ipairs(resources) do
        local state = GetResourceState(res)
        local color = state == 'started' and '^2' or (state == 'missing' and '^1' or '^3')
        local sym = state == 'started' and '[✓]' or '[✗]'
        print(("^2- %-20s^7 %s%s^7"):format(res, color, sym))
    end
    
    print("^5====================================^0\n")
end, false)

RegisterCommand('dsn-audit', function(source, args, rawCommand)
    ExecuteCommand('dsn-status')
end, false)

RegisterCommand('dsn-test-framework', function(source, args, rawCommand)
    if source ~= 0 and not Core.Player.IsAdmin(source) then return end
    
    local targetId = tonumber(args[1]) or source
    if targetId == 0 then print("^1[Error]^7 Source 0 cannot test player functions.") return end
    
    print("^4--- Framework Logic Test ---^7")
    local cid = Core.Player.GetIdentifier(targetId)
    print(("^2- Identifier:^7 %s"):format(cid or "nil"))
    local bank = Core.Money.GetBalance(targetId, 'bank')
    print(("^2- Bank Balance:^7 $%s"):format(bank or "0"))
    print("^4----------------------------^7")
end, false)

-- ==================================================
-- LEGACY & COMPATIBILITY EXPORTS
-- ==================================================
--- Universal identifier retrieval for ecosystem scripts.
--- Usage: exports['DjonStNix-Bridge']:GetIdentifier(source)
exports('GetIdentifier', function(src)
    return Core.Player.GetIdentifier(src)
end)

exports('Notify', function(src, message, notifyType)
    if Core and Core.UI and Core.UI.Notify then
        Core.UI.Notify(src, message, notifyType)
        return true
    end
    return false
end)

exports('IsAdmin', function(src)
    if not src then return false end
    if Core and Core.Player then
        if Core.Player.IsAdmin and Core.Player.IsAdmin(src) then
            return true
        end
        if Core.Player.HasPermission and Core.Player.HasPermission(src, { 'admin', 'god', 'superadmin' }) then
            return true
        end
    end
    return false
end)

exports('IsPlayerAdmin', function(src)
    return exports['DjonStNix-Bridge']:IsAdmin(src)
end)
