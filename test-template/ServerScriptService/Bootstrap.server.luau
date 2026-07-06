local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTemplate = require(ReplicatedStorage.DataTemplate)
local DataServiceServer = require(ReplicatedStorage.Packages.dataservicev2).Server

DataServiceServer:Init({
	Template = DataTemplate,
	StoreName = "DataServiceV2_Test",
	KeyPrefix = "Test_",
	UseMock = true,
	StrictPaths = true,
	AutoCreateMissingTables = false,
	Exclude = { { "Private" } },
})

print("[Test Server] DataServiceV2 initialized")

Players.PlayerAdded:Connect(function(player)
	local data = DataServiceServer:WaitFor(player)
	local Paths = DataServiceServer.Paths :: DataTemplate.Schema

	data:Set(Paths.Currencies.Coins, 100)
	data:Update(Paths.Stats.XP, function(current)
		return (current or 0) + 10
	end)

	data:GetChangedSignal(Paths.Currencies.Coins):Connect(function(newValue, oldValue)
		print(("[Test Server] %s Coins: %s -> %s"):format(player.Name, tostring(oldValue), tostring(newValue)))
	end)

	print(("[Test Server] %s loaded | Coins=%s"):format(player.Name, data:Get(Paths.Currencies.Coins)))
end)

Players.PlayerRemoving:Connect(function(player)
	local stats = DataServiceServer:GetBufferStats(player)
	if stats then
		print(("[Test Server] Buffer %s | bytes=%d messages=%d"):format(
			player.Name,
			stats.Bytes or 0,
			stats.Messages or 0
		))
	end
end)
