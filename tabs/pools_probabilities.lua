TheFamily.own_tabs.pools_probabilities = {
	keep_shop_slots_in_pool = true,

	-- TODO: constant updates when opened
	get_sorted_rarities = function()
		local rarities_list = {}
		if SMODS and SMODS.Rarities then
			-- Taken from SMODS
			local available_rarities = copy_table(SMODS.ObjectTypes["Joker"].rarities)
			local total_weight = 0
			for _, v in ipairs(available_rarities) do
				v.mod = G.GAME[tostring(v.key):lower() .. "_mod"] or 1
				if
					SMODS.Rarities[v.key]
					and SMODS.Rarities[v.key].get_weight
					and type(SMODS.Rarities[v.key].get_weight) == "function"
				then
					v.weight = SMODS.Rarities[v.key]:get_weight(v.weight, SMODS.ObjectTypes["Joker"])
				end
				v.weight = v.weight * v.mod
				total_weight = total_weight + v.weight
			end
			for index, v in ipairs(available_rarities) do
				v.weight = v.weight / total_weight
				local rarity = SMODS.Rarities[v.key]
				local vanilla_rarities = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4 }
				local pool = G.P_JOKER_RARITY_POOLS[vanilla_rarities[rarity.key] or rarity.key]
				local items_in_pool = #pool
				local items_left_in_pool = items_in_pool
				local is_showman_present = next(find_joker("Showman"))
				local keys_in_shop = {}
				if TheFamily.own_tabs.pools_probabilities.keep_shop_slots_in_pool then
					if G.shop_jokers then
						for _, card in ipairs(G.shop_jokers.cards) do
							keys_in_shop[card.config.center.key] = true
						end
					end
				end
				local showman_check = SMODS.showman or function(key)
					return is_showman_present
				end
				for _, v in ipairs(pool) do
					if
						not v.unlocked
						or (G.GAME.used_jokers[v.key] and not keys_in_shop[v.key] and not showman_check(v.key))
					then
						items_left_in_pool = items_left_in_pool - 1
					end
				end
				if rarity then
					table.insert(rarities_list, {
						key = rarity.key,
						localized = SMODS.Rarity:get_rarity_badge(v.key),
						badge_colour = rarity.badge_colour,
						weight = v.weight,
						items_count = #G.P_JOKER_RARITY_POOLS[vanilla_rarities[rarity.key] or rarity.key],
						items_left = items_left_in_pool,
						index = index,
					})
				end
			end
		else
			local weights = { 0.7, 0.25, 0.05, 0 }
			for i, key in ipairs({ "Common", "Uncommon", "Rare" }) do
				local pool = G.P_JOKER_RARITY_POOLS[i]
				local items_in_pool = #pool
				local items_left_in_pool = items_in_pool
				local is_showman_present = next(find_joker("Showman"))
				local keys_in_shop = {}
				if TheFamily.own_tabs.pools_probabilities.keep_shop_slots_in_pool then
					if G.shop_jokers then
						for _, card in ipairs(G.shop_jokers.cards) do
							keys_in_shop[card.config.center.key] = true
						end
					end
				end
				for _, v in ipairs(pool) do
					if
						not v.unlocked
						or (G.GAME.used_jokers[v.key] and not keys_in_shop[v.key] and not is_showman_present)
					then
						items_left_in_pool = items_left_in_pool - 1
					end
				end
				table.insert(rarities_list, {
					key = key,
					localized = localize("k_" .. key:lower()),
					weight = weights[i],
					items_count = items_in_pool,
					items_left = items_left_in_pool,
					badge_colour = G.C.RARITY[i],
					index = i,
				})
			end
		end
		table.sort(rarities_list, function(a, b)
			if a.weight ~= b.weight then
				return a.weight > b.weight
			else
				return a.index > b.index
			end
		end)
		return rarities_list
	end,
	get_UI_rarities = function()
		local rarities = TheFamily.own_tabs.pools_probabilities.get_sorted_rarities()
		local result = {
			{
				n = G.UIT.R,
				config = {
					padding = 0.025,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.C,
						config = {
							minw = 2,
							maxw = 2,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Rarity",
									scale = 0.3,
									colour = G.C.UI.TEXT_DARK,
									align = "cm",
								},
							},
						},
					},
					{
						n = G.UIT.C,
						config = {
							maxw = 1,
							minw = 1,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Weight",
									scale = 0.3,
									colour = G.C.UI.TEXT_DARK,
									align = "cm",
								},
							},
						},
					},
					{
						n = G.UIT.C,
					},
					{
						n = G.UIT.C,
						config = {
							maxw = 1.4,
							minw = 1.4,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Pool",
									scale = 0.3,
									colour = G.C.UI.TEXT_DARK,
									align = "cm",
								},
							},
						},
					},
					{
						n = G.UIT.C,
					},
					{
						n = G.UIT.C,
						config = {
							maxw = 1.4,
							minw = 1.4,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Left",
									scale = 0.3,
									colour = G.C.UI.TEXT_DARK,
									align = "cm",
								},
							},
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = {
					minh = 0.05,
				},
			},
		}
		for _, rarity in ipairs(rarities) do
			table.insert(result, {
				n = G.UIT.R,
				config = {
					padding = 0.025,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.C,
						config = {
							minw = 2,
							maxw = 2,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{
										n = G.UIT.R,
										config = {
											align = "cm",
											colour = rarity.badge_colour or G.C.GREEN,
											r = 0.1,
											minw = 2,
											minh = 0.25,
											emboss = 0.05,
											padding = 0.06,
										},
										nodes = {
											{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
											{
												n = G.UIT.O,
												config = {
													object = DynaText({
														string = rarity.localized or "ERROR",
														colours = { G.C.WHITE },
														float = true,
														shadow = true,
														offset_y = -0.05,
														silent = true,
														spacing = 1,
														scale = 0.25,
													}),
												},
											},
											{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
										},
									},
								},
							},
						},
					},
					{
						n = G.UIT.C,
					},
					{
						n = G.UIT.C,
						config = {
							maxw = 1,
							minw = 1,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.R,
								config = {
									align = "cm",
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = string.format("%0.3f%%", rarity.weight * 100),
											colour = G.C.CHIPS,
											scale = 0.3,
											align = "cm",
										},
									},
								},
							},
						},
					},
					{
						n = G.UIT.C,
					},
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							maxw = 1.4,
							minw = 1.4,
						},
						nodes = {
							{
								n = G.UIT.R,
								config = {
									align = "cm",
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = string.format("%s ", rarity.items_count),
											colour = G.C.CHIPS,
											scale = 0.3,
											align = "cm",
										},
									},
									{
										n = G.UIT.T,
										config = {
											text = string.format("(%0.3f%%)", rarity.weight / rarity.items_count * 100),
											colour = adjust_alpha(G.C.UI.TEXT_DARK, 0.6),
											scale = 0.3,
											align = "cm",
										},
									},
								},
							},
						},
					},
					{
						n = G.UIT.C,
					},
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							maxw = 1.4,
							minw = 1.4,
						},
						nodes = {
							{
								n = G.UIT.R,
								config = {
									align = "cm",
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = string.format("%s ", rarity.items_left),
											colour = G.C.CHIPS,
											scale = 0.3,
											align = "cm",
										},
									},
									{
										n = G.UIT.T,
										config = {
											text = string.format("(%0.3f%%)", rarity.weight / rarity.items_left * 100),
											colour = adjust_alpha(G.C.UI.TEXT_DARK, 0.6),
											scale = 0.3,
											align = "cm",
										},
									},
								},
							},
						},
					},
				},
			})
		end
		return result
	end,

	create_UI_popup = function(definition, card)
		return {
			description = {
				TheFamily.own_tabs.pools_probabilities.get_UI_rarities(),
				{
					{
						n = G.UIT.R,
						config = {
							padding = 0.05,
							r = 0.1,
							colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
						},
						nodes = {
							create_toggle({
								label = "Ignore shop slots",
								ref_table = TheFamily.own_tabs.pools_probabilities,
								ref_value = "keep_shop_slots_in_pool",
								scale = 0.5,
								label_scale = 0.3,
								callback = function()
									definition:rerender_popup()
								end,
							}),
						},
					},
				},
			},
		}
	end,
}
TheFamily.create_tab({
	key = "thefamily_pools_rarities",
	order = 1,
	group_key = "thefamily_default",
	center = "v_hone",
	type = "switch",

	front_label = function()
		return {
			text = "Rarities",
		}
	end,
	popup = function(definition, card)
		return TheFamily.own_tabs.pools_probabilities.create_UI_popup(definition, card)
	end,

	keep_popup_when_highlighted = true,
})
