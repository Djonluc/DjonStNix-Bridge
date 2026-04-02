-- server/migration.lua
-- Runs early in script startup to ensure schema structure is aligned.

MigrationsComplete = false

CreateThread(function()
    print("^3[DjonStNix-Bridge] ^7Checking Database Schema...")
    
    -- Ensure schema history table exists
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS djonstnix_bridge_schema_migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            version INT NOT NULL,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY (version)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    
    local currentDbVersion = tonumber(MySQL.Sync.fetchScalar('SELECT MAX(version) FROM djonstnix_bridge_schema_migrations')) or 0
    local targetVersion = 1

    if currentDbVersion < targetVersion then
        print("^3[DjonStNix-Bridge] ^7Updates available! Running incremental migrations (" .. currentDbVersion .. " -> " .. targetVersion .. ")")
        
        -- Migration 1: Initial Pillar Setup
        if currentDbVersion < 1 then
            MySQL.Sync.execute([[
                CREATE TABLE IF NOT EXISTS `djonstnix_audit_logs` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `resource` VARCHAR(50) NOT NULL,
                    `action` VARCHAR(100) NOT NULL,
                    `citizenid` VARCHAR(50) DEFAULT 'SYSTEM',
                    `details` TEXT DEFAULT NULL,
                    `metadata` JSON DEFAULT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX `idx_resource` (`resource`),
                    INDEX `idx_action` (`action`),
                    INDEX `idx_citizen` (`citizenid`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]])

            MySQL.Sync.execute('INSERT IGNORE INTO djonstnix_bridge_schema_migrations (version) VALUES (1)')
        end
        
        print("^2[DjonStNix-Bridge] ^7Migrations applied successfully.")
    end

    MigrationsComplete = true
end)
