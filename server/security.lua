-- ==================================================
-- DjonStNix-Bridge SECURITY ENGINE
-- Token bucket rate limiter, input validation,
-- secure event handler, and command registration.
-- ==================================================

local RateBuckets = {}

-- ==================================================
-- TOKEN BUCKET RATE LIMITER
-- ==================================================

local function EnsureBucket(src)
    if not RateBuckets[src] then
        local cfg = Config.Security.RateLimit or { Tokens = 10, RefillSeconds = 60 }
        RateBuckets[src] = {
            tokens = cfg.Tokens,
            maxTokens = cfg.Tokens,
            refillSeconds = cfg.RefillSeconds,
            lastRefill = os.time()
        }
    end
end

local function TakeToken(src, key)
    EnsureBucket(src)
    local bucket = RateBuckets[src]
    local now = os.time()
    local elapsed = now - bucket.lastRefill

    -- Refill tokens based on elapsed time
    if elapsed > 0 then
        local refill = math.floor(elapsed / bucket.refillSeconds)
        if refill > 0 then
            bucket.tokens = math.min(bucket.maxTokens, bucket.tokens + refill)
            bucket.lastRefill = now
        end
    end

    if bucket.tokens > 0 then
        bucket.tokens = bucket.tokens - 1
        return true
    end

    -- Rate limited — log if configured
    if Config.Security.LogSuspicious then
        Core.Log('security', ("Rate Limit Exceeded: Player %s (Event: %s) — 0 tokens remaining"):format(src, key or 'unknown'))
    end
    return false
end

--- Legacy-compatible RateLimit function (cooldown-based shortcut)
function RateLimit(src, key, cooldown)
    -- For backward compatibility with existing resources using the cooldown API
    if not RateBuckets[src] then RateBuckets[src] = {} end

    -- Use sub-buckets when called with a key + cooldown (legacy pattern)
    if key and cooldown then
        if not RateBuckets[src]._cooldowns then RateBuckets[src]._cooldowns = {} end
        local now = GetGameTimer()
        if RateBuckets[src]._cooldowns[key] and (now - RateBuckets[src]._cooldowns[key]) < cooldown then
            if Config.Security.LogSuspicious then
                Core.Log('security', ("Rate Limit Exceeded: Player %s (Event: %s)"):format(src, key))
            end
            return false
        end
        RateBuckets[src]._cooldowns[key] = now
        return true
    end

    -- Token bucket mode (no cooldown specified)
    return TakeToken(src, key)
end

-- ==================================================
-- INPUT VALIDATION HELPERS
-- ==================================================

function ValidateInput(value, expectedType, opts)
    if type(value) ~= expectedType then return false, "expected " .. expectedType end
    if expectedType == 'number' then
        if opts and opts.min and value < opts.min then return false, "below minimum" end
        if opts and opts.max and value > opts.max then return false, "above maximum" end
        if value ~= value then return false, "NaN" end -- NaN check
    end
    if expectedType == 'string' then
        if opts and opts.maxLen and #value > opts.maxLen then return false, "too long" end
        if opts and opts.minLen and #value < opts.minLen then return false, "too short" end
    end
    return true
end

-- ==================================================
-- SECURE EVENT HANDLER WRAPPER
-- ==================================================

function SecureHandler(fn, opts)
    opts = opts or {}
    return function(...)
        local src = source
        if not src or src == 0 then
            Core.Log('security', "Blocked non-player source on secure handler")
            return false, "invalid source"
        end

        -- Token bucket check
        if not TakeToken(src, opts.name or 'secure') then
            return false, "rate limited"
        end

        -- Execute handler in protected call
        local ok, result = pcall(fn, src, ...)
        if not ok then
            Core.Log('security', ("SecureHandler error for player %s: %s"):format(src, tostring(result)))
            return false, "handler error"
        end

        return result
    end
end

-- Cleanup disconnected players
AddEventHandler('playerDropped', function()
    local src = source
    RateBuckets[src] = nil
end)

