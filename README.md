<p align="center">
  <img src="https://img.shields.io/badge/DEVELOPED%20BY-DjonStNix-blue?style=for-the-badge&logo=github" alt="DjonStNix" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/Language-Lua_5.4-blue?style=flat-square&logo=lua" alt="Lua 5.4" />
  <img src="https://img.shields.io/badge/Platform-FiveM-orange?style=flat-square" alt="FiveM" />
  <img src="https://img.shields.io/badge/Framework-QBCore%20|%20ESX%20|%20QBox-green?style=flat-square" alt="Framework" />
  <img src="https://img.shields.io/badge/Maintained-Yes-brightgreen?style=flat-square" alt="Maintained" />
  <a href="https://discord.gg/s7GPUHWrS7"><img src="https://img.shields.io/badge/Discord-Join%20Us-5865F2?style=flat-square&logo=discord&logoColor=white" alt="Discord" /></a>
</p>

# 🌉 DjonStNix-Bridge (V1.0.0)

A universal framework bridge and security layer for FiveM. One dependency — every framework — zero rewrites. Auto-detects your stack at runtime and exposes a single, stable `Core` API that all DjonStNix resources share.

---

## 🌟 Features

### 🔌 Universal Framework Bridge

- **Auto-Detection** — Identifies QBCore, QBox, ESX, or Standalone at startup. Zero config required.
- **Unified Core API** — Single `Core` object with Player, Money, Items, Vehicle, Society, UI, Security, and Logging modules.
- **Inventory Agnostic** — Seamless support for ox_inventory, qb-inventory, and qs-inventory.
- **Target System Detection** — Detects ox_target and qb-target automatically.

### 🔒 Security Architecture

- **Token Bucket Rate Limiter** — Configurable per-player rate limiting that refills over time instead of fixed cooldowns.
- **SecureHandler Wrapper** — Drop-in event handler that validates source, applies rate limits, and catches errors in protected calls.
- **Input Validation** — Built-in `ValidateInput()` helper for type-checking, range enforcement, and length limits.
- **Permission Checks** — Framework-aware admin detection via `Core.Player.IsAdmin()` and `Core.Security.RequirePermission()`.
- **Suspicious Activity Logging** — Rate limit violations and blocked sources are logged automatically.

### ⚡ Performance

- **Event-Driven Architecture** — No busy loops; all modules use `CreateThread` with appropriate yields.
- **Lazy Initialization** — Framework objects are resolved once on startup, not on every API call.
- **Scoped Event Bus** — Lightweight cross-resource messaging without TriggerEvent boilerplate overhead.
- **Integration Polling** — Sibling resource status refreshed every 5 seconds, cached between checks.

### 🔀 Feature Gates

- **`Core.Features`** — Auto-populated capability table listing every detected module (inventory, target, ox_lib, banking, shops, dispatch).
- **Graceful Degradation** — Resources can check `Core.Features.hasBanking` before calling banking exports, avoiding nil errors.
- **Runtime Refresh** — Call `exports['DjonStNix-Bridge']:GetFeatures()` to get a fresh snapshot at any time.

### 🎨 UI Wrappers (Client)

- **Progress Bars** — Works with ox_lib, QB, or native fallback.
- **Context Menus** — ox_lib or qb-menu, same function signature.
- **Input Dialogs** — ox_lib or qb-input, unified API.
- **Item Image Resolver** — Returns the correct NUI image path for any inventory system.

---

## 🛠️ Installation

### 1. Prerequisites

| Dependency                             | Required    | Notes                      |
| -------------------------------------- | ----------- | -------------------------- |
| `oxmysql`                              | ✅ Yes      | Database driver            |
| `qb-core` / `es_extended` / `qbx_core` | ✅ Yes      | One framework required     |
| `ox_target` / `qb-target`              | 🟡 Optional | For target system bridging |

### 2. Download & Placement

1. Download or clone this repository.
2. Place in your resources folder: `resources/[addons]/DjonStNix-Bridge/`.
3. **DO NOT RENAME** the folder.

### 3. Startup Order

Add to your `server.cfg` — the bridge **must** start before any resource that depends on it:

