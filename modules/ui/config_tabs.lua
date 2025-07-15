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
			{ "Right", "Left" },
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
TheFamily.UI.get_config_tab_groups_order = function()
	TheFamily.toggle_and_sort_tabs_and_groups()

	local area = TheFamily.UI.PARTS.create_groups_order_area()

	for _, group in ipairs(TheFamily.tab_groups.list) do
		group:create_config_card(area)
	end

	return {
		{
			n = G.UIT.R,
			config = {
				align = "cm",
				pading = 0.05,
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = "Rearrange cards to change tabs display order",
						scale = 0.4,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
		TheFamily.UI.PARTS.create_separator_r(),
		{
			n = G.UIT.R,
			config = {
				align = "cm",
				colour = adjust_alpha(G.C.BLACK, 0.5),
				padding = 0.05,
				r = 0.1,
			},
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = area,
						align = "cm",
					},
				},
			},
		},
	}
end

-- Tabs order

TheFamily.UI.PARTS.tabs_list = {
	["Overall"] = {
		definition = function()
			return TheFamily.UI.get_config_tab_overall()
		end,
	},
	["Groups order"] = {
		definition = function()
			return TheFamily.UI.get_config_tab_groups_order()
		end,
	},
}
TheFamily.UI.PARTS.tabs_order = {
	"Overall",
	"Groups order",
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
