local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

assert(RunService:IsClient(), "DataService.Client may only be required on the client")

local Signal = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("signal"))

local Data = require(script.Parent.Data)
local Enums = require(script.Parent.Enums)
local Replicator = require(script.Parent.Replicator).Client

local Client = {
	_initialized = false,
	_data = nil :: any?,
	_loaded = Signal.new(),
}

function Client:Init(): any
	if not self._initialized then
		self._initialized = true

		Replicator:On(Enums.Init, function(_path, snapshot)
			if self._data then
				self._data:Destroy()
			end
			self._data = Data.new(snapshot, false)
			self._loaded:Fire()
		end)

		Replicator:On(Enums.Set, function(path, value)
			if self._data then
				self._data:_applySet(path, value)
			end
		end)

		Replicator:On(Enums.ArrayInsert, function(path, value, index)
			if self._data then
				self._data:_applyArrayInsert(path, value, index)
			end
		end)

		Replicator:On(Enums.ArrayRemove, function(path, index)
			if self._data then
				self._data:_applyArrayRemove(path, index)
			end
		end)

		Replicator:NotifyReady()
	end

	return self:WaitForData()
end

function Client:WaitForData()
	if self._data then
		return self._data
	end
	self._loaded:Wait()
	return self._data
end

function Client:Get()
	return self._data
end

return Client
