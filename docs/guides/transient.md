---
sidebar_position: 4
---

# Transient overlay

Test overlay: values are visible and replicated to the client, but **not saved** to ProfileStore.

## Use case

Player has **500 real coins**. An admin panel adds **+500** to display **1000**, but on leave only **500** should be saved.

```lua
local Paths = DataServiceServer.Paths :: DataTemplate.Schema

-- real progress (saved)
data:Set(Paths.Currencies.Coins, 500)

-- test panel (NOT saved)
data:UpdateTransient(Paths.Currencies.Coins, function(current)
	return (current or 0) + 500
end)

print(data:Get(Paths.Currencies.Coins))           -- 1000 (merged)
print(data:GetPersisted(Paths.Currencies.Coins)) -- 500
```

The overlay is discarded when the player leaves.

## API summary

| Method | Persists? | Description |
|---|---|---|
| `Set` / `Update` | Yes | Real player progress |
| `SetTransient` / `UpdateTransient` | No | Admin / QA overlay |
| `ClearTransient(path?)` | — | Remove overlay (`nil` = clear all) |
| `Get()` | — | Merged value |
| `GetPersisted()` | — | Saved value only |
| `GetTransient()` | — | Overlay only, if present |

Arrays support `ArrayInsertTransient` and `ArrayRemoveTransient`.

## Rules

- Use `Set` / `Update` for real progress.
- Use `*Transient` only in admin or QA tools.
- Overlay replicates to the client and fires `GetChangedSignal`.
- `UseMock` is **not** a substitute — it mocks the entire store, not per-session overlay on real data.
