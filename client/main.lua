-- ==================================================
-- DjonStNix-Bridge CLIENT INITIALIZATION
-- ==================================================

-- local Core is already initialized in shared/exports.lua as a global

-- Wait for framework module to finish mapping
while not Core.FrameworkReady do Wait(10) end

-- Signal that client-side bridge is ready
Core.Ready = true

print("^4[DjonStNix-Bridge]^7 Client-Side Core Ready. (Ready Flag: " .. tostring(Core.Ready) .. ")")
