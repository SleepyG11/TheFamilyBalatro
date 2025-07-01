TheFamily.create_tab_group({
	key = "example_vanilla",
	order = 1,
})
TheFamily.create_tab({
	key = "example_showman",
	group_key = "example_vanilla",

	front_label = function(definition, card)
		return {
			text = "Showman",
			colour = G.C.WHITE, -- also default value
			scale = 0.5, -- default value
		}
	end,
	center = "j_ring_master",

	popup = function(definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Showman",
						colour = G.C.WHITE,
						scale = 0.4,
					},
				},
			},
			description = {
				{
					{
						n = G.UIT.T,
						config = {
							text = "First message box",
							scale = 0.3,
							colour = G.C.BLACK,
						},
					},
				},
				{
					{
						n = G.UIT.T,
						config = {
							text = "Second message box",
							scale = 0.3,
							colour = G.C.BLACK,
						},
					},
				},
				{
					{
						n = G.UIT.T,
						config = {
							text = card.highlighted and "Tab is selected" or "Tab is not selected",
							scale = 0.3,
							colour = G.C.BLACK,
						},
					},
				},
			},
		}
	end,
	keep_popup_when_highlighted = true,
	alert = function(definition, card)
		return {
			text = "!",
		}
	end,

	can_highlight = function(definition, card)
		return G.STATE == G.STATES.SHOP
	end,
})
TheFamily.create_tab({
	key = "example_obelisk",
	group_key = "example_vanilla",

	front_label = function(definition, card)
		return {
			text = "Obelisk",
			colour = G.C.WHITE, -- also default value
			scale = 0.5, -- default value
		}
	end,
	center = "j_obelisk",

	popup = function(definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Close the game",
						colour = G.C.WHITE,
						scale = 0.4,
					},
				},
			},
			description = {
				{
					{
						n = G.UIT.T,
						config = {
							text = "You really want obelisk?",
							scale = 0.3,
							colour = G.C.BLACK,
						},
					},
				},
			},
		}
	end,
	keep_popup_when_highlighted = true,
	alert = function(definition, card)
		local info = TheFamily.UI.get_ui_values() -- Function which returns UI varibles like rotation, scale and gap
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
						n = G.UIT.T,
						config = {
							text = "Click me!",
							colour = G.C.WHITE,
							scale = 0.4 * info.scale,
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

	click = function(definition, card)
		card:juice_up()
		return true
	end,
})
if BalatroSR then
	TheFamily.create_tab_group({
		key = "example_starrail_group",
		order = 2,
	})
	TheFamily.create_tab({
		key = "example_gacha_shop",
		group_key = "example_starrail_group",
		order = 0,

		front_label = function(definition, card)
			return {
				text = "B:SR",
			}
		end,
		center = function(definition, area)
			return SMODS.create_card({
				key = "c_hsr_starrailpass",
				no_edition = true,
			})
		end,

		popup = function(definition, card)
			return {
				name = {
					{
						n = G.UIT.T,
						config = {
							text = "Gacha shop",
							colour = G.C.WHITE,
							scale = 0.4,
						},
					},
				},
			}
		end,

		can_highlight = function(definition, card)
			return G.STATE == G.STATES.SHOP
		end,
		highlight = function(definition, card)
			BalatroSR.open_gacha_results(true, true)
			BalatroSR.open_gacha_shop(false, true)
		end,
		unhighlight = function(definition, card)
			BalatroSR.open_gacha_results(true, false)
			BalatroSR.open_gacha_shop(true, false)
		end,
	})
end
