-- ==========================================
-- DJONSTNIX-BRIDGE SCHEMA
-- ==========================================

CREATE TABLE IF NOT EXISTS `djonstnix_audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `resource` VARCHAR(50) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `user_id` VARCHAR(50) DEFAULT 'SYSTEM',
    `details` TEXT DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_resource` (`resource`),
    INDEX `idx_action` (`action`),
    INDEX `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