-- ==================================================
-- SECURE SERVER EVENT (Convenience Wrapper)
-- ==================================================
-- Usage: SecureServerEvent('myEvent', function(src, ...) end)
-- Combines RegisterNetEvent + SecureHandler in one call.

function SecureServerEvent(eventName, handler, opts)
    opts = opts or {}
    opts.name = opts.name or eventName
    RegisterNetEvent(eventName, SecureHandler(handler, opts))
end

-- ==================================================
-- VALIDATION HELPERS (NUI/Client Input)
-- ==================================================

Core.Validation = {}

--- Validate a string value with min/max length
function Core.Validation.String(value, minLen, maxLen)
    minLen = minLen or 1
    maxLen = maxLen or 64
    if type(value) ~= 'string' then return false, "Expected string" end
    if #value < minLen then return false, "String too short (min " .. minLen .. ")" end
    if #value > maxLen then return false, "String too long (max " .. maxLen .. ")" end
    return true
end

--- Validate a numeric value with min/max range
function Core.Validation.Number(value, min, max)
    min = min or 1
    max = max or 999999999
    local n = tonumber(value)
    if not n then return false, "Expected number" end
    if n ~= n then return false, "NaN" end
    if n < min then return false, "Below minimum (" .. min .. ")" end
    if n > max then return false, "Above maximum (" .. max .. ")" end
    return true
end

--- Validate a player exists by server ID
function Core.Validation.PlayerExists(serverId)
    local sid = tonumber(serverId)
    if not sid or sid <= 0 then return false, "Invalid server ID" end
    local name = GetPlayerName(sid)
    if not name then return false, "Player not found" end
    return true
end

--- Validate a citizenid exists in the database
function Core.Validation.CitizenExists(citizenid)
    if type(citizenid) ~= 'string' or #citizenid < 1 then return false, "Invalid citizenid" end
    local rows = MySQL.query.await('SELECT citizenid FROM players WHERE citizenid = ? LIMIT 1', {citizenid})
    return rows and #rows > 0, rows and #rows > 0 and nil or "Citizen not found"
end

-- ==================================================
-- STRUCTURED ERROR LOGGING
-- ==================================================

Core.Logging = Core.Logging or {}

function Core.Logging.Error(system, message, context)
    local ctx = ""
    if context and type(context) == 'table' then
        local parts = {}
        for k, v in pairs(context) do
            parts[#parts + 1] = k .. "=" .. tostring(v)
        end
        ctx = " | " .. table.concat(parts, ", ")
    end
    local line = ("^1[%s ERROR]^7 %s%s"):format(system, message, ctx)
    print(line)
    if Core.Log then
        Core.Log('error', ("[%s] %s%s"):format(system, message, ctx))
    end
end

-- ==================================================
-- FRAMEWORK COMMAND REGISTRATION
-- ==================================================

function InternalRegisterCommand(name, permission, cb, help, params)
    local framework = GetFramework()
    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if type(permission) == 'table' then
            QBCore.Commands.Add(name, help or "No Description", params or {}, false, cb, table.unpack(permission))
        else
            QBCore.Commands.Add(name, help or "No Description", params or {}, false, cb, permission or "admin")
        end
    elseif framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        ESX.RegisterCommand(name, permission or "admin", cb, true, {help = help, arguments = params})
    else
        RegisterCommand(name, function(source, args, rawCommand)
            if source == 0 or RequirePermission(source, permission) then
                cb(source, args, rawCommand)
            end
        end, false)
    end
end

-- ==================================================
-- ASSEMBLE SECURITY API
-- ==================================================

Core.Security.RateLimit = RateLimit
Core.Security.TakeToken = TakeToken
Core.Security.ValidateInput = ValidateInput
Core.Security.SecureHandler = SecureHandler
Core.Security.SecureServerEvent = SecureServerEvent
Core.Security.RegisterCommand = InternalRegisterCommand
