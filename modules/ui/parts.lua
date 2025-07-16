TheFamily.UI.PARTS = {
	create_dark_alert = function(card, content)
		local ui_values = TheFamily.UI.get_ui_values()

		local config
		if ui_values.position_on_screen == "right" then
			config = {
				align = "tri",
				offset = {
					x = card.T.w * math.sin(ui_values.r_rad) + 0.22 * ui_values.scale,
					y = -0.1 * ui_values.scale,
				},
			}
		elseif ui_values.position_on_screen == "left" then
			config = {
				align = "tli",
				offset = {
					x = -1 * (card.T.w * math.sin(ui_values.r_rad) + 0.22 * ui_values.scale),
					y = -0.1 * ui_values.scale,
				},
			}
		else
			config = {
				align = "tri",
				offset = {
					x = card.T.w * math.sin(ui_values.r_rad) + 0.21 * ui_values.scale,
					y = 0.15 * ui_values.scale,
				},
			}
		end

		return {
			definition = {
				n = G.UIT.ROOT,
				config = { align = "cm", colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.1 * ui_values.scale,
							r = 0.02 * ui_values.scale,
							colour = HEX("22222288"),
						},
						nodes = content,
					},
				},
			},
			config = config,
		}
	end,

	create_option_cycle = function(label, values, current_value, callback_func, options)
		options = options or {}
		if options.compress then
			local new_values = {}
			for k, v in ipairs(values) do
				table.insert(new_values, label .. ": " .. v)
			end
			values = new_values
		end
		return create_option_cycle({
			w = options.compress and 10 or 6,
			label = not options.compress and label or nil,
			scale = 0.8,
			options = values,
			opt_callback = callback_func,
			current_option = current_value,
			focus_args = { nav = "wide" },
		})
	end,

	create_separator_r = function(h)
		return { n = G.UIT.R, config = { minh = h or 0.25 } }
	end,
	create_separator_c = function(w)
		return { n = G.UIT.C, config = { minw = w or 0.25 } }
	end,

	create_groups_order_area = function()
		local area = CardArea(0, 0, G.CARD_W * 5, G.CARD_H, {
			card_limit = 1e308,
			type = "title_2",
			highlight_limit = 1,
		})
		function area:can_highlight()
			return true
		end
		function area:set_ranks()
			for k, card in ipairs(self.cards) do
				card.rank = k
				card.states.collide.can = true
				card.states.drag.can = true
			end
		end
		function area:update(dt)
			self.config.temp_limit = math.max(#self.cards, self.config.card_limit)
			self.config.card_count = #self.cards
			self:set_ranks()
		end
		function area:align_cards()
			-- copypaste vanilla code, it's just easier
			for k, card in ipairs(self.cards) do
				if not card.states.drag.is then
					card.T.r = 0.1 * (-#self.cards / 2 - 0.5 + k) / #self.cards
						+ (G.SETTINGS.reduced_motion and 0 or 1) * 0.02 * math.sin(2 * G.TIMERS.REAL + card.T.x)
					local max_cards = math.max(#self.cards, self.config.temp_limit)
					card.T.x = self.T.x
						+ (self.T.w - self.card_w) * ((k - 1) / math.max(max_cards - 1, 1) - 0.5 * (#self.cards - max_cards) / math.max(
							max_cards - 1,
							1
						))
						+ 0.5 * (self.card_w - card.T.w)
					if
						#self.cards > 2
						or (#self.cards > 1 and self == G.consumeables)
						or (#self.cards > 1 and self.config.spread)
					then
						card.T.x = self.T.x
							+ (self.T.w - self.card_w) * ((k - 1) / (#self.cards - 1))
							+ 0.5 * (self.card_w - card.T.w)
					elseif #self.cards > 1 and self ~= G.consumeables then
						card.T.x = self.T.x
							+ (self.T.w - self.card_w) * ((k - 0.5) / #self.cards)
							+ 0.5 * (self.card_w - card.T.w)
					else
						card.T.x = self.T.x + self.T.w / 2 - self.card_w / 2 + 0.5 * (self.card_w - card.T.w)
					end
					local highlight_height = G.HIGHLIGHT_H / 2
					if not card.highlighted then
						highlight_height = 0
					end
					card.T.y = self.T.y
						+ self.T.h / 2
						- card.T.h / 2
						- highlight_height
						+ (G.SETTINGS.reduced_motion and 0 or 1) * 0.03 * math.sin(0.666 * G.TIMERS.REAL + card.T.x)
					card.T.x = card.T.x + card.shadow_parrallax.x / 30
				end
			end
			table.sort(self.cards, function(a, b)
				return a.T.x + a.T.w / 2 - 100 * (a.pinned and a.sort_id or 0)
					< b.T.x + b.T.w / 2 - 100 * (b.pinned and b.sort_id or 0)
			end)
			local is_updated = false
			for k, card in ipairs(self.cards) do
				if card.rank and card.rank ~= k then
					is_updated = true
				end
				card.rank = k
			end
			if is_updated then
				TheFamily.save_groups_order(self)
			end
		end
		function area:add_to_highlighted(card, silent)
			if self.highlighted[1] then
				self:remove_from_highlighted(self.highlighted[1])
			end
			self.highlighted[#self.highlighted + 1] = card
			card:highlight(true)
			if not silent then
				play_sound("cardSlide1")
			end
		end
		return area
	end,
	create_tabs_order_area = function()
		local area = CardArea(0, 0, G.CARD_W * 5, G.CARD_H, {
			card_limit = 1e308,
			type = "title_2",
			highlight_limit = 1,
		})
		area.children.info_line = UIBox({
			definition = {
				n = G.UIT.ROOT,
				config = { colour = G.C.CLEAR, align = "cm" },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = "Select group to see tabs list here",
							scale = 0.4,
							colour = G.C.UI.TEXT_INACTIVE,
						},
					},
				},
			},
			config = {
				parent = area,
				align = "cm",
				offset = {
					x = 0,
					y = 0,
				},
			},
		})
		function area:can_highlight()
			return true
		end
		function area:set_ranks()
			for k, card in ipairs(self.cards) do
				card.rank = k
				card.states.collide.can = true
				card.states.drag.can = true
			end
		end
		function area:update(dt)
			self.config.temp_limit = math.max(#self.cards, self.config.card_limit)
			self.config.card_count = #self.cards
			self:set_ranks()
			self.children.info_line.states.visible = self.config.card_count == 0
		end
		function area:align_cards()
			-- copypaste vanilla code, it's just easier
			for k, card in ipairs(self.cards) do
				if not card.states.drag.is then
					card.T.r = 0.1 * (-#self.cards / 2 - 0.5 + k) / #self.cards
						+ (G.SETTINGS.reduced_motion and 0 or 1) * 0.02 * math.sin(2 * G.TIMERS.REAL + card.T.x)
					local max_cards = math.max(#self.cards, self.config.temp_limit)
					card.T.x = self.T.x
						+ (self.T.w - self.card_w) * ((k - 1) / math.max(max_cards - 1, 1) - 0.5 * (#self.cards - max_cards) / math.max(
							max_cards - 1,
							1
						))
						+ 0.5 * (self.card_w - card.T.w)
					if
						#self.cards > 2
						or (#self.cards > 1 and self == G.consumeables)
						or (#self.cards > 1 and self.config.spread)
					then
						card.T.x = self.T.x
							+ (self.T.w - self.card_w) * ((k - 1) / (#self.cards - 1))
							+ 0.5 * (self.card_w - card.T.w)
					elseif #self.cards > 1 and self ~= G.consumeables then
						card.T.x = self.T.x
							+ (self.T.w - self.card_w) * ((k - 0.5) / #self.cards)
							+ 0.5 * (self.card_w - card.T.w)
					else
						card.T.x = self.T.x + self.T.w / 2 - self.card_w / 2 + 0.5 * (self.card_w - card.T.w)
					end
					local highlight_height = G.HIGHLIGHT_H / 2
					if not card.highlighted then
						highlight_height = 0
					end
					card.T.y = self.T.y
						+ self.T.h / 2
						- card.T.h / 2
						- highlight_height
						+ (G.SETTINGS.reduced_motion and 0 or 1) * 0.03 * math.sin(0.666 * G.TIMERS.REAL + card.T.x)
					card.T.x = card.T.x + card.shadow_parrallax.x / 30
				end
			end
			table.sort(self.cards, function(a, b)
				return a.T.x + a.T.w / 2 - 100 * (a.pinned and a.sort_id or 0)
					< b.T.x + b.T.w / 2 - 100 * (b.pinned and b.sort_id or 0)
			end)
			local is_updated = false
			for k, card in ipairs(self.cards) do
				if card.rank and card.rank ~= k then
					is_updated = true
				end
				card.rank = k
			end
			if is_updated then
				TheFamily.save_tabs_order(self)
			end
		end
		function area:add_to_highlighted(card, silent)
			if self.highlighted[1] then
				self:remove_from_highlighted(self.highlighted[1])
			end
			self.highlighted[#self.highlighted + 1] = card
			card:highlight(true)
			if not silent then
				play_sound("cardSlide1")
			end
		end
		local old_draw = area.draw
		function area:draw()
			old_draw(self)
			if self.children.info_line then
				self.children.info_line:draw()
			end
		end
		return area
	end,

	create_mod_badge = function(mod)
		if not mod then
			return nil
		end
		local mod_name = mod.display_name
		local size = 0.9
		local font = G.LANG.font
		local max_text_width = 2 - 2 * 0.05 - 4 * 0.03 * size - 2 * 0.03
		local calced_text_width = 0
		for _, c in utf8.chars(mod_name) do
			local tx = font.FONT:getWidth(c) * (0.33 * size) * G.TILESCALE * font.FONTSCALE
				+ 2.7 * 1 * G.TILESCALE * font.FONTSCALE
			calced_text_width = calced_text_width + tx / (G.TILESIZE * G.TILESCALE)
		end
		local scale_fac = 1
		return {
			n = G.UIT.R,
			config = { align = "cm" },
			nodes = {
				{
					n = G.UIT.R,
					config = {
						align = "cm",
						colour = mod.badge_colour or G.C.GREEN,
						r = 0.1,
						minw = 2,
						minh = 0.36,
						emboss = 0.05,
						padding = 0.03 * size,
					},
					nodes = {
						{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
						{
							n = G.UIT.O,
							config = {
								object = DynaText({
									string = mod_name or "ERROR",
									colours = { mod.badge_text_colour or G.C.WHITE },
									float = true,
									shadow = true,
									offset_y = -0.05,
									silent = true,
									spacing = 1 * scale_fac,
									scale = 0.33 * size * scale_fac,
									marquee = true,
									maxw = max_text_width,
								}),
							},
						},
						{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
					},
				},
			},
		}
	end,
}
