---
sidebar_position: 5
---

# Ordered lists

Sort table entries by a numeric field (e.g. `Damage`).

## Example

```lua
local Enum = require(ReplicatedStorage.Packages.dataservicev2).Enum
local Paths = DataServiceServer.Paths :: DataTemplate.Schema

local ordered = data:GetOrderedListWithPriority(
	Paths.Units.List,
	"Damage",
	Enum.OrderList.Desc
)

for _, entry in ordered do
	print(entry.index, entry.value.Damage, entry.priority)
end
```

## Top N

```lua
local top3 = data:GetOrderedList(Paths.Units.List, {
	key = "Damage",
	order = Enum.OrderList.Desc,
	limit = 3,
})
```

## `Enum.OrderList`

| Enum | Meaning |
|---|---|
| `Enum.OrderList.Desc` | Descending — highest first (**default**) |
| `Enum.OrderList.Asc` | Ascending — lowest first |

Strings `"asc"` and `"desc"` still work for compatibility.

## Return shape

Each entry:

```lua
{
	index = number,    -- original index in the list
	value = any,       -- full item
	priority = any,    -- value used for sorting
}
```

`nil` priorities are treated as `0`.
