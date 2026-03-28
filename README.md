# DjonStNix Bridge - Developer Documentation

## 🛑 EXCLUSIVE Banking Interface 🛑

To ensure 100% receipt coverage and financial stability, the DjonStNix Bridge is the **ONLY PERMITTED WAY** to process player bank transactions.

Direct calls to `Player.Functions.RemoveMoney("bank", ...)` or framework-direct exports are strictly prohibited for ecosystem resources.

---

## Unified Transaction Engine [NEW]

The Bridge now features a **Universal Receipt Engine** that auto-calculates totals, taxes, and itemized breakdowns.

### 1. Unified Process: `ProcessBankTransaction`

This is the recommended way to handle all bank charges. You can send either a full receipt or minimal purchase data.

```lua
-- Simple Usage: Minimal Data (Bridge auto-calculates tax/totals)
exports['DjonStNix-Bridge']:ProcessBankTransaction(src, {
    source = "Shop Purchase",
    items = {
        { name = "Water", price = 2, quantity = 2 },
        { name = "Bread", price = 5, quantity = 1 }
    }
})

-- Pro Usage: Single Item Shorthand
exports['DjonStNix-Bridge']:ProcessBankTransaction(src, {
    source = "Vehicle Dealer",
    item = "Sultan RS",
    price = 45000
})
```

### 2. Manual Helper: `CreateReceipt`

If you need to display the receipt to the user _before_ charging them, use the `CreateReceipt` helper.

```lua
local receipt = exports['DjonStNix-Bridge']:CreateReceipt({
    source = "Property Sale",
    item = "Apartment 101",
    price = 250000
})
```

---

## Enforcement & Fallbacks

The Bridge strictly enforces the presence of a structured receipt for all `bank` account transactions.

- **Critical Warnings**: If a script attempts a bank withdrawal without a receipt (via standard `RemoveMoney`), the Bridge will log a `[CRITICAL WARNING]` to the server console.
- **Auto-Fallbacks**: The Bridge will automatically generate an "Unknown Transaction" receipt with the exact format required by the Banking Spec.

---

## Legacy Support (LogBankTransaction)

For scripts that only need to log a transaction without using the new helpers:

```lua
-- Legacy method (internally redirects to ChargeBankAccount if 'bank')
exports['DjonStNix-Bridge']:LogBankTransaction(src, amount, 'bank', "Legacy Reason", receiptData)
```
