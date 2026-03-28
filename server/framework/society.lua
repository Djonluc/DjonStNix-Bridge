local function InitializeSocietyHelpers()
    -- Use global Core

    local function ResolveFallbackAccount(jobOrAccount)
        if not jobOrAccount then return nil end
        local normalized = tostring(jobOrAccount)
        if string.sub(string.lower(normalized), 1, 8) == 'society_' then
            normalized = string.sub(normalized, 9)
        end
        return normalized
    end

    Core.Society.GetSocietyAccount = function(jobOrAccount)
        if IsResourceRunning('DjonStNix-Banking') then
            return exports['DjonStNix-Banking']:GetSocietyAccount(jobOrAccount)
        end
        return ResolveFallbackAccount(jobOrAccount)
    end

    Core.Society.AddSocietyMoney = function(jobOrAccount, amount, reason)
        local account = Core.Society.GetSocietyAccount(jobOrAccount)
        if IsResourceRunning('DjonStNix-Banking') then
            return exports['DjonStNix-Banking']:AddSocietyMoney(account, amount, reason)
        end

        if GetFramework() == 'qb' and GetResourceState('qb-management') == 'started' then
            exports['qb-management']:AddMoney(account, amount)
            return true
        elseif GetFramework() == 'esx' then
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. account, function(acc)
                if acc then
                    acc.addMoney(amount)
                end
            end)
            return true
        end

        return false, "No society backend available"
    end

    Core.Society.RemoveSocietyMoney = function(jobOrAccount, amount, reason)
        local account = Core.Society.GetSocietyAccount(jobOrAccount)
        if IsResourceRunning('DjonStNix-Banking') then
            return exports['DjonStNix-Banking']:RemoveSocietyMoney(account, amount, reason)
        end

        if GetFramework() == 'qb' and GetResourceState('qb-management') == 'started' then
            exports['qb-management']:RemoveMoney(account, amount)
            return true
        elseif GetFramework() == 'esx' then
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. account, function(acc)
                if acc then
                    acc.removeMoney(amount)
                end
            end)
            return true
        end

        return false, "No society backend available"
    end

    Core.Society.GetSocietyMoney = function(jobOrAccount)
        local account = Core.Society.GetSocietyAccount(jobOrAccount)
        if IsResourceRunning('DjonStNix-Banking') then
            return exports['DjonStNix-Banking']:GetSocietyMoney(account)
        end

        if GetFramework() == 'qb' and GetResourceState('qb-management') == 'started' then
            local ok, balance = pcall(function()
                return exports['qb-management']:GetAccount(account)
            end)
            if ok then
                if type(balance) == 'table' then
                    return balance.money or balance.balance or 0
                end
                return balance or 0
            end
        end

        return 0
    end
end

InitializeSocietyHelpers()