```cfg
# Core Dependencies
ensure oxmysql
ensure ox_lib

# Framework
ensure qb-core          # or es_extended / qbx_core

# DjonStNix Ecosystem (Must start in this order)
ensure DjonStNix-Bridge
ensure DjonStNix-Banking # (optional)
ensure DjonStNix-Shops   # (optional)
```

### 4. Verify

On startup you should see:

```
[DjonStNix] v1.0.0 — Initializing Master Architecture...
[DjonStNix] Framework Detected: qb
[DjonStNix] Feature Gates: Inventory, Target, Banking
[DjonStNix-Bridge] v1.0.0 — Core.Ready is now TRUE.
```

---

## ⚙️ Configuration

All settings live in [`config.lua`](config.lua):

| Setting                                   | Default                          | Description                                         |
| ----------------------------------------- | -------------------------------- | --------------------------------------------------- |
| `Config.Framework`                        | `"auto"`                         | Override: `"qb"`, `"qbox"`, `"esx"`, `"standalone"` |
| `Config.Inventory`                        | `"auto"`                         | Override: `"ox"`, `"qb"`, `"qs"`, `"standalone"`    |
| `Config.Target`                           | `"auto"`                         | Override: `"ox"`, `"qb"`, `"none"`                  |
| `Config.Debug`                            | `false`                          | Verbose console output and EventBus tracing         |
| `Config.Logging.Enable`                   | `true`                           | Master logging toggle                               |
| `Config.Logging.DiscordWebhook`           | `false`                          | Set to webhook URL string                           |
| `Config.Security.RateLimit.Tokens`        | `10`                             | Max burst tokens per player                         |
| `Config.Security.RateLimit.RefillSeconds` | `60`                             | Seconds to refill one token                         |
| `Config.Security.LogSuspicious`           | `true`                           | Log rate limit violations and blocked sources       |
| `Config.Security.PermissionRoles`         | `{"admin", "superadmin", "god"}` | Roles treated as admin                              |

---

## 🔌 API Reference

Access the bridge from any resource:

```lua
local Core = exports['DjonStNix-Bridge']:GetCore()
```

### `Core.Player` — Player Data

| Function                      | Side   | Description                             |
| ----------------------------- | ------ | --------------------------------------- |
| `GetPlayer(src)`              | Server | Raw framework player object             |
| `GetPlayers()`                | Server | All online player objects               |
| `GetPlayerData(src)`          | Both   | Full player data table                  |
| `GetIdentifier(src)`          | Server | Citizen ID / identifier                 |
| `GetName(src)`                | Server | First + Last name string                |
| `GetJob(src)`                 | Both   | Job table `{ name, label, grade, ... }` |
| `SetJob(src, jobName, grade)` | Server | Set player job and grade                |
| `IsOnDuty(src)`               | Server | Duty status boolean                     |
| `IsAdmin(src)`                | Server | Admin / superadmin check                |
| `HasLicense(src, type)`       | Server | License check (QB/QBox)                 |
| `HasPermission(src, perm)`    | Server | Fine-grained permission check           |

### `Core.Money` — Economy

| Function                                    | Side   | Description                                  |
| ------------------------------------------- | ------ | -------------------------------------------- |
| `AddMoney(src, account, amount, reason)`    | Server | Deposit to `"cash"`, `"bank"`, or `"crypto"` |
| `RemoveMoney(src, account, amount, reason)` | Server | Withdraw (returns `false` if insufficient)   |
| `GetBalance(src, account)`                  | Server | Current balance for an account type          |

### `Core.Items` — Inventory

| Function                               | Side   | Description                       |
| -------------------------------------- | ------ | --------------------------------- |
| `AddItem(src, item, amount, metadata)` | Server | Give item to player               |
| `RemoveItem(src, item, amount)`        | Server | Take item from player             |
| `HasItem(src, item)`                   | Server | Returns `true` / `false`          |
| `GetItemData(src, item)`               | Server | Item details from inventory       |
| `GetItemsByType(src, type)`            | Server | All items matching a type (ox/qb) |
| `GetItemCount(src, item)`              | Server | Quantity of a specific item (ox)  |
| `GetInventory(src)`                    | Server | Full inventory contents           |
| `RegisterUsableItem(item, cb)`         | Server | Register a usable item handler    |

### `Core.Vehicle` — Vehicles

