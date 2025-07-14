TheFamily.utils = {}

--- @generic T
--- @generic S
--- @param target T
--- @param source S
--- @param ... any
--- @return T | S
function TheFamily.utils.table_merge(target, source, ...)
	assert(type(target) == "table", "Target is not a table")
	local tables_to_merge = { source, ... }
	if #tables_to_merge == 0 then
		return target
	end

	for k, t in ipairs(tables_to_merge) do
		assert(type(t) == "table", string.format("Expected a table as parameter %d", k))
	end

	for i = 1, #tables_to_merge do
		local from = tables_to_merge[i]
		for k, v in pairs(from) do
			if type(v) == "table" then
				target[k] = target[k] or {}
				target[k] = TheFamily.utils.table_merge(target[k], v)
			else
				target[k] = v
			end
		end
	end

	return target
end

function TheFamily.utils.table_contains(t, value)
	for i = #t, 1, -1 do
		if t[i] and t[i] == value then
			return true
		end
	end
	return false
end

function TheFamily.utils.serialize_string(s)
	return string.format("%q", s)
end

function TheFamily.utils.serialize(t, indent)
	indent = indent or ""
	local str = "{\n"
	for k, v in ipairs(t) do
		str = str .. indent .. "\t"
		if type(v) == "number" then
			str = str .. v
		elseif type(v) == "boolean" then
			str = str .. (v and "true" or "false")
		elseif type(v) == "string" then
			str = str .. TheFamily.utils.serialize_string(v)
		elseif type(v) == "table" then
			str = str .. TheFamily.utils.serialize(v, indent .. "\t")
		else
			-- not serializable
			str = str .. "nil"
		end
		str = str .. ",\n"
	end
	for k, v in pairs(t) do
		if type(k) == "string" then
			str = str .. indent .. "\t" .. "[" .. TheFamily.utils.serialize_string(k) .. "] = "

			if type(v) == "number" then
				str = str .. v
			elseif type(v) == "boolean" then
				str = str .. (v and "true" or "false")
			elseif type(v) == "string" then
				str = str .. TheFamily.utils.serialize_string(v)
			elseif type(v) == "table" then
				str = str .. TheFamily.utils.serialize(v, indent .. "\t")
			else
				-- not serializable
				str = str .. "nil"
			end
			str = str .. ",\n"
		end
	end
	str = str .. indent .. "}"
	return str
end

function TheFamily.utils.as_array(t)
	return type(t) == "table" and t or { t }
end

function TheFamily.utils.table_slice(t, n)
	local sliced = {}
	for i = #t, n + 1, -1 do
		table.insert(sliced, t[i])
		t[i] = nil
	end
	return t, sliced
end
function TheFamily.utils.table_copy_part(t, from_index, to_index)
	local result = {}
	for i = from_index, to_index - 1 do
		result[#result + 1] = t[i]
	end
	return result
end
function TheFamily.utils.first_non_zero(...)
	local values = { ... }
	for _, value in ipairs(values) do
		if value ~= 0 then
			return value
		end
	end
	return 0
end
