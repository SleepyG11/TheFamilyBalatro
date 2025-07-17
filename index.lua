TheFamily = setmetatable({
	version = "0.1.2",
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

function TheFamily.toggle_and_sort_tabs_and_groups()
	EMPTY(TheFamily.enabled_tabs.list)
	EMPTY(TheFamily.enabled_tabs.dictionary)

	local get_tab_order = function(tab)
		return tab
				and tab.group
				and TheFamily.cc.tabs_order[tab.group.key]
				and TheFamily.cc.tabs_order[tab.group.key][tab.key]
			or 0
	end
	local get_group_order = function(group)
		return group and TheFamily.cc.groups_order[group.key] or 0
	end

	table.sort(TheFamily.tabs.list, function(a, b)
		return TheFamily.utils.first_non_zero(
			get_tab_order(a) - get_tab_order(b),
			a.order - b.order,
			a.load_index - b.load_index
		) < 0
	end)
	table.sort(TheFamily.tab_groups.list, function(a, b)
		return TheFamily.utils.first_non_zero(
			get_group_order(a) - get_group_order(b),
			a.order - b.order,
			a.load_index - b.load_index
		) < 0
	end)
	for _, group in ipairs(TheFamily.tab_groups.list) do
		table.sort(group.tabs.list, function(a, b)
			return TheFamily.utils.first_non_zero(
				get_tab_order(a) - get_tab_order(b),
				a.order - b.order,
				a.load_index - b.load_index
			) < 0
		end)
		EMPTY(group.enabled_tabs.list)
		EMPTY(group.enabled_tabs.dictionary)
		if group:_enabled() then
			for _, tab in ipairs(group.tabs.list) do
				if tab:_enabled() then
					table.insert(group.enabled_tabs.list, tab)
					group.enabled_tabs.dictionary[tab.key] = tab
					table.insert(TheFamily.enabled_tabs.list, tab)
					TheFamily.enabled_tabs.dictionary[tab.key] = tab
				end
			end
		end
	end
end
function TheFamily.save_groups_order(area)
	local result = {}
	for _, card in ipairs(area.cards) do
		local group = card.thefamily_group
		result[group.key] = card.rank
	end
	TheFamily.config.current.groups_order = result
	TheFamily.config.save()

	TheFamily.rerender_area()
end
function TheFamily.save_tabs_order(area)
	local group = area.cards[1].thefamily_tab.group
	local result = {}
	for _, card in ipairs(area.cards) do
		local tab = card.thefamily_tab
		result[tab.key] = card.rank
	end
	TheFamily.config.current.tabs_order[group.key] = result
	TheFamily.config.save()

	TheFamily.rerender_area()
end

function TheFamily.create_tab_group(config)
	return TheFamilyGroup(config)
end
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
	TheFamily.toggle_and_sort_tabs_and_groups()

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
	TheFamily.toggle_and_sort_tabs_and_groups()

	local ui_values = TheFamily.UI.get_ui_values()
	if ui_values.position_on_screen == "bottom" or ui_values.position_on_screen == "top" then
		TheFamily.UI.tabs_per_page = 22
	else
		TheFamily.UI.tabs_per_page = 15
	end
	ui_values = TheFamily.UI.get_ui_values()

	TheFamily.UI.max_page = math.ceil(#TheFamily.enabled_tabs.list / ui_values.tabs_per_page)
	TheFamily.UI.page = math.max(1, math.min(TheFamily.UI.max_page, TheFamily.UI.page))

	local rerender_data = TheFamily.UI.area:_save_rerender_data()
	TheFamily.UI.area:safe_remove()
	TheFamilyCardArea():init_cards(rerender_data)
end
function TheFamily.process_loc_text()
	G.localization.descriptions["TheFamily_Group"] = G.localization.descriptions["TheFamily_Group"] or {}
	G.localization.descriptions["TheFamily_Tab"] = G.localization.descriptions["TheFamily_Tab"] or {}

	for _, group in ipairs(TheFamily.tab_groups.list) do
		group:process_loc_text()
	end
	for _, tab in ipairs(TheFamily.tabs.list) do
		tab:process_loc_text()
	end
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

local init_localization_ref = init_localization
function init_localization(...)
	if not G.localization.__thefamily_injected then
		TheFamily.process_loc_text()
		-- local en_loc = require("handy/localization/en-us")
		-- TheFamily.utils.table_merge(G.localization, en_loc)
		-- TheFamily.UI.cache_config_dictionary_search()
		-- if G.SETTINGS.language ~= "en-us" then
		-- local success, current_loc = pcall(function()
		-- 	return require("handy/localization/" .. G.SETTINGS.language)
		-- end)
		-- local missing_keys = TheFamily.utils.deep_missing_keys(en_loc, current_loc)
		-- for _, missing_key in ipairs(missing_keys) do
		-- 	print("Missing key: " .. missing_key)
		-- end
		-- if success and current_loc then
		-- 	TheFamily.utils.table_merge(G.localization, current_loc)
		-- 	TheFamily.UI.cache_config_dictionary_search(true)
		-- end
		-- end
		G.localization.__thefamily_injected = true
	end
	return init_localization_ref(...)
end

------------------------------

require("thefamily/tabs")