| Function                               | Side   | Description                      |
| -------------------------------------- | ------ | -------------------------------- |
| `GetOwnedVehicles(identifier)`         | Server | All vehicles owned by identifier |
| `SetVehicleOwner(plate, identifier)`   | Server | Transfer ownership               |
| `ValidateVehicleOwnership(src, plate)` | Server | Verify caller owns the plate     |
| `MarkVehicleStolen(plate)`             | Server | Emits `vehicle:stolen` event     |

### `Core.Society` — Organization Funds

| Function                       | Side   | Description                                       |
| ------------------------------ | ------ | ------------------------------------------------- |
| `GetSocietyAccount(job)`       | Server | Returns society account key                       |
| `AddSocietyMoney(job, amount)` | Server | Add funds (Banking → qb-management → esx_society) |

### `Core.Security` — Anti-Exploit

| Function                                        | Side   | Description                                             |
| ----------------------------------------------- | ------ | ------------------------------------------------------- |
| `RateLimit(src, key, cooldown)`                 | Server | Legacy cooldown-based limiter (backward compatible)     |
| `TakeToken(src, key)`                           | Server | Token bucket check — returns `false` when exhausted     |
| `SecureHandler(fn, opts)`                       | Server | Wraps event handler with source validation + rate limit |
| `ValidateInput(value, type, opts)`              | Server | Type / range / length validation                        |
| `RequirePermission(src, perm)`                  | Server | Notifies + blocks unpermitted players                   |
| `RegisterCommand(name, perm, cb, help, params)` | Server | Framework-aware command registration                    |

### `Core.Logging` — Logging

```lua
-- Type: "info" | "action" | "transaction" | "security" | "debug"
Core.Log(type, message, data)
```

### `Core.UI` — Client UI Wrappers

| Function                                                             | Description                      |
| -------------------------------------------------------------------- | -------------------------------- |
| `ProgressBar(name, label, duration, opts, anim, prop, done, cancel)` | ox_lib / QB progress bar         |
| `ShowContextMenu(id, title, items)`                                  | ox_lib / qb-menu context menu    |
| `Input(header, fields, cb)`                                          | ox_lib / qb-input dialog         |
| `GetItemImage(itemName)`                                             | NUI image path for any inventory |

### `Core.Notify` — Notifications

```lua
-- Client-side
Core.Notify(src, message, type) -- type: "success" | "error" | "info"

-- Server → Client
TriggerClientEvent('DjonStNix-Bridge:client:Notify', src, message, type)
```

### `Core.Functions` — Callbacks

| Function                         | Side            | Description                        |
| -------------------------------- | --------------- | ---------------------------------- |
| `TriggerCallback(name, cb, ...)` | Client          | Framework-agnostic server callback |
| `CreateCallback(name, cb)`       | Server / Client | Register a callback                |

### `Core.Features` — Feature Gates

```lua
local features = exports['DjonStNix-Bridge']:GetFeatures()

if features.hasBanking then
    -- Safe to call DjonStNix-Banking exports
end

-- Available gates: framework, isQB, isQBox, isESX, isStandalone,
-- hasOxInventory, hasQBInventory, hasQSInventory, hasInventory,
-- hasOxTarget, hasQBTarget, hasTarget, hasOxLib,
-- hasBanking, hasShops, hasGovernment, hasDispatch
```

### EventBus — Internal Events

```lua
Core.Emit('myEvent', { key = 'value' })   -- Fire a scoped event
Core.On('myEvent', function(payload) end)  -- Listen for a scoped event
```

### Utilities

```lua
Core.Utils.TableContains(table, value)   -- Search a sequential table
Core.Utils.GetFormattedPrice(5000)        -- "$5,000"
Core.Utils.DeepCopy(sourceTable)          -- Deep clone a table
```

### State Management (Client)

```lua
Core.SetState('isWorking', true)   -- Synced via OneSync state bags
Core.GetState('isWorking')         -- Retrieve state value
```

### Helper Exports

```lua
exports['DjonStNix-Bridge']:GetFramework()         -- "qb" | "qbox" | "esx" | "standalone"
exports['DjonStNix-Bridge']:IsResourceRunning(name) -- true / false
exports['DjonStNix-Bridge']:GetIntegrationStatus()  -- { ['DjonStNix-Banking'] = true, ... }
exports['DjonStNix-Bridge']:GetFeatures()            -- Full feature gates table
```

