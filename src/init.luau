const RunService = game:GetService("RunService")

const Path = require(script.Path)

local function createUnavailableContext(contextName: string)
	local rootPaths = Path.rootToken()

	return {
		Init = function()
			error(`DataService.{contextName}:Init is not available in this runtime context`, 2)
		end,
		WaitFor = function()
			error(`DataService.{contextName}:WaitFor is not available in this runtime context`, 2)
		end,
		WaitForData = function()
			error(`DataService.{contextName}:WaitForData is not available in this runtime context`, 2)
		end,
		Get = function()
			error(`DataService.{contextName}:Get is not available in this runtime context`, 2)
		end,
		GetBufferStats = function()
			return nil
		end,
		Destroy = function() end,
		Paths = rootPaths,
	}
end

const DataService = {
	Paths = Path.rootToken(),
	Enum = require(script.Enum),
}

if RunService:IsServer() then
	const Server = require(script.Server)
	DataService.Server = Server
	DataService.Client = createUnavailableContext("Client")
	DataService.Paths = Server.Paths
else
	const Client = require(script.Client)
	DataService.Client = Client
	DataService.Server = createUnavailableContext("Server")
	DataService.Paths = Client.Paths
end

return DataService
