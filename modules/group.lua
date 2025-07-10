TheFamilyGroup = Object:extend()

--- @param params TheFamilyGroupOptions
function TheFamilyGroup:init(params)
	if TheFamily.tab_groups.dictionary[params.key] then
		print(string.format("[TheFamily]: Duplicate group key: %s", params.key))
	end

	local function only_function(a, b)
		return type(a) == "function" and a or b
	end

	self.key = params.key
	self.order = params.order or #TheFamily.tab_groups.list

	self.enabled = only_function(params.enabled, self.enabled)
	self.is_enabled = false

	self.tabs = {
		list = {},
		dictionary = {},
	}
	self.enabled_tabs = {
		list = {},
		dictionary = {},
	}

	if self.key then
		table.insert(TheFamily.tab_groups.list, self)
		TheFamily.tab_groups.dictionary[self.key] = self
	end
end

function TheFamilyGroup:_add_tab(tab)
	table.insert(self.tabs.list, tab)
	self.tabs.dictionary[tab.key] = tab
end

function TheFamilyGroup:enabled()
	return true
end
