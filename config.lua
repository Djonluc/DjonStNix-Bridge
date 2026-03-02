Config = {}

-- ==================================================
-- DjonStNix-Bridge MASTER CONFIGURATION
-- ==================================================

Config.Debug = false
Config.Version = "1.0.0"
Config.BrandName = "DjonStNix"
Config.CurrencyPrefix = "$"

-- Framework Settings
-- Options: "auto", "qb", "qbox", "esx", "standalone"
Config.Framework = "auto"

-- Inventory Settings
-- Options: "auto", "ox", "qb", "qs", "standalone"
Config.Inventory = "auto"

-- Target Settings
-- Options: "auto", "ox", "qb", "none"
Config.Target = "auto"

-- Logging Settings
Config.Logging = {
    Enable = true,
    DiscordWebhook = false, -- Set to your webhook URL
    Database = true,        -- Log to djon_audit_logs table
    Console = true          -- Log to server console
}

-- Security Settings
Config.Security = {
    DefaultMaxDistance = 5.0,    -- Default distance for interaction checks
    RateLimitCooldown = 1000,   -- Default cooldown in ms for legacy events
    LogSuspicious = true,       -- Log potential exploit attempts

    -- Token Bucket Rate Limiter (advanced)
    RateLimit = {
        Tokens = 10,            -- Max tokens per player
        RefillSeconds = 60,     -- Seconds to refill one token
    },

    -- Permission roles treated as admin
    PermissionRoles = { "admin", "superadmin", "god" },
}

-- Branding
Config.Prefix = "^4[DjonStNix-Bridge]^7"
Config.NotificationIcon = "fas fa-shield-alt"
