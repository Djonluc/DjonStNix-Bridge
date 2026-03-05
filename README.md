<!-- ==============================================================================
👑 DJONSTNIX BRANDING
==============================================================================
DEVELOPED BY: DjonStNix (DjonLuc)
GITHUB: https://github.com/Djonluc
DISCORD: https://discord.gg/s7GPUHWrS7
YOUTUBE: https://www.youtube.com/@Djonluc
EMAIL: djonstnix@gmail.com
LICENSE: MIT License (c) 2026 DjonStNix (DjonLuc)
============================================================================== -->

# 🌉 DjonStNix-Bridge

### [DjonStNix Ecosystem] - Framework Abstraction & Security Layer

![DjonStNix Premium](https://img.shields.io/badge/DjonStNix-Premium-gold?style=for-the-badge)
![Middleware](https://img.shields.io/badge/Layer-Middleware-blue?style=for-the-badge)

---

## 📖 Description

**DjonStNix-Bridge** is the critical foundation of the DjonStNix ecosystem. It acts as a universal abstraction layer that translates native framework calls (QBCore, ESX, QBox) into a unified API. This allows every script in the ecosystem to run on any major framework without modification.

## 👤 Author & Attribution

- **Author:** DjonLuc
- **Project:** DjonStNix Ecosystem
- **GitHub:** [https://github.com/Djonluc](https://github.com/Djonluc)

## ✨ Features

- ⚙️ **Framework Agnostic:** Auto-detects QBCore, ESX, and QBox.
- 🛡️ **Atomic Security:** Integrated `SecureHandler` for rate-limited server events.
- 📡 **Global EventBus:** Unified Pub/Sub system for inter-script communication.
- 📊 **Core Validation:** Real-time data sanitization and type checking.
- 📜 **Structured Logging:** Centralized error reporting via `Core.Logging`.

## 📦 Dependencies

- **Required:** `oxmysql`
- **Optional:** `ox_lib` (Enhanced notifications/progress)

## 📥 Installation Instructions

1.  **Extract:** Move the `DjonStNix-Bridge` folder to `resources/[addons]/`.
2.  **Order:** Ensure the resource is named exactly `DjonStNix-Bridge`.
3.  **Config:** Set your framework in `config.lua` (or use `"auto"`).

## 📝 File Modification Instructions

To upgrade a custom script to use Bridge security:

**File:** `your-script/server/main.lua`

**Action:** Replace standard events with `SecureServerEvent`.

**Snippet Replacement:**

```lua
-- FIND (approx line 45):
RegisterNetEvent('myscript:server:DoSomething', function(data)
    local src = source
    -- ...
end)

-- REPLACE WITH:
local Core = exports['DjonStNix-Bridge']:GetCore()
Core.Security.SecureServerEvent('myscript:server:DoSomething', function(src, data)
    -- src is automatically validated and rate-limited here
    -- ...
end)
```

## 🔍 Before / After Examples

### ❌ BEFORE (Hardcoded QBCore)

```lua
local Player = QBCore.Functions.GetPlayer(source)
local citizenid = Player.PlayerData.citizenid
```

### ✅ AFTER (Bridge Abstraction)

```lua
local Core = exports['DjonStNix-Bridge']:GetCore()
local citizenid = Core.Player.GetIdentifier(source)
```

## ⚙️ Configuration Instructions

Open `config.lua` to define your environment:

```lua
Config.Framework = "auto" -- auto, qb, esx, qbox, standalone
Config.Security = {
    RateLimit = true,
    MaxTriggersPerSecond = 5
}
```

## 🗄️ Database Installation

No database required for this layer. ❌

## 🚀 server.cfg Setup

```cfg
ensure DjonStNix-Branding
ensure DjonStNix-Bridge
ensure DjonStNix-Banking
```

## 🔌 Optional Integrations

- **DjonStNix-Banking:** Unlocks the atomic monetary API.

## 💻 Example Usage

### 🛡️ Secure Event

```lua
local Core = exports['DjonStNix-Bridge']:GetCore()
Core.Security.SecureServerEvent('my:event', function(src, data)
    print("Securely triggered by " .. src)
end)
```

## 🛠️ Troubleshooting

- **Framework not detected?** Manually set `Config.Framework` to your framework string.
- **Exports nil?** Ensure `DjonStNix-Bridge` starts _before_ other scripts.

---

© 2026 **DjonStNix Ecosystem**. All rights reserved.
[GitHub](https://github.com/Djonluc) | [Discord](https://discord.gg/s7GPUHWrS7)
