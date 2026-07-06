---
sidebar_position: 2
---

# API Reference

Complete method list for `DataServiceServer`, `DataServiceClient`, and `Data`.

Root export:

```lua
local DataService = require(ReplicatedStorage.Packages.dataservicev2)
-- DataService.Server   (server only)
-- DataService.Client   (client only)
-- DataService.Paths    (typed paths after Init)
-- DataService.Enum     (OrderList.Asc / OrderList.Desc)
```

---

## DataServiceServer

Server singleton. **Writable.** Call `Init` once at boot.

| Method / property | Returns | Description |
|---|---|---|
| `:Init(options)` | `Server` | Initializes ProfileStore, paths, and player lifecycle |
| `:WaitFor(player)` | `Data` | Yields until player data is loaded |
| `:Get(player)` | `Data?` | Returns data if already loaded |
| `:HasData(player)` | `boolean` | Whether the player session is ready |
| `:GetProfile(player)` | `Profile?` | Underlying ProfileStore profile |
| `:GetBufferStats(player?)` | `table?` | QuickNet replication buffer metrics |
| `:Destroy()` | `()` | Cleans up all sessions and connections |
| `.Paths` | `PathTree` | Typed path tokens (available after `Init`) |

### Init options

| Option | Type | Default | Description |
|---|---|---|---|
| `Template` | `table` | required | Default player data shape |
| `StoreName` | `string?` | `"PlayerData"` | ProfileStore / DataStore name |
| `UseMock` | `boolean?` | `false` | Uses mock store (no real DataStore). **Not** per-player transient overlay |
| `KeyPrefix` | `string?` | `"Player_"` | Profile key prefix + `UserId` |
| `Exclude` | `{ Path }?` | `nil` | Paths that never replicate to the client |
| `StrictPaths` | `boolean?` | `true` | Errors on writes to invalid paths |
| `AutoCreateMissingTables` | `boolean?` | `false` | Auto-creates missing nested tables on write |

**Recommendations**

- Call `Init` exactly once in a dedicated bootstrap script (`ServerScriptService`).
- Use `WaitFor(player)` inside `PlayerAdded`, not `Get`, unless you know data is already loaded.
- Keep `StrictPaths = true` in production.
- Use `Exclude` for secrets, anti-cheat flags, or server-only state.

---

## DataServiceClient

Client singleton. **Read-only** data mirror.

| Method / property | Returns | Description |
|---|---|---|
| `:Init()` | `Data` | Yields until the initial snapshot arrives |
| `:WaitForData()` | `Data` | Yields until replicated data exists |
| `:Get()` | `Data?` | Data if snapshot already received |
| `:GetBufferStats()` | `table?` | Latest replication buffer stats from server |
| `:Destroy()` | `()` | Cleans client listeners |
| `.Paths` | `PathTree` | Typed paths (available after `Init`) |

**Recommendations**

- Call `Init()` once from a `LocalScript` under `StarterPlayerScripts`.
- Never call `Set` / `Update` on the client — mutations are server-driven.
- Use `GetChangedSignal` for UI updates instead of polling `Get`.

---

## Data

Per-player data instance. Returned by `Server:WaitFor` or `Client:Init`.

### Read methods

| Method | Server | Client | Description |
|---|---:|---:|---|
| `:Get(path?)` | ✓ | ✓ | Merged value (persisted + transient overlay). Omit path for full root |
| `:GetPersisted(path?)` | ✓ | ✓ | Saved ProfileStore value only |
| `:GetTransient(path?)` | ✓ | ✓ | Transient overlay at path, if any |
| `:HasTransient(path?)` | ✓ | ✓ | Whether a transient overlay exists |
| `:Typed(path)` | ✓ | ✓ | Type helper for signals and generics |

### Persisted write methods (server only)

| Method | Description |
|---|---|
| `:Set(path, value)` | Writes and saves to ProfileStore |
| `:Update(path, fn)` | Reads persisted value, applies `fn`, then `Set` |
| `:ArrayInsert(path, value, index?)` | Inserts into a persisted array |
| `:ArrayRemove(path, index)` | Removes from a persisted array; returns removed value |

### Transient write methods (server only)

| Method | Description |
|---|---|
| `:SetTransient(path, value)` | Overlay visible in `Get()` but **not saved** |
| `:UpdateTransient(path, fn)` | Updates merged value via transient overlay |
| `:ClearTransient(path?)` | Clears overlay (`nil` clears all) |
| `:ArrayInsertTransient(path, value, index?)` | Array insert through overlay |
| `:ArrayRemoveTransient(path, index)` | Array remove through overlay |

### Query methods

| Method | Description |
|---|---|
| `:GetOrderedList(path, options)` | Sorts table entries by `options.key`; supports `order`, `limit` |
| `:GetOrderedListWithPriority(path, key, order?)` | Shortcut for sorting by one field |

`order` accepts `Enum.OrderList.Desc` (default) or `Enum.OrderList.Asc`.

Each entry:

```lua
{ index = number, value = any, priority = any }
```

### Signals

| Method | Fires when |
|---|---|
| `:GetChangedSignal(path)` | Merged value at path changes |
| `:GetPathChangedSignal(path)` | Alias of `GetChangedSignal` |
| `:GetIndexChangedSignal(path)` | Direct child of path changes |
| `:GetArrayInsertedSignal(path)` | Item inserted in array at path |
| `:GetArrayRemovedSignal(path)` | Item removed from array at path |
| `.Changed` | Any mutation (`action`, `path`, `...`) |

Transient changes fire the same signals as persisted writes.

### Lifecycle

| Method | Description |
|---|---|
| `:Destroy()` | Destroys internal signals and clears transient state |

---

## Enum

```lua
local Enum = require(ReplicatedStorage.Packages.dataservicev2).Enum

Enum.OrderList.Desc -- "desc", highest first (default)
Enum.OrderList.Asc  -- "asc", lowest first
```

---

## Quick decision guide

| Goal | Use |
|---|---|
| Real player progress | `Set` / `Update` |
| Admin / QA preview without saving | `*Transient` |
| Leaderboard from a list field | `GetOrderedListWithPriority` |
| UI reacts to coin changes | `GetChangedSignal(Paths.Currencies.Coins)` |
| Hide data from client | `Exclude` in `Init` |
| Studio without DataStore API | `UseMock = true` |
