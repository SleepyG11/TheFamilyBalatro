TheFamilyGroup = Object:extend()

local load_index = 1

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
	self.load_index = load_index
	load_index = load_index + 1

	self.original_mod = SMODS and SMODS.current_mod or nil

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

function TheFamilyGroup:create_card(area)
	if not self.tabs.list[1] then
		return nil
	end
	local center = self.center or self.tabs.list[1].center or "c_base"
	local front = self.front or self.tabs.list[1].front or nil

	TheFamily.__prevent_used_jokers = true
	if type(center) == "string" then
		card = Card(
			area.T.x + area.T.w / 2,
			area.T.y,
			G.CARD_W,
			G.CARD_H,
			front and G.P_CARDS[front] or nil,
			G.P_CENTERS[center] or G.P_CENTERS.c_base,
			{
				bypass_discovery_center = true,
				bypass_discovery_ui = true,
				discover = false,
			}
		)
	elseif type(center) == "function" then
		card = center(self, area)
			or Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_base, {
				bypass_discovery_center = true,
				bypass_discovery_ui = true,
				discover = false,
			})
	end
	card.no_shadow = true
	TheFamily.__prevent_used_jokers = nil

	card.thefamily_group = self

	function card:align_h_popup()
		return {}
	end
	function card:hover() end
	function card:stop_hover() end
	function card:update_alert() end
	function card:stop_drag()
		TheFamily.save_groups_order(self.area)
	end

	return card
end

function TheFamilyGroup:_add_tab(tab)
	table.insert(self.tabs.list, tab)
	self.tabs.dictionary[tab.key] = tab
end

function TheFamilyGroup:enabled()
	return true
end
