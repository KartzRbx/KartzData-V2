---
sidebar_position: 3
---

# Typed paths

DataServiceV2 builds a path tree from the template passed to `Server:Init`.

## Recommended usage

```lua
local DataService = require(ReplicatedStorage.Packages.dataservicev2)
local Paths = DataService.Server.Paths :: DataTemplate.Schema

data:Set(Paths.Currencies.Coins, 100)
local coins = data:Get(Paths.Currencies.Coins)

data:GetChangedSignal(Paths.Currencies.Coins):Connect(function(newValue, oldValue)
	print(newValue, oldValue)
end)
```

Paths live on the **service** (`DataService.Server.Paths`), not on the `data` instance.

## Shared modules

In `ReplicatedStorage.Shared` modules:

```lua
local DataService = require(ReplicatedStorage.Packages.dataservicev2)

-- Server (after Server:Init)
local Paths = DataService.Paths :: DataTemplate.Schema

-- Client (after Client:Init)
local Paths = DataService.Client.Paths :: DataTemplate.Schema
```

On `2.2.2+`, `DataService.Client` exists on the server as a safe facade with stub `Paths`. Client methods only work on the client.

## Legacy format

String arrays still work:

```lua
data:Set({ "Currencies", "Coins" }, 100)
```

Prefer typed paths for autocomplete and fewer typos.

## Validation

| Option | Default | Description |
|---|---|---|
| `StrictPaths` | `true` | Blocks writes to invalid paths |
| `AutoCreateMissingTables` | `false` | Does not auto-create missing nested tables |

Legacy permissive mode:

```lua
DataServiceServer:Init({
	Template = DataTemplate,
	StrictPaths = false,
	AutoCreateMissingTables = true,
})
```

## Private data

Paths in `Exclude` are not replicated to the client:

```lua
DataServiceServer:Init({
	Template = DataTemplate,
	Exclude = { { "Private" } },
})
```
