-- Tabs definitions

TheFamily.UI.get_config_tab_overall = function()
	return {
		TheFamily.UI.PARTS.create_option_cycle(
			"Tabs display mode",
			{ "Pages", "Scrollable" },
			TheFamily.cc.pagination_type,
			"thefamily_change_pagination_type"
		),
	}
end

-- Tabs order

TheFamily.UI.PARTS.tabs_list = {
	["Overall"] = {
		definition = function()
			return TheFamily.UI.get_config_tab_overall()
		end,
	},
}
TheFamily.UI.PARTS.tabs_order = {
	"Overall",
}

-- Getters

function TheFamily.UI.get_config_tab(_tab, _index)
	local result = {
		n = G.UIT.ROOT,
		config = { align = "cm", padding = 0.05, colour = G.C.CLEAR, minh = 5, minw = 5 },
		nodes = {},
	}
	TheFamily.UI.config_tab_index = _index
	result.nodes = TheFamily.UI.PARTS.tabs_list[_tab].definition()
	return result
end
function TheFamily.UI.get_options_tabs()
	local result = {}
	for index, k in ipairs(TheFamily.UI.PARTS.tabs_order) do
		table.insert(result, {
			label = k,
			tab_definition_function = function()
				return TheFamily.UI.get_config_tab(k, index)
			end,
		})
	end
	return result
end
