-- ==============================================================================
-- 👑 DJONSTNIX BRANDING
-- ==============================================================================
-- DEVELOPED BY: DjonStNix (DjonLuc)
-- GITHUB: https://github.com/Djonluc
-- DISCORD: https://discord.gg/s7GPUHWrS7
-- YOUTUBE: https://www.youtube.com/@Djonluc
-- EMAIL: djonstnix@gmail.com
-- LICENSE: MIT License (c) 2026 DjonStNix (DjonLuc)
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

description 'DjonStNix - Central Bridge & Security Resource'
author 'DjonStNix (DjonLuc)'
version '1.0.0'
repository 'https://github.com/Djonluc/DjonStNix-Bridge'

shared_scripts {
    'config.lua',
    'shared/exports.lua',
    'shared/utils.lua',
    'shared/framework_detect.lua',
    'shared/integration_detect.lua'
}

server_scripts {
    'server/framework/qb.lua',
    'server/framework/qbox.lua',
    'server/framework/esx.lua',
    'server/framework/standalone.lua',
    'server/framework/inventory.lua',
    'server/framework/vehicle.lua',
    'server/framework/society.lua',
    'server/security.lua',
    'server/logging.lua',
    'server/permissions.lua',
    'server/features.lua',
    'server/testing.lua',
    'server/main.lua'
}

client_scripts {
    'client/framework.lua',
    'client/notify.lua',
    'client/ui.lua',
    'client/state.lua',
    'client/main.lua'
}

lua54 'yes'

exports {
    'GetCore',
    'GetCoreObject',
    'GetFrameworkObject',
    'GetFeatures',
    'Notify',
    'IsAdmin',
    'IsPlayerAdmin',
    'SecureHandler',
    'ValidateInput',
    'GetIdentifier',
    'Emit',
    'On',
    'BroadcastEvent',
    'LogBankTransaction',
    'ProcessBankTransaction',
    'ChargeBankAccount',
    'CreateReceipt'
}
