-- ServerScriptService/Modules/Utilities.lua
local Utils = {}

-- Shuffle a table randomly (Fisher-Yates)
function Utils.ShuffleArray(array)
	for i = #array, 2, -1 do
		local j = math.random(1, i)
		array[i], array[j] = array[j], array[i]
	end
end

-- Wait recursively for a child in a deep hierarchy
function Utils.WaitForChildRecursive(parent, name)
	local found = parent:FindFirstChild(name)
	while not found do
		parent.ChildAdded:Wait()
		found = parent:FindFirstChild(name)
	end
	return found
end

-- Format time (seconds) into mm:ss
function Utils.FormatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

-- Deep clone a table (copy nested tables)
function Utils.DeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = Utils.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- Check if value exists in array
function Utils.Contains(array, value)
	for _, v in pairs(array) do
		if v == value then
			return true
		end
	end
	return false
end

-- Count elements in a table
function Utils.Count(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

return Utils