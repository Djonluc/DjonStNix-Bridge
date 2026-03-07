local function InitializeInventory()
    -- Use global Core

    -- --- OX INVENTORY ---
    if IsResourceRunning('ox_inventory') then
        Core.Items.AddItem = function(src, item, amount, metadata)
            return exports.ox_inventory:AddItem(src, item, amount, metadata)
        end
        Core.Items.RemoveItem = function(src, item, amount)
            return exports.ox_inventory:RemoveItem(src, item, amount)
        end
        Core.Items.HasItem = function(src, item)
            return exports.ox_inventory:GetItemCount(src, item) >= 1
        end
        Core.Items.GetItemData = function(src, item, metadata)
            return exports.ox_inventory:GetItem(src, item, metadata)
        end
        Core.Items.GetItemsByType = function(src, type)
            return exports.ox_inventory:GetSlotsWithItem(src, type)
        end
        Core.Items.GetItemCount = function(src, item)
            return exports.ox_inventory:GetItemCount(src, item)
        end
        Core.Items.GetImagePath = function(itemName)
            return ('nui://ox_inventory/web/images/%s.png'):format(itemName)
        end
        Core.Items.GetItemLabel = function(itemName)
            local items = exports.ox_inventory:Items()
            if items and items[itemName] then return items[itemName].label end
            return nil
        end
        Core.Items.ImageBasePath = 'nui://ox_inventory/web/images/'

    -- --- QB INVENTORY ---
    elseif IsResourceRunning('qb-inventory') then
        local QBCore = exports['qb-core']:GetCoreObject()
        Core.Items.AddItem = function(src, item, amount, metadata)
            return exports['qb-inventory']:AddItem(src, item, amount, nil, metadata)
        end
        Core.Items.RemoveItem = function(src, item, amount)
            return exports['qb-inventory']:RemoveItem(src, item, amount)
        end
        Core.Items.HasItem = function(src, item)
            return exports['qb-inventory']:HasItem(src, item, 1)
        end
        Core.Items.GetItemData = function(src, item)
            local player = QBCore.Functions.GetPlayer(src)
            return player and player.Functions.GetItemByName(item) or nil
        end
        Core.Items.GetItemsByType = function(src, itemType)
            local player = QBCore.Functions.GetPlayer(src)
            if not player then return {} end
            local items = {}
            for _, item in pairs(player.PlayerData.items) do
                if item.type == itemType or item.name == itemType then
                    table.insert(items, item)
                end
            end
            return items
        end
        Core.Items.GetItemCount = function(src, item)
            local player = QBCore.Functions.GetPlayer(src)
            if not player then return 0 end
            local itemData = player.Functions.GetItemByName(item)
            return itemData and itemData.amount or 0
        end
        Core.Items.GetImagePath = function(itemName)
            return ('nui://qb-inventory/html/images/%s.png'):format(itemName)
        end
        Core.Items.GetItemLabel = function(itemName)
            local shared = QBCore.Shared.Items[itemName]
            if shared then return shared.label end
            return nil
        end
        Core.Items.ImageBasePath = 'nui://qb-inventory/html/images/'

    -- --- QS INVENTORY ---
    elseif IsResourceRunning('qs-inventory') then
        Core.Items.AddItem = function(src, item, amount, metadata)
            return exports['qs-inventory']:AddItem(src, item, amount, metadata)
        end
        Core.Items.GetImagePath = function(itemName)
            return ('nui://qs-inventory/html/images/%s.png'):format(itemName)
        end
        Core.Items.GetItemLabel = function(itemName) return nil end
        Core.Items.ImageBasePath = 'nui://qs-inventory/html/images/'
    end

    -- Fallback if no function was assigned
    if not Core.Items.GetImagePath then
        Core.Items.GetImagePath = function(itemName)
            return ('nui://qb-inventory/html/images/%s.png'):format(itemName)
        end
        Core.Items.ImageBasePath = 'nui://qb-inventory/html/images/'
    end
    if not Core.Items.GetItemLabel then
        Core.Items.GetItemLabel = function(itemName) 
            -- Try to derive a clean label from the name as a last resort
            if not itemName then return "Unknown Item" end
            local label = itemName:gsub("_", " "):gsub("^%l", string.upper)
            return label
        end
    end
    -- --- GLOBAL NOTIFICATION HELPERS ---
    Core.Items.NotifyReceived = function(src, item, amount)
        if IsResourceRunning('ox_inventory') then
            TriggerClientEvent('ox_inventory:itemNotify', src, {item = item, amount = amount, type = 'add'})
        elseif IsResourceRunning('qb-inventory') then
            local QBCore = exports['qb-core']:GetCoreObject()
            local itemData = QBCore.Shared.Items[item]
            if itemData then
                TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'add', amount)
            end
        end
    end
end

InitializeInventory()

