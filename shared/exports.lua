Core = {}
EventBus = {}

-- ==================================================
-- INTERNAL EVENT BUS
-- ==================================================

function EventBus.Emit(eventName, payload)
    TriggerEvent('DjonStNix-Bridge:internal:' .. eventName, payload)
end

function EventBus.On(eventName, handler)
    AddEventHandler('DjonStNix-Bridge:internal:' .. eventName, function(payload)
        handler(payload)
    end)
end

-- ==================================================
-- MASTER CORE API OBJECT (V2.1 Standard)
-- ==================================================

function InitializeCore()
    -- These will be populated by server/framework files
    Core.Player = {}
    Core.Money = {}
    Core.Items = {}
    Core.Vehicle = {}
    Core.Society = {}
    Core.Government = {}
    Core.Security = {}
    Core.Logging = {}
    Core.Registry = {}
    Core.Plugins = {}
    Core.Phone = {}
    Core.Utils = {}
    Core.UI = {
        Notify = function(src, msg, type) 
            if src == -1 then
                TriggerClientEvent('DjonStNix-Bridge:client:Notify', -1, msg, type)
            else
                TriggerClientEvent('DjonStNix-Bridge:client:Notify', src, msg, type)
            end
        end,
        Broadcast = function(msg, type)
            TriggerClientEvent('DjonStNix-Bridge:client:Notify', -1, msg, type)
        end
    }
    Core.Functions = {}
    Core.Ready = false
    
    -- [[ Shared API Bindings ]] --
    Core.IsResourceRunning = function(name) return GetResourceState(name) == 'started' end
    Core.Emit = EventBus.Emit
    Core.On = EventBus.On

    -- [[ Late-Binding Ecosystem Hooks ]] --
    -- This ensures that if Government or Economy start LATER, the Core can still route to them.
    local function ResolveStartedResource(candidates)
        for _, resourceName in ipairs(candidates) do
            if Core.IsResourceRunning(resourceName) then
                return resourceName
            end
        end
        return nil
    end

    Core.GetEconomy = function()
        local resourceName = ResolveStartedResource({
            'DjonStNix-economy',
            'djonstnix-economy',
            'DjonStNix-Economy'
        })
        return resourceName and exports[resourceName] or nil
    end
    Core.GetGovernment = function() return Core.IsResourceRunning('DjonStNix-Government') and exports['DjonStNix-Government'] or nil end
    Core.GetBanking = function() return Core.IsResourceRunning('DjonStNix-Banking') and exports['DjonStNix-Banking'] or nil end

    -- [[ ITEM IMAGE RESOLUTION (Universal) ]] --
    Core.Items.GetImagePath = function(itemName)
        if not itemName then return "" end
        
        local inv = Config.Inventory or 'auto'
        local path = ""

        if inv == 'auto' then
            if GetResourceState('ox_inventory') == 'started' then inv = 'ox'
            elseif GetResourceState('qb-inventory') == 'started' then inv = 'qb'
            elseif GetResourceState('qs-inventory') == 'started' then inv = 'qs'
            else inv = 'standalone' end
        end

        if inv == 'ox' then
            path = "nui://ox_inventory/web/images/%s.png"
        elseif inv == 'qb' then
            path = "nui://qb-inventory/html/images/%s.png"
        elseif inv == 'qs' then
            path = "nui://qs-inventory/html/img/items/%s.png"
        elseif inv == 'esx' then
            path = "nui://inventory/html/img/items/%s.png"
        elseif Core.Items and Core.Items.ImageBasePath then
            path = Core.Items.ImageBasePath .. "%s.png"
        else
            return ""
        end
        
        return string.format(path, itemName)
    end

    -- SDK Extensions
    Core.Utils.PrintBanner = function(resource, version)
        print("^5================================================^0")
        print("^3  👑 DJONSTNIX ECOSYSTEM^0")
        print("^5================================================^0")
        print("^2  Resource : ^7" .. (resource or GetCurrentResourceName()))
        print("^2  Version  : ^7" .. (version or "1.0.0"))
        print("^2  Author   : ^7DjonLuc (@DjonStNix)")
        print("^5================================================^0")
    end

    Core.Plugins.Register = function(name, pluginTable)
        if not name or not pluginTable then return false end
        Core.Registry.Plugins = Core.Registry.Plugins or {}
        Core.Registry.Plugins[name] = pluginTable
        print(("^2[DjonStNix-Bridge]^7 Plugin Registered: ^3%s^7 (v%s)"):format(name, pluginTable.version or "1.0"))
        
        Core.Emit('bridge:plugin:registered', { name = name, version = pluginTable.version })
        return true
    end

    -- [[ RECEIPT VALIDATION & PERSISTENCE ]] --
    Core.Utils.ValidateReceipt = function(receipt)
        if type(receipt) ~= "table" then return false, "Invalid receipt format" end
        
        -- Essential Fields Check
        local required = { "source", "items", "total" }
        for _, field in ipairs(required) do
            if not receipt[field] then return false, "Missing required field: " .. field end
        end

        -- Ensure items is a table
        if type(receipt.items) ~= "table" then return false, "Items must be a table" end

        -- Integrity Check: Sum of items vs Total
        local calculatedSubtotal = 0
        for _, item in ipairs(receipt.items) do
            calculatedSubtotal = calculatedSubtotal + (tonumber(item.total) or 0)
        end

        -- If receipt has a subtotal, verify it
        if receipt.subtotal and math.abs(receipt.subtotal - calculatedSubtotal) > 1 then
            Utils.LogDebug(("[Receipt Warning] Subtotal mismatch: Got %s, Calculated %s"):format(receipt.subtotal, calculatedSubtotal))
        end
        receipt.subtotal = calculatedSubtotal

        -- Auto-calculate total if missing (subtotal + tax)
        if not receipt.total or receipt.total == 0 then
            receipt.total = receipt.subtotal + (tonumber(receipt.tax) or 0)
        end

        -- Auto-fill date if missing
        if not receipt.date then
            receipt.date = os.date("%Y-%m-%d %H:%M:%S")
        end

        return true, receipt
    end

    --- Advanced Helper: Automatically builds a receipt object with totals/taxes
    --- @param data table { items = {}, taxRate = nil, source = "My Shop" }
    Core.Money.CreateReceipt = function(data)
        if not data then return nil end
        
        local subtotal = 0
        local items = {}
        local rawItems = data.items or {}

        -- Handle Single Item shorthand: { item = "Name", price = 100 }
        if data.item and data.price then
            rawItems = { { name = data.item, unitPrice = data.price, quantity = 1 } }
        end
        
        for _, item in ipairs(rawItems) do
            local unitPrice = tonumber(item.unitPrice or item.price or 0)
            local quantity = tonumber(item.quantity or item.amount or 1)
            local lineTotal = math.floor(unitPrice * quantity)
            
            subtotal = subtotal + lineTotal
            table.insert(items, {
                name = item.name or "Item",
                quantity = quantity,
                unitPrice = unitPrice,
                total = lineTotal
            })
        end

        local taxRate = data.taxRate or Config.SalesTax or 0.05
        local taxAmount = math.floor(subtotal * taxRate)
        local totalCharge = subtotal + taxAmount

        return {
            source = data.source or "Unknown Transaction",
            items = items,
            subtotal = subtotal,
            tax = taxAmount,
            total = totalCharge,
            taxRate = taxRate,
            date = os.date("%Y-%m-%d %H:%M:%S")
        }
    end

    --- NEW Standardized entry point for all bank transactions
    --- @param src number Player source
    --- @param payload table Either a full receipt or minimal { source, items }
    Core.Money.ProcessBankTransaction = function(src, payload)
        if not src or not payload then return false end
        
        -- If it looks like a minimal payload (no total or no subtotal), build it
        local receipt = payload
        if not payload.total or not payload.subtotal or not payload.date then
            receipt = Core.Money.CreateReceipt(payload)
        end

        if not receipt then return false end

        local finalMetadata = {
            reason = receipt.source or "Purchase",
            store = receipt.source or "General Purchase",
            receipt = receipt
        }

        return Core.Money.RemoveMoney(src, 'bank', receipt.total, finalMetadata.reason, finalMetadata)
    end

    --- Standardized entry point for and Charging Bank Accounts with Receipts (Alias for ProcessBankTransaction)
    Core.Money.ChargeBankAccount = function(src, amount, reason, receiptData)
        -- If receiptData is missing, use amount/reason to build a fallback
        if not receiptData then
            receiptData = {
                source = reason or "General Purchase",
                item = reason or "General Purchase",
                price = amount
            }
        end
        
        -- Ensure source is set for the receipt builder
        if not receiptData.source then receiptData.source = reason end

        return Core.Money.ProcessBankTransaction(src, receiptData)
    end

    --- Centralized entry point for logging transactions (Legacy Support)
    Core.Money.LogBankTransaction = function(src, account, amount, reason, receiptData)
        if account == 'bank' then
            return Core.Money.ChargeBankAccount(src, amount, reason, receiptData)
        end
        return Core.Money.RemoveMoney(src, account, amount, reason, { receipt = receiptData })
    end
    
    return Core
