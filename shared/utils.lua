Utils = {}

function Utils.TableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

function Utils.GetFormattedPrice(amount)
    local left, num, right = string.match(tostring(amount), '^([^%d]*%d)(%d*)(.-)$')
    return (Config.CurrencyPrefix or "$") .. left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.DeepCopy(orig_key)] = Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Retrieves the correct progressive tax rate based on the player's total liquid wealth
--- @param src number The player's server ID
--- @param fallbackRate number The static rate to use if Progressive Tax is disabled
--- @return number The calculated tax rate (e.g., 0.12)
--- @return number The player's total wealth calculated
function Utils.CalculateProgressiveTax(src, fallbackRate)
    local rate = fallbackRate or 0.0
    local totalWealth = 0
    
    if Config.Economy and Config.Economy.ProgressiveTax and Config.Economy.ProgressiveTax.Enabled then
        -- This function is only safe to run Server-Side because it requires Core.Money
        if IsDuplicityVersion() and Core and Core.Money then
            local cash = Core.Money.GetBalance(src, 'cash') or 0
            local bank = Core.Money.GetBalance(src, 'bank') or 0
            totalWealth = cash + bank
            
            -- Brackets are assumed to be sorted highest to lowest in config
            for i=1, #Config.Economy.ProgressiveTax.Brackets do
                local bracket = Config.Economy.ProgressiveTax.Brackets[i]
                if totalWealth >= bracket.minWealth then
                    rate = bracket.rate
                    break
                end
            end
        end
    end
    
    return rate, totalWealth
end

-- Attach utilities to core
if Core then
    for k, v in pairs(Utils) do
        Core.Utils[k] = v
    end
end
