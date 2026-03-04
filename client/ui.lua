-- ==================================================

-- ==================================================
-- DJONSTNIX CORE - UI WRAPPERS (CLIENT)
-- ==================================================

Core.UI = {}

-- --- NOTIFICATION ---
Core.UI.Notify = function(msg, type, duration)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = 'System',
            description = msg,
            type = type or 'info',
            duration = duration or 5000
        })
    elseif GetResourceState('qb-core') == 'started' then
        exports['qb-core']:GetCoreObject().Functions.Notify(msg, type or 'primary', duration)
    elseif GetResourceState('es_extended') == 'started' then
        exports['es_extended']:getSharedObject().ShowNotification(msg, type, duration)
    else
        TriggerEvent('chat:addMessage', { args = { "System", msg } })
    end
end

-- --- PROGRESS BAR ---
Core.UI.ProgressBar = function(name, label, duration, options, anim, prop, done, cancel)
    if GetResourceState('qb-core') == 'started' then
        exports['qb-core']:GetCoreObject().Functions.Progressbar(name, label, duration, options.useLib, options.canCancel, options.disable, anim or {}, prop or {}, {}, done, cancel)
    elseif GetResourceState('ox_lib') == 'started' then
        if exports.ox_lib:progressBar({
            duration = duration,
            label = label,
            useLib = options.useLib,
            canCancel = options.canCancel,
            disable = options.disable,
            anim = anim,
            prop = prop
        }) then
            if done then done() end
        else
            if cancel then cancel() end
        end
    else
        Wait(duration)
        if done then done() end
    end
end

-- --- CONTEXT MENU ---
Core.UI.ShowContextMenu = function(id, title, items)
    if GetResourceState('ox_lib') == 'started' then
        local options = {}
        for _, item in ipairs(items) do
            table.insert(options, {
                title = item.header,
                description = item.txt,
                icon = item.icon,
                onSelect = function()
                    if item.params and item.params.event then
                        TriggerEvent(item.params.event, item.params.args)
                    end
                end
            })
        end
        exports.ox_lib:registerContext({ id = id, title = title, options = options })
        exports.ox_lib:showContext(id)
    elseif GetResourceState('qb-menu') == 'started' then
        exports['qb-menu']:openMenu(items)
    end
end

-- --- INPUT DIALOG ---
Core.UI.Input = function(header, fields, cb)
    if GetResourceState('ox_lib') == 'started' then
        local rows = {}
        for _, field in ipairs(fields) do
            table.insert(rows, { type = 'input', label = field.text, placeholder = field.placeholder })
        end
        local input = exports.ox_lib:inputDialog(header, rows)
        if input and cb then cb(input) end
    elseif GetResourceState('qb-input') == 'started' then
        local input = exports['qb-input']:ShowInput({ header = header, submitText = "Submit", inputs = fields })
        if input and cb then cb(input) end
    end
end

-- --- ITEM IMAGES ---
Core.UI.GetItemImage = function(itemName)
    local image = itemName .. ".png"
    -- Attempt to get specialized image name from framework if available
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore.Shared.Items[itemName] and QBCore.Shared.Items[itemName].image then
            image = QBCore.Shared.Items[itemName].image
        end
    end

    if GetResourceState('ox_inventory') == 'started' then
        return "nui://ox_inventory/web/images/" .. image
    elseif GetResourceState('qb-inventory') == 'started' then
        return "nui://qb-inventory/html/images/" .. image
    elseif GetResourceState('ps-inventory') == 'started' then
        return "nui://ps-inventory/html/images/" .. image
    elseif GetResourceState('qs-inventory') == 'started' then
        return "nui://qs-inventory/html/img/items/" .. image
    end
    return "nui://qb-inventory/html/images/" .. image -- Final fallback
end
