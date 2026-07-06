---
sidebar_position: 2
---

# Recommended project structure

A production-friendly layout for games using DataServiceV2.

## Folder layout

```text
src/
  shared/
    DataTemplate.luau       -- default player data + export type Schema
    DataPaths.luau          -- optional: re-export typed Paths helper
  server/
    DataBootstrap.server.luau -- Server:Init once
    PlayerData.server.luau    -- PlayerAdded / rewards / economy
  client/
    DataClient.client.luau    -- Client:Init + global signals
    UI/
      Hud.client.luau       -- reads data, listens to signals
```

Rojo maps `src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService`, etc.

## Bootstrap pattern (server)

**Do**

- One script calls `Server:Init` at startup.
- Per-player logic uses `Server:WaitFor(player)` in `PlayerAdded`.
- Paths come from `DataServiceServer.Paths`, cast with `DataTemplate.Schema`.

**Don't**

- Call `Init` from multiple scripts.
- Store paths on the `data` instance (they live on the service).
- Write player data from the client.

```lua
-- ServerScriptService/DataBootstrap.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTemplate = require(ReplicatedStorage.Shared.DataTemplate)
local DataServiceServer = require(ReplicatedStorage.Packages.dataservicev2).Server

DataServiceServer:Init({
	Template = DataTemplate,
	StoreName = "PlayerDataV2",
	StrictPaths = true,
	AutoCreateMissingTables = false,
	Exclude = { { "Private" } },
})
```

## Client pattern

```lua
-- StarterPlayerScripts/DataClient.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataServiceClient = require(ReplicatedStorage.Packages.dataservicev2).Client

local data = DataServiceClient:Init()
-- UI modules receive `data` and DataServiceClient.Paths
```

## Shared modules

For code used on both server and client:

```lua
local DataService = require(ReplicatedStorage.Packages.dataservicev2)
local RunService = game:GetService("RunService")

local Paths
if RunService:IsServer() then
	Paths = DataService.Paths :: DataTemplate.Schema
else
	Paths = DataService.Client.Paths :: DataTemplate.Schema
end
```

On server `2.2.2+`, `DataService.Client` is a safe stub (paths only). Client methods error on the server.

## Data template rules

1. **JSON-compatible values only** — no `Instance`, `Vector3`, `CFrame`, functions.
2. **Stable keys** — renaming template keys breaks saved profiles unless you migrate.
3. **Nested tables for domains** — `Currencies`, `Stats`, `Inventory`, not flat globals.
4. **Export `Schema`** — `export type Schema = typeof(Data)` for path typing.
5. **Arrays as lists** — `Inventory = {} :: { string }` for `ArrayInsert` / `ArrayRemove`.

## Replication boundaries

| Data type | Recommendation |
|---|---|
| Currency, stats, inventory | Replicate (default) |
| Admin flags, ban state, roll seeds | `Exclude` |
| Test / preview values | `*Transient` (never `Set` for fake rewards) |

## Script responsibilities

| Script | Responsibility |
|---|---|
| `DataBootstrap` | `Init`, global config |
| `PlayerData` | load player, starter grants, session hooks |
| `EconomyService` | `Update` coins/gems with validation |
| `DataClient` | `Init`, expose data to UI layer |
| UI controllers | `Get` + `GetChangedSignal`, no writes |

## Local module testing

Use the repo's `Test/` Rojo sandbox (gitignored):

```bash
.\scripts\setup-test-env.ps1
cd Test
rojo serve
```

`Test/default.project.json` maps `dataservicev2` directly to `../src` so you can iterate without publishing to Wally.

## Checklist before shipping

- [ ] `Server:Init` runs once before any `WaitFor`
- [ ] `Client:Init` in a LocalScript
- [ ] All writes happen on the server
- [ ] `StrictPaths = true`
- [ ] Secrets in `Exclude`
- [ ] Admin tools use `*Transient`, not `Set`
- [ ] `DataTemplate.Schema` used for `Paths` typing
