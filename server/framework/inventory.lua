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

    -- --- QS INVENTORY ---
    elseif IsResourceRunning('qs-inventory') then
        Core.Items.AddItem = function(src, item, amount, metadata)
            return exports['qs-inventory']:AddItem(src, item, amount, metadata)
        end
        -- ... qs specific calls if needed
    end
end

InitializeInventory()
