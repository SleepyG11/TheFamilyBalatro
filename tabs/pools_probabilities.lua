TheFamily.own_tabs.pools_probabilities = {
	keep_shop_slots_in_pool = true,

	edition_probabilities_for = 1,
	edition_modifiers = { 1, 2, 5 },

	rarities_last_render = 0,
	editions_last_render = 0,
	pools_last_render = 0,

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
				return a.index < b.index
			end
		end)
		return rarities_list
	end,
	get_sorted_editions = function()
		local editions_list = {}
		local modifier =
			TheFamily.own_tabs.pools_probabilities.edition_modifiers[TheFamily.own_tabs.pools_probabilities.edition_probabilities_for]
		if SMODS and SMODS.Edition then
			local available_editions = G.P_CENTER_POOLS.Edition
			local total_weight = 0
			local total_scaled_weight = 0
			for index, edition in ipairs(available_editions) do
				if edition.key ~= "e_base" then
					total_weight = total_weight + edition.weight
					local v = {
						key = edition.key,
						index = index,
						weight = edition:get_weight(),
						localized = localize({ set = "Edition", type = "name_text", key = edition.key }),
					}
					table.insert(editions_list, v)
					total_scaled_weight = total_scaled_weight + v.weight
					if
						edition.key == "e_negative"
						and TheFamily.own_tabs.pools_probabilities.edition_probabilities_for ~= 1
					then
						local prev = editions_list[index - 1]
						prev.weight = prev.weight + v.weight
						v.weight = 0
					end
				end
			end
			total_weight = total_weight + (total_weight / 4 * 96)
			for _, v in ipairs(editions_list) do
				v.rate = v.weight / total_weight * modifier
				v.weight = v.weight / total_scaled_weight
			end
		else
			local available_editions = { "Foil", "Holographic", "Polychrome", "Negative" }
			local weights = { 20, 14, 3, 3 }
			local loc_keys = { "e_foil", "e_holo", "e_polychrome", "e_negative" }
			local total_weight = 0
			local total_scaled_weight = 0
			for index, edition in ipairs(available_editions) do
				total_weight = total_weight + weights[index]
				local scaled_weight = (index == 4 and weights[index]) or weights[index] * G.GAME.edition_rate
				local v = {
					key = edition,
					index = index,
					weight = scaled_weight,
					localized = localize({ set = "Edition", type = "name_text", key = loc_keys[index] }),
				}
				table.insert(editions_list, v)
				total_scaled_weight = total_scaled_weight + v.weight
				if edition == "Negative" and TheFamily.own_tabs.pools_probabilities.edition_probabilities_for ~= 1 then
					local prev = editions_list[index - 1]
					prev.weight = prev.weight + v.weight
					v.weight = 0
				end
			end
			total_weight = total_weight + (total_weight / 4 * 96)
			for _, v in ipairs(editions_list) do
				v.rate = v.weight / total_weight
				v.weight = v.weight / total_scaled_weight
			end
		end
		table.sort(editions_list, function(a, b)
			if a.weight ~= b.weight then
				return a.weight > b.weight
			else
				return a.index < b.index
			end
		end)
		return editions_list
	end,
	get_sorted_pools = function()
		local pools_list = {}
		local total_weight = G.GAME.joker_rate + G.GAME.playing_card_rate
		table.insert(pools_list, {
			key = "Joker",
			index = 1,
			localized = localize("k_joker"),
			badge_colour = G.C.SECONDARY_SET.Joker,
			weight = G.GAME.joker_rate,
		})
		table.insert(pools_list, {
			key = "Playing",
			index = 2,
			localized = localize("k_base_cards"),
			badge_colour = G.C.SECONDARY_SET.Enhanced,
			weight = G.GAME.playing_card_rate,
		})
		local pools
		if SMODS and SMODS.ConsumableType then
			pools = SMODS.ConsumableType.ctype_buffer
		else
			pools = { "Spectral", "Tarot", "Planet" }
		end
		for index, _pool in ipairs(pools) do
			local weight = G.GAME[_pool:lower() .. "_rate"]
			local v = {
				key = _pool,
				index = index + 2,
				localized = localize("k_" .. _pool:lower()),
				badge_colour = G.C.SECONDARY_SET[_pool],
				weight = weight,
			}
			table.insert(pools_list, v)
			total_weight = total_weight + weight
		end
		for _, v in ipairs(pools_list) do
			-- v.rate = v.weight / total_weight
			v.weight = v.weight / total_weight
		end
		table.sort(pools_list, function(a, b)
			if a.weight ~= b.weight then
				return a.weight > b.weight
			else
				return a.index < b.index
			end
		end)
		return pools_list
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
											padding = 0.075,
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
	get_UI_edition = function()
		local editions = TheFamily.own_tabs.pools_probabilities.get_sorted_editions()
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
									text = "Edition",
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
							maxw = 1,
							minw = 1,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Rate",
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
		for _, edition in ipairs(editions) do
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
											colour = G.C.DARK_EDITION,
											r = 0.1,
											minw = 2,
											minh = 0.25,
											emboss = 0.05,
											padding = 0.075,
										},
										nodes = {
											{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
											{
												n = G.UIT.O,
												config = {
													object = DynaText({
														string = edition.localized or "ERROR",
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
											text = string.format("%0.3f%%", edition.weight * 100),
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
							maxw = 1,
							minw = 1,
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
											text = string.format("%0.3f%%", edition.rate * 100),
											colour = G.C.CHIPS,
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
	get_UI_pools = function()
		local pools = TheFamily.own_tabs.pools_probabilities.get_sorted_pools()
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
									text = "Card type",
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
				},
			},
			{
				n = G.UIT.R,
				config = {
					minh = 0.05,
				},
			},
		}
		for _, pool in ipairs(pools) do
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
											colour = pool.badge_colour,
											r = 0.1,
											minw = 2,
											minh = 0.25,
											emboss = 0.05,
											padding = 0.075,
										},
										nodes = {
											{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
											{
												n = G.UIT.O,
												config = {
													object = DynaText({
														string = pool.localized or "ERROR",
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
											text = string.format("%0.3f%%", pool.weight * 100),
											colour = G.C.CHIPS,
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

	create_UI_rarities_popup = function(definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Shop probabilities: Joker rarities",
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				TheFamily.own_tabs.pools_probabilities.get_UI_rarities(),
				{
					{
						n = G.UIT.R,
						nodes = TheFamily.UI.localize_text({
							"{C:inactive}Gray percents represent probability to{}",
							"{C:inactive}find{} {C:attention}one specific{} {C:inactive}card of this rarity{}",
						}, {
							align = "cm",
							default_col = G.C.UI.TEXT_DARK, -- default value
						}),
					},
				},
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
	create_UI_editions_popup = function(definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Shop probabilities: Editions",
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				TheFamily.own_tabs.pools_probabilities.get_UI_edition(),
				{

					create_option_cycle({
						options = { "Jokers", "Standard Pack", "Illusion voucher" },
						opt_callback = "thefamily_update_pools_probabilities_edition_for",
						current_option = TheFamily.own_tabs.pools_probabilities.edition_probabilities_for,
						colour = G.C.RED,
						scale = 0.6,
						w = 4,
					}),
				},
			},
		}
	end,
	create_UI_pools_popup = function(definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Shop probabilities: Card types",
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				TheFamily.own_tabs.pools_probabilities.get_UI_pools(),
			},
		}
	end,
}
TheFamily.create_tab({
	key = "thefamily_pools_pools",
	order = 1,
	group_key = "thefamily_default",
	center = "v_overstock_norm",
	type = "switch",

	front_label = function()
		return {
			text = "Card types",
		}
	end,
	popup = function(definition, card)
		TheFamily.own_tabs.pools_probabilities.pools_last_render = love.timer.getTime()
		return TheFamily.own_tabs.pools_probabilities.create_UI_pools_popup(definition, card)
	end,
	update = function(defuninition, card, dt)
		local now = love.timer.getTime()
		if card and card.children.popup and TheFamily.own_tabs.pools_probabilities.pools_last_render + 3 < now then
			TheFamily.own_tabs.pools_probabilities.pools_last_render = now
			defuninition:rerender_popup()
		end
	end,

	keep_popup_when_highlighted = true,
})
TheFamily.create_tab({
	key = "thefamily_pools_rarities",
	order = 2,
	group_key = "thefamily_default",
	center = "v_hone",
	type = "switch",

	front_label = function()
		return {
			text = "Rarities",
		}
	end,
	popup = function(definition, card)
		TheFamily.own_tabs.pools_probabilities.rarities_last_render = love.timer.getTime()
		return TheFamily.own_tabs.pools_probabilities.create_UI_rarities_popup(definition, card)
	end,
	update = function(defuninition, card, dt)
		local now = love.timer.getTime()
		if card and card.children.popup and TheFamily.own_tabs.pools_probabilities.rarities_last_render + 3 < now then
			TheFamily.own_tabs.pools_probabilities.rarities_last_render = now
			defuninition:rerender_popup()
		end
	end,

	keep_popup_when_highlighted = true,
})
local edition_tab = TheFamily.create_tab({
	key = "thefamily_pools_editions",
	order = 3,
	group_key = "thefamily_default",
	center = "v_glow_up",
	type = "switch",

	front_label = function()
		return {
			text = "Editions",
		}
	end,
	popup = function(definition, card)
		TheFamily.own_tabs.pools_probabilities.editions_last_render = love.timer.getTime()
		return TheFamily.own_tabs.pools_probabilities.create_UI_editions_popup(definition, card)
	end,
	update = function(defuninition, card, dt)
		local now = love.timer.getTime()
		if card and card.children.popup and TheFamily.own_tabs.pools_probabilities.editions_last_render + 3 < now then
			TheFamily.own_tabs.pools_probabilities.editions_last_render = now
			defuninition:rerender_popup()
		end
	end,

	keep_popup_when_highlighted = true,
})

--

function G.FUNCS.thefamily_update_pools_probabilities_edition_for(arg)
	TheFamily.own_tabs.pools_probabilities.edition_probabilities_for = arg.to_key
	edition_tab:rerender_popup()
end
