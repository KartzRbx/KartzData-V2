local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTemplate = require(ReplicatedStorage.DataTemplate)
local DataService = require(ReplicatedStorage.Packages.dataservicev2)
local DataServiceClient = DataService.Client
local Enum = DataService.Enum

local data = DataServiceClient:Init()
local Paths = DataServiceClient.Paths :: DataTemplate.Schema

print("[Test Client] Initial Coins:", data:Get(Paths.Currencies.Coins))

data:GetChangedSignal(Paths.Currencies.Coins):Connect(function(newValue, oldValue)
	print(("[Test Client] Coins: %s -> %s"):format(tostring(oldValue), tostring(newValue)))
end)

data:GetChangedSignal(Paths.Stats.XP):Connect(function(newValue)
	print("[Test Client] XP:", newValue)
end)

task.defer(function()
	local ordered = data:GetOrderedListWithPriority(Paths.Units.List, "Damage", Enum.OrderList.Desc)
	for _, entry in ordered do
		print("[Test Client] Unit rank:", entry.index, entry.value.Name, entry.priority)
	end
end)

task.spawn(function()
	while task.wait(15) do
		local buffer = DataServiceClient:GetBufferStats()
		if buffer then
			print(("[Test Client] Buffer | bytes=%d messages=%d"):format(
				buffer.Bytes or 0,
				buffer.Messages or 0
			))
		end
	end
end)