---

## 🚀 Quick Start Example

```lua
-- server/main.lua of your custom resource

local Core = exports['DjonStNix-Bridge']:GetCore()

RegisterNetEvent('myResource:buyItem', Core.Security.SecureHandler(function(src, item, price)
    -- Input validation
    local ok, err = Core.Security.ValidateInput(price, 'number', { min = 1 })
    if not ok then return end

    -- Economy: check and deduct funds
    if Core.Money.GetBalance(src, 'cash') < price then
        TriggerClientEvent('DjonStNix-Bridge:client:Notify', src, 'Not enough cash!', 'error')
        return
    end

    Core.Money.RemoveMoney(src, 'cash', price, 'Purchased ' .. item)
    Core.Items.AddItem(src, item, 1)

    -- Logging
    Core.Log('transaction', ('%s purchased %s for %s'):format(
        Core.Player.GetName(src), item, Core.Utils.GetFormattedPrice(price)
    ))

    TriggerClientEvent('DjonStNix-Bridge:client:Notify', src, 'Purchase successful!', 'success')
end, { name = 'buyItem' }))
```

---

## � Security Checklist

The following protections are built into the bridge. Server owners should verify:

- [x] All server-side operations validate player existence before accessing data
- [x] Money operations check balance before removing (returns `false` if insufficient)
- [x] Token bucket rate limiter enabled by default (10 tokens / 60s refill)
- [x] `SecureHandler` validates source is a real player (not console or spoofed)
- [x] Disconnected players are cleaned up from rate limit buckets
- [x] Permission checks use framework-native APIs (not custom tables)
- [x] Suspicious activity is logged when `Config.Security.LogSuspicious = true`
- [ ] Discord webhook logging (roadmap)
- [ ] Database audit log persistence (roadmap)

---

## �📁 Project Structure

```
DjonStNix-Bridge/
├── fxmanifest.lua              # Resource manifest
├── config.lua                  # Master configuration
├── shared/
│   ├── exports.lua             # Core object & EventBus initialization
│   ├── eventbus.lua            # Scoped event system
│   ├── utils.lua               # Utility functions
│   ├── framework_detect.lua    # Auto framework detection
│   └── integration_detect.lua  # Sibling resource detection
├── server/
│   ├── framework/
│   │   ├── qb.lua              # QBCore server bindings
│   │   ├── qbox.lua            # QBox server bindings
│   │   ├── esx.lua             # ESX server bindings
│   │   ├── standalone.lua      # Standalone fallback
│   │   ├── inventory.lua       # Unified inventory layer
│   │   ├── vehicle.lua         # Vehicle management
│   │   └── society.lua         # Society/org funds
│   ├── security.lua            # Token bucket, SecureHandler, validation
│   ├── logging.lua             # Console/webhook/DB logging
│   ├── permissions.lua         # Permission checks
│   ├── features.lua            # Feature gates (Core.Features)
│   └── main.lua                # Server initialization
├── client/
│   ├── framework.lua           # Client framework bindings
│   ├── notify.lua              # Notification wrappers
│   ├── ui.lua                  # Progress bars, menus, inputs, images
│   ├── state.lua               # OneSync state bag helpers
│   └── main.lua                # Client initialization
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🗺️ Roadmap

- [ ] Discord webhook logging implementation
- [ ] Database audit log persistence (`djon_audit_logs`)
- [ ] ox_lib callback support
- [ ] Expanded QBox-specific player data helpers
- [ ] Society fund management (QB/ESX)
- [ ] Target system wrapper API
- [ ] Phone integration bridge (qs-smartphone / lb-phone)
- [ ] Busted unit tests + CI pipeline
- [ ] Telemetry & observability (admin-only counters)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>DjonStNix</b> — Digital Creator & Software Developer<br/>
  <a href="https://www.youtube.com/@Djonluc">YouTube</a> •
  <a href="https://github.com/Djonluc">GitHub</a> •
  <a href="https://discord.gg/s7GPUHWrS7">Discord</a> •
  <a href="mailto:djonstnix@gmail.com">Email</a>
</p>
