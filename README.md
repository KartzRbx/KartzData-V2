# DataServiceV2

High-performance Roblox data service with automatic server/client replication, embedded ProfileStore persistence, typed path tokens, QuickNet transport, and Janitor-based connection lifecycle management.

**Documentation:** https://kartzrbx.github.io/KartzData-V2/docs/intro  
**API reference:** https://kartzrbx.github.io/KartzData-V2/docs/api-reference  
**Repository:** https://github.com/KartzRbx/KartzData-V2

## Local testing

```powershell
.\scripts\setup-test-env.ps1
cd Test
rojo serve
```

`Test/` is gitignored. The template lives in `test-template/`.

## Installation

`wally.toml`:

```toml
[dependencies]
dataservicev2 = "kartzrbx/dataservicev2@2.3.2"
```

```bash
wally install
```

Bundled dependencies (`signal`, `quicknet`, `janitor`) are included in the package — no extra Wally deps required in your game.

### Rojo setup

```json
{
  "name": "MyGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

Require:

```lua
local DataService = require(ReplicatedStorage.Packages.dataservicev2)
local DataServiceServer = DataService.Server
local DataServiceClient = DataService.Client
```

## Quick start

**Server**

```lua
local DataServiceServer = require(ReplicatedStorage.Packages.dataservicev2).Server

DataServiceServer:Init({
	Template = DataTemplate,
	StoreName = "PlayerDataV2",
	StrictPaths = true,
})

local data = DataServiceServer:WaitFor(player)
local Paths = DataServiceServer.Paths :: DataTemplate.Schema
data:Set(Paths.Currencies.Coins, 100)
```

**Client**

```lua
local DataServiceClient = require(ReplicatedStorage.Packages.dataservicev2).Client
local data = DataServiceClient:Init()
local Paths = DataServiceClient.Paths :: DataTemplate.Schema
print(data:Get(Paths.Currencies.Coins))
```

## Features

- Typed path tokens (`DataService.Paths.Currencies.Coins`)
- ProfileStore persistence with automatic reconciliation
- QuickNet replication with Janitor cleanup
- Transient overlay API for admin/QA panels (`*Transient`)
- Ordered list queries with `Enum.OrderList.Asc` / `Desc`

## Docs

- [Getting started](https://kartzrbx.github.io/KartzData-V2/docs/intro)
- [API reference](https://kartzrbx.github.io/KartzData-V2/docs/api-reference)
- [Project structure](https://kartzrbx.github.io/KartzData-V2/docs/guides/project-structure)
