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

-- Economy Settings (Universal)
Config.Economy = {
    -- Progressive Taxation System
    -- Scans a player's total liquid wealth (cash + bank) to determine their tax bracket.
    ProgressiveTax = {
        Enabled = true,        -- If true, overrides static tax rates in other scripts
        Brackets = {
            { minWealth = 250000000, rate = 0.15 }, -- $2.5M+: 15% Tax (Ultra-Wealthy)
            { minWealth = 50000000,  rate = 0.12 }, -- $500k+: 12% Tax
            { minWealth = 20000000,  rate = 0.08 }, -- $200k+: 8% Tax
            { minWealth = 0,         rate = 0.05 }  -- $0+: 5% Tax (Base/Poverty)
        }
    }
}

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
