---
sidebar_position: 1
---

# Getting Started with DataServiceV2

DataServiceV2 manages player persistence on the server and keeps clients in sync automatically.

Wally package: `kartzrbx/dataservicev2`. Bundled dependencies (`signal`, `quicknet`, `janitor`) are included — you do not need to add them to your game's `wally.toml`.

## 1) Install

Add to your game's `wally.toml`:

```toml
[dependencies]
dataservicev2 = "kartzrbx/dataservicev2@2.3.2"
```

Then run:

```bash
wally install
```

In Rojo, sync `Packages` to `ReplicatedStorage.Packages`:

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

## 2) Define your data template

Create a module with default player data:

```lua
local Data = {
	Currencies = {
		Coins = 0,
		Gems = 0,
	},
	Stats = {
		Level = 1,
		XP = 0,
	},
	Inventory = {} :: { string },
}

export type Schema = typeof(Data)

return Data
```

> Keep values JSON-compatible (numbers, strings, booleans, arrays, dictionaries).

## 3) Initialize on the server

In a server script, initialize DataService once:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTemplate = require(ReplicatedStorage.DataTemplate)
local DataServiceServer = require(ReplicatedStorage.Packages.dataservicev2).Server

DataServiceServer:Init({
	Template = DataTemplate,
	StoreName = "PlayerDataV2",
	StrictPaths = true,
})
```

After `Init`, typed paths are available on `DataServiceServer.Paths`:

```lua
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local data = DataServiceServer:WaitFor(player)
	local Paths = DataServiceServer.Paths :: DataTemplate.Schema

	data:Set(Paths.Currencies.Coins, 100)
end)
```

## 4) Init, read, and react on the client

On the client, initialize and subscribe to changes:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTemplate = require(ReplicatedStorage.DataTemplate)
local DataServiceClient = require(ReplicatedStorage.Packages.dataservicev2).Client

local data = DataServiceClient:Init()
local Paths = DataServiceClient.Paths :: DataTemplate.Schema

print("Coins:", data:Get(Paths.Currencies.Coins))

data:GetChangedSignal(Paths.Currencies.Coins):Connect(function(newValue, oldValue)
	print("Coins updated:", oldValue, "->", newValue)
end)
```

## 5) Update data on the server

Mutate player data with `Set` or `Update`:

```lua
local data = DataServiceServer:WaitFor(player)
local Paths = DataServiceServer.Paths :: DataTemplate.Schema

data:Update(Paths.Currencies.Coins, function(current)
	return (current or 0) + 100
end)
```

## Local test environment

This repo includes a Rojo sandbox under `Test/` (gitignored). Copy the template and sync:

```bash
.\scripts\setup-test-env.ps1
cd Test
rojo serve
```

## Next steps

- [Recommended project structure](./guides/project-structure)
- [Typed paths](./guides/paths)
- [Transient overlay](./guides/transient)
- [Ordered lists](./guides/ordered-lists)
- [Full API reference](./api-reference)
- [Generated API docs](https://kartzrbx.github.io/KartzDataService/api)
