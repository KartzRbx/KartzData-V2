local Path = {}

export type Path = { string | number }

function Path.toKey(path: Path?): string
	if not path or #path == 0 then
		return ""
	end
	local parts = table.create(#path)
	for i, v in path do
		if type(v) == "string" then
			parts[i] = "s\1" .. v
		else
			parts[i] = "n\1" .. tostring(v)
		end
	end
	return table.concat(parts, "\0")
end

function Path.clone(path: Path?): Path
	if not path then
		return {}
	end
	local out = table.create(#path)
	for i, v in path do
		out[i] = v
	end
	return out
end

function Path.parent(path: Path): Path
	local out = table.create(math.max(#path - 1, 0))
	for i = 1, #path - 1 do
		out[i] = path[i]
	end
	return out
end

return Path
