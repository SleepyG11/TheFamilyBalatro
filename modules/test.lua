function TheFamily.debug()
	TheFamily.create_tab_group({
		key = "thefamily_debug",
	})
	for i = 1, 24 do
		TheFamily.create_tab({
			key = "thefamily_debug_showman_" .. tostring(i),
			group_key = "thefamily_debug",
			type = "overlay",
			keep = true,

			front_label = function(definition, card)
				return {
					text = "Showman " .. tostring(i),
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
								text = "Showman " .. tostring(i),
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
				if G.STATE == G.STATES.SHOP then
					return {
						remove = true,
					}
				end
				return {
					text = "!",
				}
			end,

			can_highlight = function(definition, card)
				return G.STATE == G.STATES.SHOP
			end,

			highlight = function()
				print(string.format("Showman %s highlighted", i))
			end,
			unhighlight = function()
				print(string.format("Showman %s unhighlighted", i))
			end,
		})
	end
	for i = 1, 4 do
		TheFamily.create_tab({
			key = "thefamily_debug_obelisk_" .. tostring(i),
			group_key = "thefamily_debug",
			type = "switch",

			keep = i % 2 == 0,
			force_highlight = function()
				return true
			end,

			front_label = function(definition, card) end,
			center = "j_obelisk",

			highlight = function()
				print(string.format("Obelisk %s highlighted", i))
			end,
			unhighlight = function()
				print(string.format("Obelisk %s unhighlighted", i))
			end,
			click = function(self, card)
				card:juice_up()
			end,
		})
	end
end
