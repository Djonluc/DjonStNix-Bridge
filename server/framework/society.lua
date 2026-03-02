local function InitializeSocietyHelpers()
    -- Use global Core

    Core.Society.GetSocietyAccount = function(job)
        return "society_" .. job
    end

    Core.Society.AddSocietyMoney = function(job, amount)
        local account = Core.Society.GetSocietyAccount(job)
        -- Check if DjonStNix-Banking is running for society handling
        if IsResourceRunning('DjonStNix-Banking') then
            return exports['DjonStNix-Banking']:AddSocietyMoney(job, amount)
        else
            -- Fallback to standard management patterns
            if GetFramework() == 'qb' then
                exports['qb-management']:AddMoney(job, amount)
            elseif GetFramework() == 'esx' then
                TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
                    acc.addMoney(amount)
                end)
            end
            return true
        end
    end

    -- ... RemoveSocietyMoney etc.
end

InitializeSocietyHelpers()
