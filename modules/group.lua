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
	local this = self
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
	function card:hover()
		if not self.children.popup then
			local current_mod = this.original_mod_id and SMODS and SMODS.Mods[this.original_mod_id]
			local localization = (
				this.loc_txt and this.loc_txt[G.SETTINGS.language]
				or this.loc_txt["en-us"]
				or this.loc_txt
			) or {}
			local title = localization.name or (current_mod and string.format("%s's group", current_mod.name)) or nil
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
							nodes = TheFamily.UI.localize_text(this.loc_txt.description, {
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
								vars = { #this.tabs.list },
							}),
						},
					},
				}),
			}
			if current_mod and current_mod.display_name and current_mod.badge_colour then
				table.insert(
					result_content,
					create_badge(current_mod.display_name, current_mod.bagde_colour, current_mod.badge_text_colour)
				)
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
