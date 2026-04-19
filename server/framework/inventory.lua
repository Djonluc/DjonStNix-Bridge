local function InitializeInventory()
    -- Use global Core

    -- --- OX INVENTORY ---
    if IsResourceRunning('ox_inventory') then
        local ox = exports.ox_inventory
        Core.Items.AddItem = function(src, item, amount, metadata, extraMetadata)
            if extraMetadata ~= nil and metadata == nil then metadata = extraMetadata end
            return ox:AddItem(src, item, amount, metadata)
        end
        Core.Items.RemoveItem = function(src, item, amount)
            return ox:RemoveItem(src, item, amount)
        end
        Core.Items.HasItem = function(src, item)
            -- Support both legacy and modern versions
            local count = 0
            if ox.GetItemCount then
                count = ox:GetItemCount(src, item)
            else
                count = ox:GetItem(src, item, nil, true)
            end
            return count and count >= 1 or false
        end
        Core.Items.GetItemData = function(src, item, metadata)
            return ox:GetItem(src, item, metadata)
        end
        Core.Items.GetItemsByType = function(src, type)
            if ox.GetSlotsWithItem then
                return ox:GetSlotsWithItem(src, type) or {}
            end
            return ox:Search(src, 'slots', type) or {}
        end
        Core.Items.GetItemCount = function(src, item)
            if ox.GetItemCount then
                return ox:GetItemCount(src, item) or 0
            end
            return ox:GetItem(src, item, nil, true) or 0
        end
        Core.Items.GetItemLabel = function(itemName)
            local item = ox:Items(itemName)
            return item and item.label or nil
        end
        Core.Items.GetInventory = function(src)
            return ox:GetInventoryItems(src)
        end
        Core.Items.ImageBasePath = 'nui://ox_inventory/web/images/'

    -- --- QB INVENTORY ---
    elseif IsResourceRunning('qb-inventory') then
        local QBCore = exports['qb-core']:GetCoreObject()
        Core.Items.AddItem = function(src, item, amount, metadata, extraMetadata)
            if extraMetadata ~= nil and metadata == nil then metadata = extraMetadata end
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
        Core.Items.GetItemLabel = function(itemName)
            local shared = QBCore.Shared.Items[itemName]
            if shared then return shared.label end
            return nil
        end
        Core.Items.GetInventory = function(src)
            local player = QBCore.Functions.GetPlayer(src)
            return player and player.PlayerData.items or {}
        end
        Core.Items.ImageBasePath = 'nui://qb-inventory/html/images/'

    -- --- QS INVENTORY ---
    elseif IsResourceRunning('qs-inventory') then
        local function GetQSInventory(src)
            local ok, inventory = pcall(function()
                return exports['qs-inventory']:GetUserInventory(src)
            end)
            return ok and inventory or {}
        end

        local function GetQSItemCount(src, itemName)
            local total = 0
            local inventory = GetQSInventory(src)
            for _, entry in pairs(inventory or {}) do
                if type(entry) == 'table' then
                    local entryName = entry.name or entry.item or entry.itemName
                    if entryName == itemName then
                        total = total + (tonumber(entry.amount or entry.count or entry.quantity) or 0)
                    end
                end
            end
            return total
        end

        Core.Items.AddItem = function(src, item, amount, metadata, extraMetadata)
            if extraMetadata ~= nil and metadata == nil then metadata = extraMetadata end
            return exports['qs-inventory']:AddItem(src, item, amount, metadata)
        end
        Core.Items.RemoveItem = function(src, item, amount, metadata)
            local ok, result = pcall(function()
                return exports['qs-inventory']:RemoveItem(src, item, amount, metadata)
            end)
            return ok and result or false
        end
        Core.Items.HasItem = function(src, item)
            return GetQSItemCount(src, item) >= 1
        end
        Core.Items.GetItemCount = function(src, item)
            return GetQSItemCount(src, item)
        end
        Core.Items.GetItemLabel = function(itemName) return nil end
        Core.Items.GetInventory = function(src)
            return GetQSInventory(src)
        end
        Core.Items.ImageBasePath = 'nui://qs-inventory/html/img/items/'
    end

    -- (Shared Fallback is now handled in shared/exports.lua)
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

