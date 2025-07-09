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
}
