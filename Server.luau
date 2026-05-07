local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

assert(RunService:IsServer(), "DataService.Server may only be required on the server")

local profilestore = require(ServerScriptService:WaitForChild("ServerPackages"):WaitForChild("profilestore"))
local Signal = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("signal"))

local Data = require(script.Parent.Data)
local Enums = require(script.Parent.Enums)
local Path = require(script.Parent.Path)
local Replicator = require(script.Parent.Replicator).Server

type DataPath = Path.Path

local DEFAULT_KEY_PREFIX = "Player_"

export type Options = {
	Template: any,
	StoreName: string?,
	UseMock: boolean?,
	KeyPrefix: string?,
	Exclude: { DataPath }?,
}

local Server = {
	_initialized = false,
	_options = nil :: Options?,
	_store = nil :: any,
	_data = {} :: { [Player]: any },
	_profiles = {} :: { [Player]: any },
	_waitSignals = {} :: { [Player]: any },
	_ready = {} :: { [Player]: boolean },
	_replicateBindings = {} :: { [Player]: RBXScriptConnection },
	_excluded = {} :: { [string]: boolean },
}

local function isExcluded(self, path: DataPath?): boolean
	if not path or #path == 0 then
		return false
	end
	for i = 1, #path do
		local prefix = table.create(i)
		for j = 1, i do
			prefix[j] = path[j]
		end
		if self._excluded[Path.toKey(prefix)] then
			return true
		end
	end
	return false
end

local function buildSnapshot(self, value: any, prefix: DataPath): any
	if isExcluded(self, prefix) then
		return nil
	end
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		local newPath = table.clone(prefix)
		newPath[#newPath + 1] = k
		if not isExcluded(self, newPath) then
			out[k] = buildSnapshot(self, v, newPath)
		end
	end
	return out
end

function Server:Init(options: Options)
	assert(not self._initialized, "DataService.Server already initialized")
	self._initialized = true
	self._options = options

	local store = profilestore.New(options.StoreName or "PlayerData", options.Template)
	self._store = if options.UseMock then store.Mock else store

	self._excluded = {}
	for _, p in options.Exclude or {} do
		self._excluded[Path.toKey(p)] = true
	end

	Replicator.OnReady:Connect(function(player)
		self._ready[player] = true
		if self._data[player] then
			self:_sendInit(player)
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_playerAdded(player)
		end)
	end
	Players.PlayerAdded:Connect(function(p)
		self:_playerAdded(p)
	end)
	Players.PlayerRemoving:Connect(function(p)
		self:_playerRemoving(p)
	end)
end

function Server:_profileKey(player: Player): string
	local opts: any = self._options
	return (opts.KeyPrefix or DEFAULT_KEY_PREFIX) .. tostring(player.UserId)
end

function Server:_playerAdded(player: Player)
	local key = self:_profileKey(player)
	local profile = self._store:StartSessionAsync(key, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		player:Kick("Data load failed - please rejoin")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil
		if player.Parent then
			player:Kick("Data session ended - please rejoin")
		end
	end)

	if not player:IsDescendantOf(Players) then
		profile:EndSession()
		return
	end

	self._profiles[player] = profile
	local data = Data.new(profile.Data, true)
	self._data[player] = data

	self._replicateBindings[player] = data.Changed:Connect(function(action, path, ...)
		if not self._ready[player] then
			return
		end
		if isExcluded(self, path) then
			return
		end
		Replicator:Send(player, action, path, ...)
	end)

	local sig = self._waitSignals[player]
	if sig then
		sig:Fire()
		sig:Destroy()
		self._waitSignals[player] = nil
	end

	if self._ready[player] then
		self:_sendInit(player)
	end
end

function Server:_sendInit(player: Player)
	local data = self._data[player]
	if not data then
		return
	end
	local snapshot = buildSnapshot(self, data:Get(), {})
	Replicator:Send(player, Enums.Init, nil, snapshot)
end

function Server:_playerRemoving(player: Player)
	local conn = self._replicateBindings[player]
	if conn then
		conn:Disconnect()
		self._replicateBindings[player] = nil
	end

	local data = self._data[player]
	if data then
		data:Destroy()
		self._data[player] = nil
	end

	local profile = self._profiles[player]
	if profile then
		profile:EndSession()
		self._profiles[player] = nil
	end

	self._ready[player] = nil

	local sig = self._waitSignals[player]
	if sig then
		sig:Destroy()
		self._waitSignals[player] = nil
	end
end

function Server:WaitFor(player: Player)
	if self._data[player] then
		return self._data[player]
	end
	if not player:IsDescendantOf(Players) then
		return nil
	end
	local sig = self._waitSignals[player]
	if not sig then
		sig = Signal.new()
		self._waitSignals[player] = sig
	end
	sig:Wait()
	return self._data[player]
end

function Server:Get(player: Player)
	return self._data[player]
end

function Server:HasData(player: Player): boolean
	return self._data[player] ~= nil
end

function Server:GetProfile(player: Player): any
	return self._profiles[player]
end

return Server
