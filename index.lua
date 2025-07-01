TheFamily = setmetatable({
	version = "0.1.0",
}, {})

TheFamily.tabs = {
	dictionary = {},
	list = {},
}
TheFamily.tab_groups = {
	dictionary = {},
	list = {},
}

TheFamily.UI = {
	r = -70,
	gap = 0.53,
	scale = 0.4,

	get_ui_values = function()
		return {
			r_deg = TheFamily.UI.r,
			r_rad = math.rad(TheFamily.UI.r),
			gap = TheFamily.UI.gap,
			scale = TheFamily.UI.scale,
		}
	end,

	page = 1,
	items_per_page = 20,
	utility_cards_per_page = 5,
	tabs_per_page = 15,

	area = nil,
	area_container = nil,

	if_first_card_selected = function()
		if not TheFamily.UI.area then
			return false
		end
		local card = (TheFamily.UI.area.cards or {})[1]
		return card and card.highlighted
	end,
	is_any_card_hovered = function()
		if not TheFamily.UI.area then
			return false
		end
		for _, card in ipairs(TheFamily.UI.area.cards or {}) do
			if card and card.states.hover.is then
				return true
			end
		end
		return false
	end,

	create_card_area = function()
		local selector_area = CardArea(0, 0, G.CARD_W * 0.5, G.CARD_H * 0.5, {
			card_limit = 25,
			type = "hand",
			highlight_limit = 1,
		})
		function selector_area:align_cards(...)
			if not self.cards or not self.cards[1] then
				return
			end
			self.thefamily_is_first_card_selected = TheFamily.UI.if_first_card_selected()
			self.thefamily_is_any_card_hovered = TheFamily.UI.is_any_card_hovered()
			for index, card in ipairs(self.cards) do
				TheFamily.UI.set_card_position({
					card = card,
					index = index,
				})
			end
		end
		local old_remove_from = selector_area.remove_from_highlighted
		function selector_area:remove_from_highlighted(card)
			old_remove_from(self, card)
			if type(card.thefamily_definition.unhighlight) == "function" then
				card.thefamily_definition.unhighlight(card.thefamily_definition, card)
			end
			if card.states.hover.is and type(card.thefamily_definition.popup) == "function" then
				if card.children.h_popup then
					card.config.h_popup = nil
					card.children.h_popup:remove()
					card.children.h_popup = nil
				end
				TheFamily.UI.set_card_h_popup(card.thefamily_definition, card)
			end
		end
		function selector_area:add_to_highlighted(card, silent)
			if not self.cards or not self.cards[1] then
				return
			end

			if
				type(card.thefamily_definition.can_highlight) == "function"
				and not card.thefamily_definition.can_highlight(card.thefamily_definition, card)
			then
				return
			end

			-- First card can be selected over limit
			local is_first_selected = self.cards[1].highlighted
			if
				card ~= self.cards[1]
				and (#self.highlighted - (is_first_selected and 1 or 0) >= self.config.highlighted_limit)
			then
				-- search for eligible card for deselect
				for _, highlighted_card in ipairs(self.highlighted) do
					if highlighted_card ~= self.cards[1] then
						self:remove_from_highlighted(highlighted_card)
						break
					end
				end
			end
			self.highlighted[#self.highlighted + 1] = card
			card.highlighted = true
			if type(card.thefamily_definition.highlight) == "function" then
				card.thefamily_definition.highlight(card.thefamily_definition, card)
			end

			if
				(card.thefamily_definition.keep_popup_when_highlighted or card.states.hover.is)
				and type(card.thefamily_definition.popup) == "function"
			then
				if card.children.h_popup then
					card.config.h_popup = nil
					card.children.h_popup:remove()
					card.children.h_popup = nil
				end
				TheFamily.UI.set_card_h_popup(card.thefamily_definition, card)
			end

			if not silent then
				play_sound("cardSlide1")
			end
		end
		function selector_area:draw()
			if not self.states.visible then
				return
			end

			self:draw_boundingrect()
			add_to_drawhash(self)

			self.ARGS.draw_layers = self.ARGS.draw_layers or self.config.draw_layers or { "card" }
			for k, v in ipairs(self.ARGS.draw_layers) do
				for i = 1, #self.cards do
					if self.cards[i] ~= G.CONTROLLER.focused.target or self == G.hand then
						if G.CONTROLLER.dragging.target ~= self.cards[i] then
							self.cards[i]:draw(v)
						end
					end
				end
			end
		end
		if TheFamily.UI.area then
			TheFamily.UI.area:remove()
		end
		TheFamily.UI.area = selector_area
		return selector_area
	end,
	create_card_area_container = function()
		local area_container = UIBox({
			definition = {
				n = G.UIT.ROOT,
				config = { colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.O,
						config = {
							object = TheFamily.UI.area,
						},
					},
				},
			},
			config = {
				align = "tr",
				major = G.ROOM_ATTACH,
				bond = "Weak",
				offset = {
					x = 0,
					y = 1,
				},
			},
		})
		area_container.T.r = math.pi / 2
		if TheFamily.UI.area_container then
			TheFamily.UI.area_container:remove()
		end
		TheFamily.UI.area_container = area_container
		return area_container
	end,

	set_card_position = function(options)
		-- TODO: decide how this should looks like, actually
		options = options or {}
		local card = options.card
		local index = options.index or 1
		local force_position = options.force_position
		local is_first_card_selected = TheFamily.UI.area.thefamily_is_first_card_selected
		local is_any_card_hovered = TheFamily.UI.area.thefamily_is_any_card_hovered

		local rotate_angle = math.rad(TheFamily.UI.r)
		local highlight_dx = 0
		if index == 1 then
			-- Always visible
			highlight_dx = card.highlighted and -0.2 or 0
		else
			if card.highlighted then
				-- Visible only if highlighted, but only on a half I guess
				highlight_dx = is_first_card_selected and -0.3 or is_any_card_hovered and -0.2 or 0
			else
				highlight_dx = is_first_card_selected and -0.2 or is_any_card_hovered and 0 or 0.2
			end
		end
		if card.states.hover.is then
			highlight_dx = highlight_dx - 0.075
		end
		if card.highlighted then
			highlight_dx = (is_first_card_selected or is_any_card_hovered) and -0.425 or -0.2
		end
		card.states.drag.can = false
		card.T.x = TheFamily.UI.area.T.x
			- (highlight_dx * math.sin(rotate_angle))
			+ G.ROOM.T.x
			- G.CARD_W * (TheFamily.UI.scale - 0.5)
			- G.CARD_H / 2 * TheFamily.UI.scale
		card.T.y = TheFamily.UI.area.T.y + (highlight_dx * math.cos(rotate_angle)) + TheFamily.UI.gap * index
		card.T.r = rotate_angle
		if force_position then
			-- TODO: force correct rotation
			card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h)
		end
	end,
	set_card_h_popup = function(definition, card)
		local popup_definitions = definition.popup(definition, card) or {}

		local result_content = {
			popup_definitions.name and name_from_rows(popup_definitions.name) or nil,
		}
		for _, item in ipairs(popup_definitions.description or {}) do
			table.insert(
				result_content,
				desc_from_rows({
					item,
				})
			)
		end

		card.config.h_popup_config = card:align_h_popup()
		card.config.h_popup = {
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
		if not card.children.h_popup then
			card.config.h_popup_config.instance_type = "POPUP"
			card.children.h_popup = UIBox({
				definition = card.config.h_popup,
				config = card.config.h_popup_config,
			})
			card.children.h_popup.states.collide.can = false
			card.children.h_popup.states.drag.can = true
		end
	end,
	set_card_update = function(definition, card)
		function card:align_h_popup()
			return {
				align = "cl",
				offset = { x = -0.25, y = 0 },
				major = card,
				xy_bond = "Strong",
				r_bond = "Weak",
				wh_bond = "Weak",
			}
		end
		function card:hover()
			if type(definition.popup) == "function" then
				TheFamily.UI.set_card_h_popup(definition, card)
			end
		end
		function card:stop_hover()
			if definition.keep_popup_when_highlighted then
				return
			end
			if self.children.h_popup then
				self.children.h_popup:remove()
				self.children.h_popup = nil
			end
		end

		function card:update_alert() end

		local old_update = card.update
		function card:update(dt, ...)
			old_update(self, dt, ...)

			if
				self.highlighted
				and type(definition.can_highlight) == "function"
				and not definition.can_highlight(definition, self)
			then
				TheFamily.UI.area:remove_from_highlighted(self)
			end

			if type(definition.update) == "function" then
				definition.update(definition, self, dt)
			end

			if
				self.highlighted
				and definition.keep_popup_when_highlighted
				and type(definition.popup) == "function"
				and not self.children.h_popup
			then
				TheFamily.UI.set_card_h_popup(definition, card)
			elseif not self.highlighted and not self.states.hover.is and self.children.h_popup then
				self.config.h_popup = nil
				self.children.h_popup:remove()
				self.children.h_popup = nil
			end

			if type(definition.alert) == "function" then
				if not self.children.alert then
					local args = definition.alert(definition, self) or {}
					local content, config
					if args.definition then
						content, config = args.definition, args.definition_config
					end
					config = config
						or {
							offset = {
								x = -0.1 * TheFamily.UI.scale,
								y = -0.1 * TheFamily.UI.scale,
							},
						}
					content = content
						or {
							n = G.UIT.R,
							config = {
								align = "cm",
								r = 0.15 * TheFamily.UI.scale,
								minw = 0.42 * TheFamily.UI.scale,
								minh = 0.42 * TheFamily.UI.scale,
								colour = args.no_bg and G.C.CLEAR
									or args.bg_col
									or (args.red_bad and darken(G.C.RED, 0.1) or G.C.RED),
								draw_layer = 1,
								emboss = 0.05,
								refresh_movement = true,
							},
							nodes = {
								{
									n = G.UIT.O,
									config = {
										object = DynaText({
											string = args.text or "!",
											colours = { G.C.WHITE },
											shadow = true,
											rotate = true,
											H_offset = args.y_offset or 0,
											bump_rate = args.bump_rate or 3,
											bump_amount = args.bump_amount or 3,
											bump = true,
											maxw = args.maxw,
											text_rot = args.text_rot or 0.2,
											spacing = 3 * (args.scale or 1) * TheFamily.UI.scale,
											scale = (args.scale or 0.48) * TheFamily.UI.scale,
										}),
									},
								},
							},
						}
					local box = UIBox({
						definition = {
							n = G.UIT.ROOT,
							config = { align = "cm", colour = G.C.CLEAR, refresh_movement = true },
							nodes = { content },
						},
						config = {
							align = config.align or "tli",
							offset = {
								x = (config.offset or {}).x or (-0.1 * TheFamily.UI.scale),
								y = (config.offset or {}).y or (-0.1 * TheFamily.UI.scale),
							},
							parent = self,
						},
					})
					box.states.collide.can = false
					box.states.hover.can = false
					box.states.click.can = false
					box.role.r_bond = "Weak"
					box.T.r = 0
					box.T.scale = TheFamily.UI.scale
					self.children.alert = box
				end
			else
				if self.children.alert then
					self.children.alert:remove()
					self.children.alert = nil
				end
			end

			if type(definition.front_label) == "function" then
				if not self.children.front_label then
					local front_label = definition.front_label(definition, self) or {}
					local box = UIBox({
						definition = {
							n = G.UIT.ROOT,
							config = { colour = G.C.CLEAR, align = "cm" },
							nodes = {
								{
									n = G.UIT.R,
									config = {
										padding = 0.025,
										colour = adjust_alpha(G.C.BLACK, 0.75),
										r = 0.1,
									},
									nodes = {
										{
											n = G.UIT.T,
											config = {
												text = front_label.text or "",
												scale = (front_label.scale or 0.5) * TheFamily.UI.scale,
												colour = front_label.colour or G.C.WHITE,
											},
										},
									},
								},
							},
						},
						config = {
							align = "cmi",
							offset = {
								x = 0,
								y = 0,
							},
							parent = self,
						},
					})
					box.states.collide.can = false
					box.states.hover.can = false
					box.states.click.can = false
					box.role.r_bond = "Weak"
					box.T.r = math.rad(TheFamily.UI.r + 90)
					self.children.front_label = box
				end
			else
				if self.children.front_label then
					self.children.front_label:remove()
					self.children.front_label = nil
				end
			end
		end
	end,
	create_card_area_card = function(definition, replace_index)
		local card
		if definition.separator or definition.filler then
			local area = TheFamily.UI.area
			card = Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_base, {
				bypass_discovery_center = true,
				bypass_discovery_ui = true,
				discover = false,
			})
			card.no_shadow = true
			if not definition.filler then
				card.states.visible = false
				card.states.hover.can = false
			end
			card.states.collide.can = false
			card.states.drag.can = false
			function card:hover()
				return Node.hover(self)
			end
			function card:click() end
		elseif definition.center then
			local area = TheFamily.UI.area
			if type(definition.center) == "string" then
				card = Card(
					area.T.x + area.T.w / 2,
					area.T.y,
					G.CARD_W,
					G.CARD_H,
					definition.front and G.P_CARDS[definition.front] or nil,
					G.P_CENTERS[definition.center] or G.P_CENTERS.c_base,
					{
						bypass_discovery_center = true,
						bypass_discovery_ui = true,
						discover = false,
					}
				)
			elseif type(definition.center) == "function" then
				card = definition.center(definition, area)
					or Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_base, {
						bypass_discovery_center = true,
						bypass_discovery_ui = true,
						discover = false,
					})
			end
			card.no_shadow = true
			card.states.collide.can = true
			card.states.hover.can = true
			card.states.visible = true
		end
		if card then
			card:hard_set_T(nil, nil, card.T.w * TheFamily.UI.scale, card.T.h * TheFamily.UI.scale)
			remove_all(card.children)
			card.children = {}
			card:set_sprites(card.config.center, next(card.config.card) and card.config.card or nil)

			if definition.click then
				local old_click = card.click
				function card:click()
					if definition.click(definition, card) then
						return
					end
					return old_click(self)
				end
			end
			if definition.emplace and TheFamily.UI.area then
				TheFamily.UI.area:emplace(card)
			elseif replace_index and TheFamily.UI.area and (TheFamily.UI.area.cards or {})[replace_index] then
				local target_index = replace_index
				local target_card = TheFamily.UI.area.cards[target_index]
				if target_card.highlighted then
					TheFamily.UI.area:remove_from_highlighted(target_card, true)
				end
				target_card:remove()
				TheFamily.UI.area:emplace(card)
				table.insert(TheFamily.UI.area.cards, target_index, card)
				TheFamily.UI.area.cards[#TheFamily.UI.area.cards] = nil
				TheFamily.UI.set_card_position({
					card = card,
					index = target_index,
					force_position = true,
				})
			end
			card.thefamily_definition = definition
			TheFamily.UI.set_card_update(definition, card)
		end
		return card
	end,

	create_initial_cards = function()
		TheFamily.UI.create_card_area_card({
			center = "j_family",
			emplace = true,
			alert = function()
				return {
					text = "!",
				}
			end,
		})
		TheFamily.UI.create_card_area_card({
			separator = true,
			emplace = true,
		})
		for i = 1, TheFamily.UI.tabs_per_page do
			TheFamily.UI.create_card_area_card({
				filler = true,
				emplace = true,
			})
		end
		TheFamily.UI.create_card_area_card({
			separator = true,
			emplace = true,
		})
		TheFamily.UI.create_card_area_card({
			front_label = function(definition, card)
				return {
					text = "Next page",
				}
			end,
			center = "c_base",
			emplace = true,
			click = function(definition, card)
				local old_page = TheFamily.UI.page
				TheFamily.UI.page = math.max(1, math.min(TheFamily.UI.max_page, TheFamily.UI.page + 1))
				if TheFamily.UI.page ~= old_page then
					TheFamily.UI.create_page_cards()
				end
				return true
			end,
		})
		TheFamily.UI.create_card_area_card({
			front_label = function(definition, card)
				return {
					text = "Prev page",
				}
			end,
			center = "c_base",
			emplace = true,
			click = function(definition, card)
				local old_page = TheFamily.UI.page
				TheFamily.UI.page = math.max(1, TheFamily.UI.page - 1)
				if TheFamily.UI.page ~= old_page then
					TheFamily.UI.create_page_cards()
				end
				return true
			end,
			alert = function(definition, card)
				local info = TheFamily.UI.get_ui_values()
				return {
					definition = {
						n = G.UIT.R,
						config = {
							align = "cm",
							minh = 0.3 * info.scale,
							maxh = 1 * info.scale,
							minw = 0.5 * info.scale,
							maxw = 1.5 * info.scale,
							padding = 0.1 * info.scale,
							r = 0.02 * info.scale,
							colour = HEX("22222288"),
							res = 0.5 * info.scale,
						},
						nodes = {
							{
								n = G.UIT.O,
								config = {
									object = DynaText({
										string = {
											{
												ref_table = TheFamily.UI,
												ref_value = "page",
											},
										},
										colours = { G.C.WHITE },
										shadow = true,
										silent = true,
										bump = true,
										pop_in = 0.2,
										scale = 0.4 * info.scale,
									}),
								},
							},
							{
								n = G.UIT.T,
								config = {
									text = "/",
									colour = G.C.WHITE,
									scale = 0.4 * info.scale,
								},
							},
							{
								n = G.UIT.O,
								config = {
									object = DynaText({
										string = {
											{
												ref_table = TheFamily.UI,
												ref_value = "max_page",
											},
										},
										colours = { G.C.WHITE },
										shadow = true,
										silent = true,
										bump = true,
										pop_in = 0.2,
										scale = 0.4 * info.scale,
									}),
								},
							},
						},
					},
					definition_config = {
						align = "tri",
						offset = {
							x = card.T.w * math.sin(info.r_rad) + 0.21 * info.scale,
							y = 0.15 * info.scale,
						},
					},
				}
			end,
		})
	end,
	create_page_cards = function()
		local tabs_to_render = {}
		local start_index = 1 + TheFamily.UI.tabs_per_page * (TheFamily.UI.page - 1)
		local end_index = start_index + TheFamily.UI.tabs_per_page
		local current_index = 1
		for _, group in ipairs(TheFamily.tab_groups.list) do
			if current_index >= end_index then
				break
			end
			if #group.tabs + current_index < start_index then
				current_index = current_index + #group.tabs
			else
				for _, tab in ipairs(group.tabs) do
					if current_index > end_index then
						break
					end
					if current_index >= start_index then
						table.insert(tabs_to_render, tab)
					end
					current_index = current_index + 1
				end
			end
		end

		for i = 1, TheFamily.UI.tabs_per_page do
			if tabs_to_render[i] then
				TheFamily.UI.create_card_area_card(tabs_to_render[i], i + 2)
			else
				TheFamily.UI.create_card_area_card({
					filler = true,
				}, i + 2)
			end
		end
	end,
}

