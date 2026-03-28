-- server/testing.lua
-- Universal Testing Framework (UTF) for the DjonStNix Ecosystem
-- Provides diagnostic commands and cross-resource verification logic.

local RegisteredTests = {
    individual = {},
    integration = {}
}

---
--- Registers a test for the DjonStNix Diagnostic system
--- @param resource string Name of the resource
--- @param type string 'individual' or 'integration'
--- @param testFn function The function to execute. Must return (bool success, string message)
---
exports('RegisterTest', function(resource, type, testFn)
    if not RegisteredTests[type] then RegisteredTests[type] = {} end
    table.insert(RegisteredTests[type], {
        resource = resource,
        fn = testFn
    })
    print(("^2[DjonStNix-Bridge] ^7Registered %s test for resource: ^5%s^7"):format(type, resource))
end)

local function RunDiagnostics(source)
    local src = source
    local results = {
        passed = 0,
        failed = 0,
        logs = {}
    }

    local function Log(status, resource, msg)
        local color = status == 'PASS' and "^2" or "^1"
        local entry = ("[%s] %s: %s"):format(status, resource, msg)
        table.insert(results.logs, entry)
        print(color .. entry .. "^7")
        if status == 'PASS' then results.passed = results.passed + 1 else results.failed = results.failed + 1 end
    end

    print("^3[DjonStNix] Starting Global Ecosystem Diagnostics...^7")
    print("--------------------------------------------------")

    -- Phase 1: Core Dependency Check
    local bridgeVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or "Unknown"
    Log('PASS', 'Bridge', "Version " .. bridgeVersion .. " detected.")

    local dependencies = { 'oxmysql', 'qb-core', 'ox_inventory' }
    for _, dep in ipairs(dependencies) do
        local state = GetResourceState(dep)
        if state == 'started' then
            Log('PASS', 'Dep', dep .. " is active.")
        elseif state == 'missing' then
            Log('FAIL', 'Dep', dep .. " is MISSING (CRITICAL).")
        else
            Log('WARN', 'Dep', dep .. " is " .. state .. ".")
        end
    end

    -- Check for DSN Resource Integrity
    local dsnResources = {
        'DjonStNix-Banking',
        'DjonStNix-Shops',
        GetResourceState('DjonStNix-economy') == 'started' and 'DjonStNix-economy' or 'djonstnix-economy'
    }
    print("^5[DSN Ecosystem Integrity]^7")
    for _, res in ipairs(dsnResources) do
        if GetResourceState(res) == 'started' then
            Log('PASS', 'DSN', res .. " is running.")
        else
            Log('FAIL', 'DSN', res .. " is NOT running.")
        end
    end

    -- Phase 2: Individual Resource Tests
    print("^5[Individual Tests]^7")
    for _, test in ipairs(RegisteredTests.individual) do
        local success, msg = pcall(test.fn)
        if success then
            local testSuccess, testMsg = test.fn() -- fn is expected to be safe but pcall handles crashes
            if testSuccess then
                Log('PASS', test.resource, testMsg or "Module Healthy")
            else
                Log('FAIL', test.resource, testMsg or "Test Failed")
            end
        else
            Log('FAIL', test.resource, "Test crashed: " .. tostring(msg))
        end
    end

    -- Phase 3: Integration Tests
    print("^5[Integration Tests]^7")
    for _, test in ipairs(RegisteredTests.integration) do
        local success, msg = pcall(test.fn)
        if success then
            local testSuccess, testMsg = test.fn()
            if testSuccess then
                Log('PASS', test.resource .. " (Int)", testMsg or "Integration Healthy")
            else
                Log('FAIL', test.resource .. " (Int)", testMsg or "Integration Broken")
            end
        else
            Log('FAIL', test.resource .. " (Int)", "Integration crashed: " .. tostring(msg))
        end
    end

    print("--------------------------------------------------")
    print(("^3[DjonStNix] Diagnostics Complete. Passed: ^2%d ^3| Failed: ^1%d^7"):format(results.passed, results.failed))
    
    if src ~= 0 then
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 215, 0},
            multiline = true,
            args = {"DjonStNix", ("Diagnostics Complete. ^2%d Passed, ^1%d Failed. ^7Check F8/Console for report."):format(results.passed, results.failed)}
        })
    end
end

-- Admin command for global diagnostics
RegisterCommand('dsn-test', function(source, args, rawCommand)
    if source ~= 0 then
        local isAllowed = exports['DjonStNix-Bridge']:IsPlayerAdmin(source)
        if not isAllowed then
            return print("^1[Security] ^7Unauthorized dsn-test attempt from source: " .. source)
        end
    end
    RunDiagnostics(source)
end, false)
