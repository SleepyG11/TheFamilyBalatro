TheFamily = setmetatable({
	version = "0.1.1f",
}, {})

TheFamily.SWITCH_OVERLAYS = {
	JOKERS = "vanilla_jokers",
	CONSUMEABLES = "vanilla_consumeables",
	DECK = "vanilla_deck",
	TAGS = "vanilla_skip_tags",

	SHOP = "vanilla_shop",
	BOOSTER = "vanilla_booster",
	BLINDS = "vanilla_blinds",
	HAND = "vanilla_hand",
	CASH_OUT = "vanilla_cashout",

	UNDER_CONSUMEABLES = "not_taken_under_consumeables",
}

require("thefamily/utils")
require("thefamily/config")
require("thefamily/ui")
require("thefamily/group")
require("thefamily/tab")
require("thefamily/cardarea")
require("thefamily/test")

------------------------------

TheFamily.tabs = {
	--- @type table<string, TheFamilyTab>
	dictionary = {},
	--- @type TheFamilyTab[]
	list = {},
}
TheFamily.tab_groups = {
	--- @type table<string, TheFamilyGroup>
	dictionary = {},
	--- @type TheFamilyGroup[]
	list = {},
}
TheFamily.enabled_tabs = {
	--- @type table<string, TheFamilyGroup>
	dictionary = {},
	--- @type TheFamilyGroup[]
	list = {},
}
function TheFamily.toggle_and_sort_tabs()
	for _, tab in ipairs(TheFamily.tabs.list) do
		if not tab:enabled() then
			tab.is_enabled = false
		else
			tab.is_enabled = true
		end
	end
	table.sort(TheFamily.tabs.list, function(a, b)
		return not a.order or not b.order or a.order < b.order
	end)
end
function TheFamily.toggle_and_sort_tab_groups()
	table.sort(TheFamily.tab_groups.list, function(a, b)
		return not a.order or not b.order or a.order < b.order
	end)
	for _, group in ipairs(TheFamily.tab_groups.list) do
		if not group:enabled() then
			group.is_enabled = false
		else
			group.is_enabled = true
		end
		table.sort(group.tabs.list, function(a, b)
			return not a.order or not b.order or a.order < b.order
		end)
		EMPTY(group.enabled_tabs.list)
		EMPTY(group.enabled_tabs.dictionary)
		if group.is_enabled then
			for _, tab in ipairs(group.tabs.list) do
				if tab.is_enabled then
					table.insert(group.enabled_tabs.list, tab)
					group.enabled_tabs.dictionary[tab.key] = tab
				end
			end
		end
		table.sort(group.enabled_tabs.list, function(a, b)
			return not a.order or not b.order or a.order < b.order
		end)
	end
end
function TheFamily.toggle_and_sort_enabled_tabs()
	EMPTY(TheFamily.enabled_tabs.list)
	EMPTY(TheFamily.enabled_tabs.dictionary)
	for _, group in ipairs(TheFamily.tab_groups.list) do
		if group.is_enabled then
			for _, tab in ipairs(group.tabs.list) do
				if tab.is_enabled then
					table.insert(TheFamily.enabled_tabs.list, tab)
					TheFamily.enabled_tabs.dictionary[tab.key] = tab
				end
			end
		end
	end
end

--- @param config TheFamilyGroupOptions
--- @return TheFamilyGroup
function TheFamily.create_tab_group(config)
	return TheFamilyGroup(config)
end
--- @param config TheFamilyTabOptions
--- @return TheFamilyTab
function TheFamily.create_tab(config)
	return TheFamilyTab(config)
end

function TheFamily.emplace_steamodded()
	TheFamily.current_mod = SMODS.current_mod
	TheFamily.current_mod.config_tab = function()
		return TheFamily.UI.get_options_tabs()[1].tab_definition_function
	end
	TheFamily.current_mod.extra_tabs = function()
		local result = TheFamily.UI.get_options_tabs()
		table.remove(result, 1)
		return result
	end
end

function TheFamily.init()
	TheFamily.toggle_and_sort_tabs()
	TheFamily.toggle_and_sort_tab_groups()
	TheFamily.toggle_and_sort_enabled_tabs()

	local ui_values = TheFamily.UI.get_ui_values()
	TheFamily.UI.max_page = math.ceil(#TheFamily.enabled_tabs.list / ui_values.tabs_per_page)
	TheFamily.UI.page = 1

	TheFamily.own_tabs.time_tracker.last_hand = 0
	TheFamily.own_tabs.time_tracker.this_run_start = G.TIMERS.UPTIME or 0

	TheFamilyCardArea():init_cards()
end
function TheFamily.rerender_area()
	if not TheFamily.UI.area or G.SETTINGS.paused then
		return
	end
	TheFamily.toggle_and_sort_tabs()
	TheFamily.toggle_and_sort_tab_groups()
	TheFamily.toggle_and_sort_enabled_tabs()

	local ui_values = TheFamily.UI.get_ui_values()
	if ui_values.position_on_screen == "bottom" or ui_values.position_on_screen == "top" then
		TheFamily.UI.tabs_per_page = 22
	else
		TheFamily.UI.tabs_per_page = 15
	end
	ui_values = TheFamily.UI.get_ui_values()

	TheFamily.UI.max_page = math.ceil(#TheFamily.enabled_tabs.list / ui_values.tabs_per_page)
	TheFamily.UI.page = math.min(TheFamily.UI.max_page, TheFamily.UI.page)

	local rerender_data = TheFamily.UI.area:_save_rerender_data()
	TheFamily.UI.area:safe_remove()
	TheFamilyCardArea():init_cards(rerender_data)
end

------------------------------

local wheel_moved_ref = love.wheelmoved or function() end
function love.wheelmoved(x, y)
	wheel_moved_ref(x, y)
	if TheFamily.UI.area then
		TheFamily.UI.area:_scroll(y)
	end
end

local start_run_ref = Game.start_run
function Game:start_run(...)
	start_run_ref(self, ...)
	TheFamily.init()
end

------------------------------

require("thefamily/tabs")
