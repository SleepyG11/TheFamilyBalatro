TheFamily = setmetatable({}, {})

TF = TheFamily

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
				local popup_definitions = definition.popup(definition, card)
				if popup_definitions.name or popup_definitions.description then
					self.config.h_popup_config = self:align_h_popup()
					self.config.h_popup = {
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
												nodes = {
													popup_definitions.name and name_from_rows(popup_definitions.name)
														or nil,
													popup_definitions.description and desc_from_rows({
														popup_definitions.description,
													}) or nil,
												},
											},
										},
									},
								},
							},
						},
					}
				end
			end
			Node.hover(self)
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

			if type(definition.alert) == "function" then
				if not self.children.alert then
					local args = definition.alert(definition, self)
					local content, config
					if type(args.definition) == "function" then
						content, config = args.definition(definition, self)
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
					local front_label = definition.front_label(definition, self)
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
												text = front_label.text,
												scale = 0.5 * TheFamily.UI.scale,
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
	create_card_area_card = function(definition)
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
					nil,
					G.P_CENTERS[definition.center] or G.P_CENTERS.c_base,
					{
						bypass_discovery_center = true,
						bypass_discovery_ui = true,
						discover = false,
					}
				)
			elseif type(definition.center) == "function" then
				card = definition.center(definition, area)
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
			elseif
				definition.replace_index
				and TheFamily.UI.area
				and (TheFamily.UI.area.cards or {})[definition.replace_index]
			then
				local target_index = definition.replace_index
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
		for i = 1, TheFamily.UI.items_per_page - TheFamily.UI.utility_cards_per_page do
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
				TheFamily.UI.page = math.max(1, TheFamily.UI.page + 1)
				TheFamily.UI.create_page_cards()
				return true
			end,
			popup = function(definition, card)
				return {
					name = {
						{
							n = G.UIT.T,
							config = {
								text = "Previous page?",
								scale = 0.4,
								colour = G.C.WHITE,
							},
						},
					},
					description = {
						{
							n = G.UIT.T,
							config = {
								text = "Go to previous page",
								colour = G.C.BLACK,
								scale = 0.3,
							},
						},
					},
				}
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
				TheFamily.UI.page = math.max(1, TheFamily.UI.page - 1)
				TheFamily.UI.create_page_cards()
				return true
			end,
			popup = function(definition, card)
				return {
					name = {
						{
							n = G.UIT.T,
							config = {
								text = "Next page?",
								scale = 0.4,
								colour = G.C.WHITE,
							},
						},
					},
					description = {
						{
							n = G.UIT.T,
							config = {
								text = "Go to next page",
								colour = G.C.BLACK,
								scale = 0.3,
							},
						},
					},
				}
			end,
			alert = function(definition, card)
				return {
					definition = function(definition, card)
						local info = TheFamily.UI.get_ui_values()
						return {
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
													ref_table = { max_page = 3 },
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
						}, {
							align = "tri",
							offset = {
								x = card.T.w * math.sin(info.r_rad) + 0.21 * info.scale,
								y = 0.15 * info.scale,
							},
						}
					end,
				}
			end,
		})
	end,
	create_page_cards = function()
		-- local centers = { "j_joker", "c_base", "j_trading", "j_ring_master", "j_family", "j_ramen", "j_blueprint" }
		-- for i = 1, TheFamily.UI.items_per_page - TheFamily.UI.utility_cards_per_page do
		-- 	TheFamily.UI.create_card_area_card({
		-- 		front_label = i == 7 and function(definition, card)
		-- 			return {
		-- 				text = "Handy",
		-- 			}
		-- 		end,
		-- 		center = centers[((i - 1) % 3) + 1 + 3 * (TheFamily.UI.page > 1 and 1 or 0)],
		-- 		replace_index = i + 2,
		-- 		popup = function(definition, card)
		-- 			return {
		-- 				name = {
		-- 					{
		-- 						n = G.UIT.T,
		-- 						config = {
		-- 							text = "Test popup",
		-- 							scale = 0.4,
		-- 							colour = G.C.WHITE,
		-- 						},
		-- 					},
		-- 				},
		-- 				description = {
		-- 					{
		-- 						n = G.UIT.T,
		-- 						config = {
		-- 							text = "Clicking here will show an UI later!",
		-- 							colour = G.C.BLACK,
		-- 							scale = 0.3,
		-- 						},
		-- 					},
		-- 				},
		-- 			}
		-- 		end,
		-- 		alert = i == 4 and function()
		-- 			return {
		-- 				definition = function(definition, card)
		-- 					local info = TheFamily.UI.get_ui_values()
		-- 					return {
		-- 						n = G.UIT.R,
		-- 						config = {
		-- 							align = "cm",
		-- 							minh = 0.3 * info.scale,
		-- 							maxh = 1 * info.scale,
		-- 							minw = 0.5 * info.scale,
		-- 							maxw = 1.5 * info.scale,
		-- 							padding = 0.1 * info.scale,
		-- 							r = 0.02 * info.scale,
		-- 							colour = HEX("22222288"),
		-- 							res = 0.5 * info.scale,
		-- 						},
		-- 						nodes = {
		-- 							{
		-- 								n = G.UIT.T,
		-- 								config = {
		-- 									text = "Hai!",
		-- 									colour = G.C.WHITE,
		-- 									scale = 0.5 * info.scale,
		-- 								},
		-- 							},
		-- 						},
		-- 					}, {
		-- 						align = "tri",
		-- 						offset = {
		-- 							x = card.T.w * math.sin(info.r_rad) + 0.21 * info.scale,
		-- 							y = 0.15 * info.scale,
		-- 						},
		-- 					}
		-- 				end,
		-- 			}
		-- 		end,
		-- 	})
		-- end
		if BalatroSR then
			TheFamily.UI.create_card_area_card({
				front_label = function(definition, card)
					return {
						text = "B:SR",
					}
				end,
				center = "c_hsr_starrailpass",
				replace_index = 3,
				popup = function(definition, card)
					return {
						name = {
							{
								n = G.UIT.T,
								config = {
									text = "Ticket shop",
									scale = 0.4,
									colour = G.C.WHITE,
								},
							},
						},
						description = {
							{
								n = G.UIT.T,
								config = {
									text = "Clicking here to gamble!",
									colour = G.C.BLACK,
									scale = 0.3,
								},
							},
						},
					}
				end,
				alert = function()
					return {
						definition = function(definition, card)
							local info = TheFamily.UI.get_ui_values()
							return {
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
														ref_table = setmetatable({}, {
															__index = function(t, k)
																if
																	BalatroSR.hsr_gacha_shop_area
																	and BalatroSR.hsr_gacha_shop_area.cards
																then
																	return #BalatroSR.hsr_gacha_shop_area.cards
																else
																	return 0
																end
															end,
														}),
														ref_value = "count",
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
							}, {
								align = "tri",
								offset = {
									x = card.T.w * math.sin(info.r_rad) + 0.21 * info.scale,
									y = 0.15 * info.scale,
								},
							}
						end,
					}
				end,
				highlight = function()
					BalatroSR.open_gacha_shop(true, true)
					BalatroSR.open_gacha_results(true, true)
				end,
				can_highlight = function()
					return G.STATE == G.STATES.SHOP
				end,
				unhighlight = function()
					BalatroSR.open_gacha_shop(true, false)
					BalatroSR.open_gacha_results(true, false)
				end,
			})
		end
		if AKYRS and AKYRS.SOL then
			TheFamily.UI.create_card_area_card({
				front_label = function(definition, card)
					return {
						text = "Solitaire",
					}
				end,
				center = function(definition, area)
					local card = SMODS.create_card({
						key = "j_akyrs_aikoyori",
						no_edition = true,
					})
					card.children.floating_sprite.role.scale_bond = "Strong"
					return card
				end,
				replace_index = 4,
				popup = function(definition, card)
					return {
						name = {
							{
								n = G.UIT.T,
								config = {
									text = "Solitaire",
									scale = 0.4,
									colour = G.C.WHITE,
								},
							},
						},
						-- description = {
						-- 	{
						-- 		n = G.UIT.T,
						-- 		config = {
						-- 			text = "Clicking here to gamble!",
						-- 			colour = G.C.BLACK,
						-- 			scale = 0.3,
						-- 		},
						-- 	},
						-- },
					}
				end,
				click = function()
					G.SETTINGS.paused = true
					G.FUNCS.overlay_menu({
						definition = {
							n = G.UIT.ROOT,
							nodes = {
								AKYRS.SOL.get_UI_definition(),
							},
						},
						config = {},
					})
					return true
				end,
			})
		end
	end,
}

function TheFamily.init()
	G.E_MANAGER:add_event(Event({
		func = function()
			TheFamily.UI.create_card_area()
			TheFamily.UI.create_card_area_container()
			TheFamily.UI.create_initial_cards()
			TheFamily.UI.page = 1
			TheFamily.UI.create_page_cards()
			return true
		end,
	}))
end
