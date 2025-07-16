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

	self.original_mod_id = params.original_mod_id or (SMODS and SMODS.current_mod and SMODS.current_mod.id) or nil
	self.loc_txt = params.loc_txt or {}

	self.center = params.center or nil
	self.front = params.front or nil

	self.enabled = only_function(params.enabled, self.enabled)

	self.can_be_disabled = params.can_be_disabled or false
	self.disabled_change = only_function(params.disabled_change, self.disabled_change)

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
	local card

	TheFamily.__prevent_used_jokers = true
	if self.center or self.front then
		if type(self.center) == "function" then
			card = self:center(area)
				or Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_base, {
					bypass_discovery_center = true,
					bypass_discovery_ui = true,
					discover = false,
				})
		else
			card = Card(
				area.T.x + area.T.w / 2,
				area.T.y,
				G.CARD_W,
				G.CARD_H,
				self.front and G.P_CARDS[self.front] or nil,
				G.P_CENTERS[self.center or ""] or G.P_CENTERS.c_base,
				{
					bypass_discovery_center = true,
					bypass_discovery_ui = true,
					discover = false,
				}
			)
		end
	elseif self.tabs.list[1] then
		card = self.tabs.list[1]:create_card(area)
	end
	TheFamily.__prevent_used_jokers = nil

	if card then
		card.thefamily_group = self
	end

	return card
end

function TheFamilyGroup:prepare_config_card(card)
	if not card then
		return
	end
	function card:align_h_popup()
		return {}
	end
	function card:hover()
		local group = self.thefamily_group
		if not self.children.popup then
			local current_mod = group.original_mod_id and SMODS and SMODS.Mods[group.original_mod_id]
			local localization = TheFamily.utils.resolve_loc_txt(group.loc_txt)
			local title = localization.name or (current_mod and string.format("%s's group", current_mod.name)) or nil

			local is_enabled = group:enabled()
			local is_disabled_by_user = group:_disabled_by_user()

			local result_content = {
				title and name_from_rows({
					{
						n = G.UIT.T,
						config = {
							text = title,
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				}) or nil,
				localization.description and desc_from_rows({
					{
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = TheFamily.UI.localize_text(localization.description, {
								align = "cm",
							}),
						},
					},
				}) or nil,
				desc_from_rows({
					{
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = TheFamily.UI.localize_text({
								"Adds {C:attention}#1#{} tabs",
							}, {
								align = "cm",
								vars = { #group.tabs.list },
							}),
						},
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = TheFamily.UI.localize_text({
								"{V:1}#1#{} / {V:2}#2#{}",
							}, {
								align = "cm",
								vars = {
									is_enabled and "Active" or "Inactive",
									(not group.can_be_disabled) and "Cannot be disabled"
										or (not is_disabled_by_user) and "Enabled"
										or "Disabled",
									colours = {
										is_enabled and G.C.GREEN or G.C.MULT,
										(not group.can_be_disabled) and G.C.FILTER
											or (not is_disabled_by_user) and G.C.GREEN
											or G.C.MULT,
									},
								},
							}),
						},
					},
				}),
			}
			if current_mod and current_mod.display_name and current_mod.badge_colour then
				table.insert(result_content, TheFamily.UI.PARTS.create_mod_badge(current_mod))
			end

			local popup = {
				n = G.UIT.ROOT,
				config = { align = "cm", colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.R,
								config = {
									padding = 0.05,
									r = 0.12,
									colour = lighten(G.C.JOKER_GREY, 0.5),
									emboss = 0.07,
								},
								nodes = {
									{
										n = G.UIT.R,
										config = {
											align = "cm",
											padding = 0.07,
											r = 0.1,
											colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
										},
										nodes = result_content,
									},
								},
							},
						},
					},
				},
			}
			local popup_config = {
				align = "tm",
				offset = { x = 0, y = -0.25 },
				parent = self,
				instance_type = "POPUP",
				xy_bond = "Strong",
				r_bond = "Weak",
				wh_bond = "Weak",
			}

			local box = UIBox({
				definition = popup,
				config = popup_config,
			})

			self.children.popup = box
		end
	end
	function card:stop_hover()
		if self.children.popup then
			self.children.popup:remove()
			self.children.popup = nil
		end
	end
	function card:update_alert() end

	function card:highlight(is_highlighted)
		self.highlighted = is_highlighted
		if self.highlighted and not self.children.use_button then
			self.children.use_button = UIBox({
				definition = {
					n = G.UIT.ROOT,
					config = { padding = 0, colour = G.C.CLEAR },
					nodes = {
						{
							n = G.UIT.R,
							config = {
								ref_table = self,
								r = 0.08,
								padding = 0.1,
								align = "bm",
								minw = 0.5 * self.T.w - 0.15,
								maxw = 0.9 * self.T.w - 0.15,
								minh = 0.3 * self.T.h,
								hover = true,
								shadow = true,
								colour = G.C.UI.BACKGROUND_INACTIVE,
								button = "thefamily_user_toggle_group",
								func = "thefamily_can_user_toggle_group",
							},
							nodes = {
								{
									n = G.UIT.T,
									config = {
										text = "Toggle",
										colour = G.C.UI.TEXT_LIGHT,
										scale = 0.45,
										shadow = true,
									},
								},
							},
						},
					},
				},
				config = {
					align = "bmi",
					offset = { x = 0, y = 0.65 },
					parent = self,
				},
			})
		elseif not self.highlighted and self.children.use_button then
			self.children.use_button:remove()
			self.children.use_button = nil
		end
	end

	card.debuff = self:_disabled_by_user()

	return card
end
function TheFamilyGroup:emplace_config_card(card, area)
	if area and card then
		area:emplace(card)
	end
end
function TheFamilyGroup:create_config_card(area)
	if area then
		self:emplace_config_card(self:prepare_config_card(self:create_card(area)), area)
	end
end

function TheFamilyGroup:_add_tab(tab)
	table.insert(self.tabs.list, tab)
	self.tabs.dictionary[tab.key] = tab
end

function TheFamilyGroup:_enabled()
	return not self:_disabled() and self:enabled()
end
function TheFamilyGroup:_disabled()
	return self:_disabled_by_user()
end
function TheFamilyGroup:_disabled_by_user()
	return self.can_be_disabled and TheFamily.cc.disabled_groups[self.key]
end
function TheFamilyGroup:_toggle_by_user()
	local old_disabled = self:_disabled()
	local old_tabs_disabled = {}
	for _, tab in ipairs(self.tabs.list) do
		old_tabs_disabled[tab.key] = tab:_disabled()
	end
	TheFamily.cc.disabled_groups[self.key] = not TheFamily.cc.disabled_groups[self.key]
	local new_disabled = self:_disabled()
	if not not new_disabled ~= not not old_disabled then
		self:disabled_change(new_disabled)
	end
	for _, tab in ipairs(self.tabs.list) do
		local new_tab_disabled = tab:_disabled()
		if not not new_tab_disabled ~= not not old_tabs_disabled[tab.key] then
			tab:disabled_change(new_tab_disabled, true)
		end
	end
end
function TheFamilyGroup:enabled()
	return true
end
function TheFamilyGroup:disabled_change(new_value) end
