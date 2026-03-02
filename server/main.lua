-- ==================================================
-- DjonStNix-Bridge MASTER SERVER ENTRY
-- ==================================================

CreateThread(function()
    print("^4" .. [[
  _____  _             ____       _     _               
 |  __ \(_)           |  _ \     (_)   | |              
 | |  | |_  ___  _ __ | |_) |_ __ _  __| | __ _  ___ 
 | |  | | |/ _ \| '_ \|  _ <| '__| |/ _` |/ _` |/ _ \
 | |__| | | (_) | | | | |_) | |  | | (_| | (_| |  __/
 |_____/| |\___/|_| |_|____/|_|  |_|\__,_|\__, |\___|
       _/ |                                __/ |      
      |__/                                |___/       
    ]] .. "^7")
    
    print(("^4[%s]^7 v%s — Initializing Master Architecture..."):format(Config.BrandName, Config.Version or "1.0.0"))
    
    local framework = GetFramework()
    print(("^4[%s]^7 Framework Detected: ^2%s^7"):format(Config.BrandName, framework))
    
    Wait(500)
    RefreshIntegrations()
    RefreshFeatures()

    -- Log detected capabilities
    local f = Core.Features
    local caps = {}
    if f.hasInventory    then caps[#caps+1] = "Inventory" end
    if f.hasTarget       then caps[#caps+1] = "Target" end
    if f.hasOxLib        then caps[#caps+1] = "ox_lib" end
    if f.hasBanking      then caps[#caps+1] = "Banking" end
    if f.hasShops        then caps[#caps+1] = "Shops" end
    if f.hasDispatch     then caps[#caps+1] = "Dispatch" end
    print(("^4[%s]^7 Feature Gates: ^2%s^7"):format(Config.BrandName, #caps > 0 and table.concat(caps, ", ") or "None"))
    
    Core.Ready = true
    print(("^2[DjonStNix-Bridge]^7 v%s — Core.Ready is now TRUE."):format(Config.Version or "1.0.0"))
end)
