-- Tabs definitions

TheFamily.UI.get_config_tab_overall = function()
	return {
		TheFamily.UI.PARTS.create_option_cycle(
			"Tabs display mode",
			{ "Scrollable", "Pages" },
			TheFamily.cc.pagination_type,
			"thefamily_change_pagination_type"
		),
		TheFamily.UI.PARTS.create_option_cycle(
			"Position on screen",
			{ "Left", "Right" },
			TheFamily.cc.position_on_screen,
			"thefamily_change_screen_position"
		),
		TheFamily.UI.PARTS.create_option_cycle(
			"UI scale",
			{ "1x", "1.1x", "1.2x" },
			TheFamily.cc.scaling,
			"thefamily_change_scaling"
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