--- @param config TheFamilyGroupOptions
--- @return TheFamilyGroup
function TheFamily.create_tab_group(config)
	if TheFamily.tab_groups.dictionary[config.key] then
		return
	end
	local group = {
		key = config.key,
		order = config.order or #TheFamily.tab_groups.list,
		tabs = {},
	}
	table.insert(TheFamily.tab_groups.list, group)
	TheFamily.tab_groups.dictionary[group.key] = group
	return group
end

--- @param config TheFamilyTabOptions
--- @return TheFamilyTab
function TheFamily.create_tab(config)
	if TheFamily.tabs.dictionary[config.key] then
		return
	end
	local tab = {
		key = config.key,
		order = config.order or #TheFamily.tabs.list,

		front = config.front or nil,
		center = config.center or "c_base",

		front_label = config.front_label or nil,
		popup = config.popup or nil,
		alert = config.alert or nil,

		can_highlight = config.can_highlight or nil,
		highlight = config.highlight or nil,
		unhighlight = config.unhighlight or nil,
		click = config.click or nil,
		keep_popup_when_highlighted = config.keep_popup_when_highlighted or false,

		group_key = config.group_key or nil,
		group = nil,

		update = config.update or nil,
	}
	if tab.group_key then
		local group = TheFamily.tab_groups.dictionary[tab.group_key]
		if group then
			tab.group = group
			table.insert(group.tabs, tab)
		else
			tab.group = nil
		end
	end
	table.insert(TheFamily.tabs.list, tab)
	TheFamily.tabs.dictionary[tab.key] = tab
	return tab
