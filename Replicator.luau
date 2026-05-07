local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("signal"))

local REMOTE_NAME = "DataServiceReplicator"
local READY_TOKEN = "R"

local Replicator: { [string]: any } = {}

local function getRemote(): RemoteEvent
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
		if existing and existing:IsA("RemoteEvent") then
			return existing
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = REMOTE_NAME
		remote.Parent = ReplicatedStorage
		return remote
	else
		return ReplicatedStorage:WaitForChild(REMOTE_NAME) :: RemoteEvent
	end
end

if RunService:IsServer() then
	local remote = getRemote()
	local Server = {
		OnReady = Signal.new(),
	}

	remote.OnServerEvent:Connect(function(player: Player, msg: any)
		if msg ~= READY_TOKEN then
			return
		end
		Server.OnReady:Fire(player)
	end)

	function Server:Send(player: Player, ...)
		remote:FireClient(player, ...)
	end

	Replicator.Server = Server
else
	local remote = getRemote()
	local handlers: { [string]: (...any) -> () } = {}

	remote.OnClientEvent:Connect(function(action: string, ...)
		local h = handlers[action]
		if h then
			h(...)
		end
	end)

	local Client = {}

	function Client:On(action: string, fn: (...any) -> ())
		handlers[action] = fn
	end

	function Client:NotifyReady()
		remote:FireServer(READY_TOKEN)
	end

	Replicator.Client = Client
end

return Replicator