end

exports('GetCore', function()
    while not Core.Ready do Wait(100) end
    return Core
end)

exports('Emit', function(eventName, payload)
    EventBus.Emit(eventName, payload)
end)

exports('On', function(eventName, handler)
    EventBus.On(eventName, handler)
end)

--- Global broadcast which triggers both server-side and client-side (to all)
exports('BroadcastEvent', function(eventName, payload)
    EventBus.Emit(eventName, payload)
    TriggerClientEvent('DjonStNix-Bridge:client:internal:Broadcast', -1, eventName, payload)
end)

--- Standardized Receipt Logging Export for third-party developers
exports('LogBankTransaction', function(src, amount, account, reason, receiptData)
    return Core.Money.LogBankTransaction(src, account, amount, reason, receiptData)
end)

--- EXCLUSIVE INTERFACE: Process Bank Transaction (Unified)
exports('ProcessBankTransaction', function(src, payload)
    return Core.Money.ProcessBankTransaction(src, payload)
end)

--- EXCLUSIVE INTERFACE: Charge Bank Account with Receipt (Legacy Support)
exports('ChargeBankAccount', function(src, amount, reason, receiptData)
    return Core.Money.ChargeBankAccount(src, amount, reason, receiptData)
end)

--- HELPER: Create standard receipt object
exports('CreateReceipt', function(data)
    return Core.Money.CreateReceipt(data)
end)

-- Initialize Core immediately
InitializeCore()
