local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("signal"))

local Path = require(script.Parent.Path)
local Enums = require(script.Parent.Enums)

type SignalT = typeof(Signal.new())

local Data = {}
Data.__index = Data

export type DataPath = Path.Path

local READ_ONLY_ERROR = "DataService: Data on the client is read-only. Mutations are server-driven."

function Data.new(initial: any, writable: boolean?)
	local self = setmetatable({
		_root = initial,
		_writable = writable ~= false,
		_changed = {} :: { [string]: SignalT },
		_indexChanged = {} :: { [string]: SignalT },
		_arrayInserted = {} :: { [string]: SignalT },
		_arrayRemoved = {} :: { [string]: SignalT },
		Changed = Signal.new(),
		Destroyed = false,
	}, Data)
	return self
end

local function descend(root: any, path: DataPath?, ensureLeaf: boolean): (any?, any?)
	if not path or #path == 0 then
		return nil, nil
	end
	local parent = root
	for i = 1, #path - 1 do
		local k = path[i]
		if type(parent[k]) ~= "table" then
			if ensureLeaf then
				parent[k] = {}
			else
				return nil, nil
			end
		end
		parent = parent[k]
	end
	return parent, path[#path]
end

function Data:Get(path: DataPath?): any
	if not path or #path == 0 then
		return self._root
	end
	local cur: any = self._root
	for _, k in path do
		if type(cur) ~= "table" then
			return nil
		end
		cur = cur[k]
	end
	return cur
end

function Data:_fireChanged(path: DataPath, newValue: any, oldValue: any)
	if newValue == oldValue then
		return
	end
	local key = Path.toKey(path)
	local sig = self._changed[key]
	if sig then
		sig:Fire(newValue, oldValue)
	end
	if #path > 0 then
		local parentKey = Path.toKey(Path.parent(path))
		local idx = self._indexChanged[parentKey]
		if idx then
			idx:Fire(path[#path], newValue, oldValue)
		end
	end
end

function Data:_applySet(path: DataPath, value: any)
	assert(path and #path > 0, "Data: path must be non-empty")
	local parent, key = descend(self._root, path, true)
	local old = parent[key]
	parent[key] = value
	self:_fireChanged(path, value, old)
end

function Data:_applyArrayInsert(path: DataPath, value: any, index: number?)
	local arr = self:Get(path)
	assert(type(arr) == "table", "Data: ArrayInsert requires an array path")
	if index then
		table.insert(arr, index, value)
	else
		table.insert(arr, value)
		index = #arr
	end
	local sig = self._arrayInserted[Path.toKey(path)]
	if sig then
		sig:Fire(index, value)
	end
end

function Data:_applyArrayRemove(path: DataPath, index: number): any
	local arr = self:Get(path)
	assert(type(arr) == "table", "Data: ArrayRemove requires an array path")
	local removed = table.remove(arr, index)
	local sig = self._arrayRemoved[Path.toKey(path)]
	if sig then
		sig:Fire(index, removed)
	end
	return removed
end

function Data:Set(path: DataPath, value: any)
	assert(self._writable, READ_ONLY_ERROR)
	self:_applySet(path, value)
	self.Changed:Fire(Enums.Set, path, value)
end

function Data:Update(path: DataPath, fn: (any) -> any): any
	assert(self._writable, READ_ONLY_ERROR)
	local current = self:Get(path)
	local new = fn(current)
	self:Set(path, new)
	return new
end

function Data:ArrayInsert(path: DataPath, value: any, index: number?)
	assert(self._writable, READ_ONLY_ERROR)
	local arr = self:Get(path)
	assert(type(arr) == "table", "Data:ArrayInsert requires an array path")
	if index then
		table.insert(arr, index, value)
	else
		table.insert(arr, value)
		index = #arr
	end
	local sig = self._arrayInserted[Path.toKey(path)]
	if sig then
		sig:Fire(index, value)
	end
	self.Changed:Fire(Enums.ArrayInsert, path, value, index)
end

function Data:ArrayRemove(path: DataPath, index: number): any
	assert(self._writable, READ_ONLY_ERROR)
	local arr = self:Get(path)
	assert(type(arr) == "table", "Data:ArrayRemove requires an array path")
	local removed = table.remove(arr, index)
	local sig = self._arrayRemoved[Path.toKey(path)]
	if sig then
		sig:Fire(index, removed)
	end
	self.Changed:Fire(Enums.ArrayRemove, path, index)
	return removed
end

local function ensureSignal(map: { [string]: SignalT }, key: string): SignalT
	if not map[key] then
		map[key] = Signal.new()
	end
	return map[key]
end

function Data:GetChangedSignal(path: DataPath): SignalT
	return ensureSignal(self._changed, Path.toKey(path))
end

function Data:GetIndexChangedSignal(path: DataPath): SignalT
	return ensureSignal(self._indexChanged, Path.toKey(path))
end

function Data:GetArrayInsertedSignal(path: DataPath): SignalT
	return ensureSignal(self._arrayInserted, Path.toKey(path))
end

function Data:GetArrayRemovedSignal(path: DataPath): SignalT
	return ensureSignal(self._arrayRemoved, Path.toKey(path))
end

function Data:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	for _, s in self._changed do
		s:Destroy()
	end
	for _, s in self._indexChanged do
		s:Destroy()
	end
	for _, s in self._arrayInserted do
		s:Destroy()
	end
	for _, s in self._arrayRemoved do
		s:Destroy()
	end
	self.Changed:Destroy()
end

export type Data = typeof(Data.new(nil))
return Data