end

function TheFamily.init()
	G.E_MANAGER:add_event(Event({
		func = function()
			table.sort(TheFamily.tabs.list, function(a, b)
				return not a.order or not b.order or a.order < b.order
			end)
			table.sort(TheFamily.tab_groups.list, function(a, b)
				return not a.order or not b.order or a.order < b.order
			end)
			for _, group in ipairs(TheFamily.tab_groups.list) do
				table.sort(group.tabs, function(a, b)
					return not a.order or not b.order or a.order < b.order
				end)
			end
			TheFamily.UI.create_card_area()
			TheFamily.UI.create_card_area_container()
			TheFamily.UI.create_initial_cards()
			TheFamily.UI.page = 1
			TheFamily.UI.max_page = math.ceil(#TheFamily.tabs.list / TheFamily.UI.tabs_per_page)
			TheFamily.UI.create_page_cards()
			return true
		end,
	}))
end

--- @class TheFamilyGroupOptions: table
--- @field key string Unique key
--- @field order? number Value user for sorting, from lowest to highest

--- @class TheFamilyTabOptions: table
--- @field key string Unique key
--- @field group_key string Unique key of group to be assigned for
--- @field order? number Value user for sorting, from lowest to highest
--- @field front? string Key from G.P_CARDS to set card's front
--- @field center? string | fun(definition: TheFamilyTab, area: CardArea): Card Key from G.P_CENTERS, or function which return fully created card (`create_card()` or `SMODS.create_card()`, for example). **DO NOT EMPLACE IT!**
--- @field front_label? fun(definition: TheFamilyTab, card: Card): { text?: string, colour?: table, scale?: number } Function which returns config for displaying text on a card
--- @field popup? fun(definition: TheFamilyTab, card: Card): { name?: table, description?: table[] } Function which returns config for displaying popup on hover. Rerenders when tab is (de)selected, use `card.highlighted` to determine is tab selected
--- @field keep_popup_when_highlighted? boolean When set to `true` and card is highlighted, popup will stay even if card will be not hovered
--- @field alert? fun(definition: TheFamilyTab, card: Card): table | { definition: table, definition_config?: table } Function which returns config for vanilla `create_UIBox_card_alert()` function, or custom definition for it
--- @field can_highlight? fun(definition: TheFamilyTab, card: Card): boolean Function which controls can card be highlighted. When value will change to `false`, card will automatically unhighlight
--- @field highlight? fun(definition: TheFamilyTab, card: Card) Callback when card is highlighted
--- @field unhighlight? fun(definition: TheFamilyTab, card: Card) Callback when card is unhighlighted
--- @field click? fun(definition: TheFamilyTab, card: Card): boolean Callback when card is clicked. If callback returns `true`, other events will not be fired (ex. card highlight)
--- @field update? fun(definition: TheFamilyTab, card: Card, dt: number) Update function. Happends before setting all popups, alerts, etc

--- @class TheFamilyTab: TheFamilyTabOptions
--- @field group TheFamilyGroup

--- @class TheFamilyGroup: TheFamilyGroupOptions
--- @field tabs TheFamilyTab[]
