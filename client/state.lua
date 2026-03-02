-- ==================================================
-- DjonStNix-Bridge CLIENT STATE HANDLER
-- ==================================================

-- Syncing crucial states to entity state bags for performance/OneSync parity
function SetPlayerState(key, value)
    LocalPlayer.state:set(key, value, true)
end

function GetPlayerState(key)
    return LocalPlayer.state[key]
end

-- Export for scripts
Core.SetState = SetPlayerState
Core.GetState = GetPlayerState
