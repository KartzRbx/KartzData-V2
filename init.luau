local RunService = game:GetService("RunService")

local DataService = {}

if RunService:IsServer() then
	DataService.Server = require(script.Server)
else
	DataService.Client = require(script.Client)
end

return DataService
