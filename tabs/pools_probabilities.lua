TheFamily.create_tab_group({
	key = "thefamily_shop_pools",
	order = 1,

	can_be_disabled = true,

	original_mod_id = "TheFamily", -- will be used SMODS mod id if not defined
	loc_txt = {
		name = "Shop probabilities",
		text = {
			"Collection of tabs which provides you details about",
			"{C:green,E:1,S:1.1}probabilities{} to find any kind of stuff in {C:attention}Shop{}:",
			"{C:mult}Rarities{}, {C:dark_edition}Editions{}, {C:blue}Seals{}, etc.",
		},
	},
})

local PoolProbabilities = setmetatable({
	keep_shop_slots_in_pool = true,

	last_rerender = {
		Pool = 0,
		Rarity = 0,
		Edition = 0,
		Enhanced = 0,
		Seal = 0,
		Booster = 0,
		Voucher = 0,
	},
	pages = {
		Pool = 1,
		Rarity = 1,
		Edition = 1,
		Enhanced = 1,
		Seal = 1,
		Booster = 1,
		Voucher = 1,
	},

	modifier_index = 1,

	paginate_sorted_items = function(self, items, items_per_page, pool)
		local max_page = math.ceil(#items / items_per_page)
		self.pages[pool] = math.max(1, math.min(self.pages[pool] or 1, max_page))
		local items_to_render = TheFamily.utils.table_copy_part(
			items,
			items_per_page * (self.pages[pool] - 1) + 1,
			(items_per_page * self.pages[pool]) + 1
		)
		local pagination_to_render = nil
		if max_page > 1 then
			local options = {}
			for i = 1, max_page do
				table.insert(options, localize("k_page") .. " " .. tostring(i) .. "/" .. tostring(max_page))
			end
			pagination_to_render = {
				n = G.UIT.R,
				config = {
					padding = 0.05,
					align = "cm",
				},
				nodes = {
					create_option_cycle({
						options = options,
						opt_callback = "thefamily_update_pools_page",
						current_option = self.pages[pool],
						colour = G.C.RED,
						scale = 0.6,
						w = 4,
						thefamily_pool = pool,
					}),
				},
			}
		end
		return items_to_render, pagination_to_render
	end,

	pool_info_for = {
		Edition = 1,
		Enhanced = 1,
	},
	pool_info = {
		Edition = {
			base_item_weight = 1,
			base_item_rate = 4 / 96,
			modifiers = { 1, 2, 5 },
			badge_colour = G.C.DARK_EDITION,
			get_vanilla = function()
				return {
					{
						key = "Foil",
						loc_key = "e_foil",
						weight = 20,
						scaled_weight = 20 * G.GAME.edition_rate,
					},
					{
						key = "Holographic",
						loc_key = "e_holo",
						weight = 14,
						scaled_weight = 14 * G.GAME.edition_rate,
					},
					{
						key = "Polychrome",
						loc_key = "e_polychrome",
						weight = 3,
						scaled_weight = 3 * G.GAME.edition_rate,
					},
					{
						key = "Negative",
						loc_key = "e_negative",
						weight = 3,
						scaled_weight = 3,
					},
				}
			end,
		},
		Enhanced = {
			base_item_weight = 5,
			base_item_rate = 40 / 60,
			modifiers = { 0, 1, 1 },
			badge_colour = G.C.SECONDARY_SET.Enhanced,
			get_vanilla = function()
				return {
					{
						key = "Bonus",
						loc_key = "m_bonus",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Mult",
						loc_key = "m_mult",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Wild Card",
						loc_key = "m_wild",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Glass Card",
						loc_key = "m_glass",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Steel Card",
						loc_key = "m_steel",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Stone Card",
						loc_key = "m_stone",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Gold Card",
						loc_key = "m_gold",
						weight = 5,
						scaled_weight = 5,
					},
					{
						key = "Lucky Card",
						loc_key = "m_lucky",
						weight = 5,
						scaled_weight = 5,
					},
				}
			end,
		},
		Seal = {
			base_item_weight = 5,
			base_item_rate = 2 / 98,
			-- Third one should be 10 too, but it's bugged xd
			modifiers = { 0, 10, 0 },

			get_vanilla = function()
				return {
					{
						key = "Red",
						loc_key = "Red",
						weight = 5,
						scaled_weight = 5,
						badge_colour = G.C.RED,
					},
					{
						key = "Blue",
						loc_key = "Blue",
						weight = 5,
						scaled_weight = 5,
						badge_colour = G.C.BLUE,
					},
					{
						key = "Gold",
						loc_key = "Gold",
						weight = 5,
						badge_colour = G.C.GOLD,
						scaled_weight = 5,
					},
					{
						key = "Purple",
						loc_key = "Purple",
						weight = 5,
						scaled_weight = 5,
						badge_colour = G.C.PURPLE,
					},
				}
			end,
		},
	},
	get_pool_info = function(self, pool)
		local pool_info = self.pool_info[pool]
		return {
			base_item_rate = pool_info.base_item_rate,
			base_item_weight = pool_info.base_item_weight,
			modifier = pool_info.modifiers[self.modifier_index] or 1,
			modifier_index = self.modifier_index,
			get_vanilla = pool_info.get_vanilla,
			badge_colour = pool_info.badge_colour,
		}
	end,

	count_items_left_in_pool = function(self, pool)
		local items_in_pool = #pool
		local items_left_in_pool = items_in_pool

		local keys_in_shop = {}
		if self.keep_shop_slots_in_pool then
			if G.shop_jokers then
				for _, card in ipairs(G.shop_jokers.cards) do
					keys_in_shop[card.config.center.key] = true
				end
			end
			if G.shop_vouchers then
				for _, card in ipairs(G.shop_vouchers.cards) do
					keys_in_shop[card.config.center.key] = true
				end
			end
			if G.shop_booster then
				for _, card in ipairs(G.shop_booster.cards) do
					keys_in_shop[card.config.center.key] = true
				end
			end
			if G.pack_cards then
				for _, card in ipairs(G.pack_cards.cards) do
					keys_in_shop[card.config.center.key] = true
				end
			end
		end

		local is_showman_present = next(find_joker("Showman"))
		local showman_check = (SMODS and SMODS.showman) or function(key)
			return is_showman_present
		end
		local is_unlocked = function(item)
			if SMODS or (item.set == "Voucher" or item.set == "Joker") then
				return item.unlocked
			else
				return true
			end
		end
		local is_softlocked = function(item)
			return item.set == "Planet"
				and item.config
				and item.config.softlock
				and item.config.hand_type
				and (not G.GAME.hands[item.config.hand_type] or G.GAME.hands[item.config.hand_type].played == 0)
		end

		local has_rarity = false
		for _, item in ipairs(pool) do
			has_rarity = has_rarity or not not item.rarity
			if item.hidden then
				items_in_pool = items_in_pool - 1
				items_left_in_pool = items_left_in_pool - 1
			else
				if
					not is_unlocked(item)
					or is_softlocked(item)
					or item.hidden
					or (G.GAME.used_jokers[item.key] and not keys_in_shop[item.key] and not showman_check(item.key))
				then
					items_left_in_pool = items_left_in_pool - 1
				end
			end
		end
		return items_in_pool, items_left_in_pool, has_rarity
	end,

	get_sorted_rarities = function(self)
		local rarities_list = {}
		if SMODS and SMODS.Rarities then
			-- Taken from SMODS
			local available_rarities = copy_table(SMODS.ObjectTypes["Joker"].rarities)
			local total_weight = 0
			for _, v in ipairs(available_rarities) do
				local rarity = SMODS.Rarities[v.key]
				if rarity and (not rarity.in_pool or rarity:in_pool()) then
					v.mod = G.GAME[tostring(v.key):lower() .. "_mod"] or 1
					if rarity.get_weight then
						v.weight = rarity:get_weight(v.weight, SMODS.ObjectTypes["Joker"])
					end
					v.weight = v.weight * v.mod
					total_weight = total_weight + v.weight
				end
			end
			for index, v in ipairs(available_rarities) do
				local rarity = SMODS.Rarities[v.key]
				if rarity and (not rarity.in_pool or rarity:in_pool()) then
					v.weight = total_weight == 0 and 0 or v.weight / total_weight
					local vanilla_rarities = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4 }
					local pool = G.P_JOKER_RARITY_POOLS[vanilla_rarities[rarity.key] or rarity.key]
					local items_in_pool, items_left_in_pool = self:count_items_left_in_pool(pool)
					table.insert(rarities_list, {
						key = rarity.key,
						localized = SMODS.Rarity:get_rarity_badge(v.key),
						badge_colour = rarity.badge_colour,
						weight = v.weight,
						items_count = items_in_pool,
						items_left = items_left_in_pool,
						index = index,
					})
				end
			end
		else
			local weights = { 0.7, 0.25, 0.05, 0 }
			for i, key in ipairs({ "Common", "Uncommon", "Rare" }) do
				local pool = G.P_JOKER_RARITY_POOLS[i]
				local items_in_pool, items_left_in_pool = self:count_items_left_in_pool(pool)
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
	get_sorted_pools = function(self)
		local pools_list = {}
		local total_weight = G.GAME.playing_card_rate
		table.insert(pools_list, {
			key = "Playing",
			index = 1,
			localized = localize("k_base_cards"),
			badge_colour = G.C.SECONDARY_SET.Enhanced,
			weight = G.GAME.playing_card_rate,
			no_rate = true,
		})
		local pools
		if SMODS and SMODS.ConsumableType then
			pools = TheFamily.utils.table_merge({}, SMODS.ConsumableType.ctype_buffer)
		else
			pools = { "Spectral", "Tarot", "Planet" }
		end
		table.insert(pools, 1, "Joker")
		for index, _pool in ipairs(pools) do
			local weight = G.GAME[_pool:lower() .. "_rate"]

			local pool = G.P_CENTER_POOLS[_pool]
			local items_in_pool, items_left_in_pool, has_rarity = self:count_items_left_in_pool(pool)

			local v = {
				key = _pool,
				localized = localize("k_" .. _pool:lower()),
				badge_colour = G.C.SECONDARY_SET[_pool],
				weight = weight,
				items_count = items_in_pool,
				items_left = items_left_in_pool,
				index = index + 2,
				has_rarity = has_rarity,
			}
			table.insert(pools_list, v)
			total_weight = total_weight + weight
		end
		for _, v in ipairs(pools_list) do
			v.weight = total_weight == 0 and 0 or v.weight / total_weight
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
	get_sorted_pool = function(self, pool)
		local items_list = {}
		local pool_info = self:get_pool_info(pool)
		if SMODS then
			local available_items = G.P_CENTER_POOLS[pool]
			local total_weight = 0
			local total_scaled_weight = 0
			for index, item in ipairs(available_items) do
				local should_skip = (item.in_pool and not item:in_pool())
					or (pool == "Edition" and item.key == "e_base")
				if not should_skip then
					total_weight = total_weight + (item.weight or pool_info.base_item_weight)
					local localized = ""
					if pool == "Seal" then
						localized = localize({ set = "Other", type = "name_text", key = item.key:lower() .. "_seal" })
					else
						localized = localize({ set = pool, type = "name_text", key = item.key })
					end
					local v = {
						key = item.key,
						index = index,
						weight = item.get_weight and item:get_weight() or item.weight or pool_info.base_item_weight,
						localized = localized,
						badge_colour = item.badge_colour or pool_info.badge_colour,
						detailed_tooltip = item,
					}
					table.insert(items_list, v)
					total_scaled_weight = total_scaled_weight + v.weight
					if pool == "Edition" and item.key == "e_negative" and pool_info.modifier_index ~= 1 then
						local prev = items_list[index - 1]
						prev.weight = prev.weight + v.weight
						v.weight = 0
					end
				end
			end
			total_weight = total_weight + (total_weight / pool_info.base_item_rate)
			for _, v in ipairs(items_list) do
				v.rate = total_weight == 0 and 0 or v.weight / total_weight * pool_info.modifier
				v.weight = total_scaled_weight == 0 and 0 or v.weight / total_scaled_weight
			end
		else
			local available_items = pool_info.get_vanilla()
			local total_weight = 0
			local total_scaled_weight = 0
			for index, item in ipairs(available_items) do
				total_weight = total_weight + item.weight
				local localized = ""
				if pool == "Seal" then
					localized = localize({ set = "Other", type = "name_text", key = item.key:lower() .. "_seal" })
				else
					localized = localize({ set = pool, type = "name_text", key = item.loc_key })
				end
				local v = {
					key = item.key,
					index = index,
					weight = item.scaled_weight or pool_info.base_item_weight,
					localized = localized,
					badge_colour = item.badge_colour or pool_info.badge_colour,
					detailed_tooltip = item,
				}
				table.insert(items_list, v)
				total_scaled_weight = total_scaled_weight + v.weight
				if pool == "Edition" and item.key == "e_negative" and pool_info.modifier_index ~= 1 then
					local prev = items_list[index - 1]
					prev.weight = prev.weight + v.weight
					v.weight = 0
				end
			end
			total_weight = total_weight + (total_weight / pool_info.base_item_rate)
			for _, v in ipairs(items_list) do
				v.rate = total_weight == 0 and 0 or v.weight / total_weight * pool_info.modifier
				v.weight = total_scaled_weight == 0 and 0 or v.weight / total_scaled_weight
			end
		end
		table.sort(items_list, function(a, b)
			if a.weight ~= b.weight then
				return a.weight > b.weight
			else
				return a.index < b.index
			end
		end)
		return items_list
	end,
	get_sorted_boosters = function(self)
		local boosters_list = {}
		local boosters_dictionary = {}
		local available_boosters = G.P_CENTER_POOLS.Booster
		local total_weight = 0
		local index = 0
		for _, item in ipairs(available_boosters) do
			if not item.in_pool or item:in_pool() then
				local scaled_weight = item.get_weight and item:get_weight() or item.weight or 1
				total_weight = total_weight + scaled_weight
				local kind = item.kind or item.group_key or localize("k_booster_group_" .. item.key)
				if boosters_dictionary[kind] then
					boosters_dictionary[kind].weight = boosters_dictionary[kind].weight + scaled_weight
				else
					local localized = ""
					if item.kind then
						localized = localize("k_" .. item.kind:lower() .. "_pack")
						if localized == "ERROR" then
							localized = ""
						end
					end
					if localized == "" and item.group_key then
						localized = localize(item.group_key)
						if localized == "ERROR" then
							localized = ""
						end
					end
					if localized == "" then
						localized = localize("k_booster_group_" .. item.key)
					end
					index = index + 1
					boosters_dictionary[kind] = {
						kind = kind,
						index = index,
						weight = scaled_weight,
						localized = localized,
						badge_colour = G.C.BOOSTER,
						detailed_tooltip = item,
					}
				end
			end
		end
		for k, v in pairs(boosters_dictionary) do
			v.weight = total_weight == 0 and 0 or v.weight / total_weight
			table.insert(boosters_list, v)
		end
		table.sort(boosters_list, function(a, b)
			if a.weight ~= b.weight then
				return a.weight > b.weight
			else
				return a.index < b.index
			end
		end)
		return boosters_list
	end,
	get_sorted_vouchers = function(self)
		local vouchers_deps = {}
		local voucher_levels = {}
		local vouchers_level_pools = {}
		local vouchers_in_pool = {}
		local total_vouchers = 0
		local redeemable_vouchers = 0
		for _, voucher in ipairs(G.P_CENTER_POOLS.Voucher) do
			vouchers_deps[voucher.key] = voucher.requires or {}
			if (not voucher.in_pool or voucher:in_pool()) and G.P_CENTERS[voucher.key].unlocked then
				total_vouchers = total_vouchers + 1
				vouchers_in_pool[voucher.key] = true
			end
		end
		local function process_voucher(key)
			if voucher_levels[key] then
				return voucher_levels[key]
			end
			local level = 1
			local is_deps_redeemed = true
			if vouchers_deps[key] then
				local deps = vouchers_deps[key] or {}
				if type(deps) ~= "table" then
					deps = { deps }
				end
				if #deps > 0 then
					for _, voucher_dep in ipairs(vouchers_deps[key]) do
						level = math.max(level, process_voucher(voucher_dep) + 1)
						if not G.GAME.used_vouchers[voucher_dep] then
							is_deps_redeemed = false
						end
					end
				end
			end
			voucher_levels[key] = level
			vouchers_level_pools[level] = vouchers_level_pools[level]
				or {
					level = level,
					items_count = 0,
					items_left = 0,
				}
			if vouchers_in_pool[key] then
				vouchers_level_pools[level].items_count = vouchers_level_pools[level].items_count + 1
				if not G.GAME.used_vouchers[key] and is_deps_redeemed then
					redeemable_vouchers = redeemable_vouchers + 1
					vouchers_level_pools[level].items_left = vouchers_level_pools[level].items_left + 1
				end
			end
			table.insert(vouchers_level_pools[level], key)
			return level
		end
		for _, voucher in ipairs(G.P_CENTER_POOLS.Voucher) do
			process_voucher(voucher.key)
		end
		local result = {}

		for k, v in pairs(vouchers_level_pools) do
			v.weight = redeemable_vouchers == 0 and 0 or v.items_left / redeemable_vouchers
			v.rate = v.items_left == 0 and 0 or v.weight / v.items_left
			table.insert(result, v)
		end
		table.sort(result, function(a, b)
			return a.level < b.level
		end)
		return result
	end,

	create_UI_table_head = function(self, columns)
		local result_columns = {}
		for index, column in ipairs(columns) do
			table.insert(result_columns, {
				n = G.UIT.C,
				config = {
					minw = column.w or 1,
					maxw = column.w or 1,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = column.text,
							scale = column.scale or 0.3,
							colour = column.colour or G.C.UI.TEXT_DARK,
							align = "cm",
						},
					},
				},
			})
			if index < #columns then
				table.insert(result_columns, {
					n = G.UIT.C,
				})
			end
		end
		return {
			{
				n = G.UIT.R,
				config = {
					padding = 0.025,
					align = "cm",
				},
				nodes = result_columns,
			},
			{
				n = G.UIT.R,
				config = {
					minh = 0.05,
				},
			},
		}
	end,
	create_UI_table_row = function(self, columns)
		local result_columns = {}
		for index, column in ipairs(columns) do
			if column.badge then
				table.insert(result_columns, {
					n = G.UIT.C,
					config = {
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
										colour = column.badge_colour or G.C.GREEN,
										r = 0.1,
										minw = 2.5,
										minh = 0.25,
										emboss = 0.05,
										maxw = 2.5,
										padding = 0.075,
										detailed_tooltip = column.detailed_tooltip,
									},
									nodes = {
										{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
										{
											n = G.UIT.O,
											config = {
												object = DynaText({
													string = column.text or "ERROR",
													colours = { column.badge_text_colour or G.C.WHITE },
													shadow = true,
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
				})
			else
				local text_parts = {}
				for _, part in ipairs(column.texts or {}) do
					table.insert(text_parts, {
						n = G.UIT.T,
						config = {
							text = part.text,
							scale = part.scale or 0.3,
							colour = part.colour or G.C.UI.TEXT_DARK,
							align = "cm",
						},
					})
				end
				table.insert(result_columns, {
					n = G.UIT.C,
					config = {
						minw = column.w or 1,
						maxw = column.w or 1,
						align = "cm",
					},
					nodes = text_parts,
				})
			end
			if index < #columns then
				table.insert(result_columns, {
					n = G.UIT.C,
				})
			end
		end
		return {
			n = G.UIT.R,
			config = {
				padding = 0.025,
				align = "cm",
			},
			nodes = result_columns,
		}
	end,
	create_UI_keep_shop_slots_in_pool_toggle = function(self, definition)
		return create_toggle({
			label = "",
			ref_table = self,
			ref_value = "keep_shop_slots_in_pool",
			scale = 0.5,
			label_scale = 0.3,
			w = 0,
			callback = function()
				definition:rerender_popup()
			end,
		})
	end,

	get_UI_pools = function(self)
		local pools = self:get_sorted_pools()
		local result = self:create_UI_table_head({
			{
				w = 2.5,
				text = "Card type",
			},
			{
				w = 1.2,
				text = "Weight",
			},
			{
				w = 1.2,
				text = "Left",
			},
			{
				w = 1.2,
				text = "Rate",
			},
		})
		local pools_to_render, pagination = self:paginate_sorted_items(pools, 5, "Pool")
		for _, pool in ipairs(pools_to_render) do
			table.insert(
				result,
				self:create_UI_table_row({
					{
						badge = true,
						badge_colour = pool.badge_colour,
						text = pool.localized,
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%0.3f%%", pool.weight * 100),
								colour = G.C.CHIPS,
							},
						},
					},
					{
						w = 1.2,
						texts = {
							{
								text = pool.no_rate and "-" or string.format("%s ", pool.items_left),
								colour = G.C.CHIPS,
							},
							{
								text = (pool.no_rate or pool.has_rarity) and "" or string.format(
									"(%0.3f%%)",
									pool.items_left == 0 and 0 or 1 / pool.items_left * 100
								),
								colour = adjust_alpha(G.C.UI.TEXT_DARK, 0.6),
							},
						},
					},
					{
						w = 1.2,
						texts = {
							{
								text = (pool.no_rate or pool.has_rarity) and "-" or string.format(
									"%0.3f%%",
									pool.items_left == 0 and 0 or pool.weight / pool.items_left * 100
								),
								colour = G.C.CHIPS,
							},
						},
					},
				})
			)
		end
		table.insert(result, pagination)
		return result
	end,
	get_UI_rarities = function(self)
		local rarities = self:get_sorted_rarities()
		local result = self:create_UI_table_head({
			{
				w = 2.5,
				text = "Rarity",
			},
			{
				w = 1.2,
				text = "Weight",
			},
			{
				w = 1,
				text = "Left",
			},
			{
				w = 1.2,
				text = "Rate",
			},
		})
		local rarities_to_render, pagination = self:paginate_sorted_items(rarities, 8, "Rarity")
		for _, rarity in ipairs(rarities_to_render) do
			table.insert(
				result,
				self:create_UI_table_row({
					{
						badge = true,
						text = rarity.localized,
						badge_colour = rarity.badge_colour,
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%0.3f%%", rarity.weight * 100),
								colour = G.C.CHIPS,
							},
						},
					},
					{
						w = 1,
						texts = {
							{
								text = string.format("%s", rarity.items_left),
								colour = G.C.CHIPS,
							},
						},
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format(
									"%0.3f%%",
									rarity.items_left == 0 and 0 or rarity.weight / rarity.items_left * 100
								),
								colour = G.C.CHIPS,
							},
						},
					},
				})
			)
		end
		table.insert(result, pagination)
		return result
	end,
	get_UI_pool = function(self, pool, first_column)
		local editions = self:get_sorted_pool(pool)
		local result = self:create_UI_table_head({
			{
				w = 2.5,
				text = first_column,
			},
			{
				w = 1.2,
				text = "Weight",
			},
			{
				w = 1.2,
				text = "Rate",
			},
		})
		local pools_to_render, pagination = self:paginate_sorted_items(editions, 8, pool)
		for _, edition in ipairs(pools_to_render) do
			table.insert(
				result,
				self:create_UI_table_row({
					{
						badge = true,
						badge_colour = edition.badge_colour,
						detailed_tooltip = edition.detailed_tooltip,
						text = edition.localized,
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%0.3f%%", edition.weight * 100),
								colour = G.C.CHIPS,
							},
						},
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%0.3f%%", edition.rate * 100),
								colour = G.C.CHIPS,
							},
						},
					},
				})
			)
		end
		table.insert(result, pagination)
		return result
	end,
	get_UI_boosters = function(self)
		local pools = self:get_sorted_boosters()
		local result = self:create_UI_table_head({
			{
				w = 2.5,
				text = "Booster pack",
			},
			{
				w = 1.2,
				text = "Weight",
			},
		})
		local pools_to_render, pagination = self:paginate_sorted_items(pools, 8, "Booster")
		for _, pool in ipairs(pools_to_render) do
			table.insert(
				result,
				self:create_UI_table_row({
					{
						badge = true,
						badge_colour = pool.badge_colour,
						detailed_tooltip = pool.detailed_tooltip,
						text = pool.localized,
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%0.3f%%", pool.weight * 100),
								colour = G.C.CHIPS,
							},
						},
					},
				})
			)
		end
		table.insert(result, pagination)
		return result
	end,
	get_UI_vouchers = function(self)
		local vouchers = self:get_sorted_vouchers()
		local result = self:create_UI_table_head({
			{
				w = 1.2,
				text = "Level",
			},
			{
				w = 1.2,
				text = "Weight",
			},
			{
				w = 1.2,
				text = "Left",
			},
		})
		local pools_to_render, pagination = self:paginate_sorted_items(vouchers, 10, "Voucher")
		for _, rarity in ipairs(pools_to_render) do
			table.insert(
				result,
				self:create_UI_table_row({
					{
						w = 1.2,
						texts = {
							{
								text = string.format("Level %s", rarity.level),
								colour = G.C.SECONDARY_SET.Voucher,
							},
						},
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%0.3f%%", rarity.weight * 100),
								colour = G.C.CHIPS,
							},
						},
					},
					{
						w = 1.2,
						texts = {
							{
								text = string.format("%s ", rarity.items_left),
								colour = G.C.CHIPS,
							},
							{
								text = string.format("(%0.3f%%)", rarity.rate * 100),
								colour = adjust_alpha(G.C.UI.TEXT_DARK, 0.6),
							},
						},
					},
				})
			)
		end
		table.insert(result, pagination)
		return result
	end,

	create_UI_pools_popup = function(self, definition, card)
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
				self:get_UI_pools(),
				{
					{
						n = G.UIT.R,
						config = {
							padding = 0.05,
							r = 0.1,
							colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.C,
								config = { minw = 0.1 },
							},
							{
								n = G.UIT.C,
								config = { align = "cm" },
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = "Ignore shop/booster slots",
											scale = 0.3,
											colour = G.C.WHITE,
										},
									},
								},
							},
							{
								n = G.UIT.C,
								nodes = {
									self:create_UI_keep_shop_slots_in_pool_toggle(definition),
								},
							},
							{
								n = G.UIT.C,
								config = { minw = 0.1 },
							},
						},
					},
					TheFamily.UI.PARTS.create_separator_r(0.1),
					{
						n = G.UIT.R,
						nodes = TheFamily.UI.localize_text({
							"{C:inactive}Gray percents represent probability to{}",
							"{C:inactive}find{} {C:attention}one specific{} {C:inactive}card of this type{}",
						}, {
							align = "cm",
							default_col = G.C.UI.TEXT_DARK,
						}),
					},
				},
			},
		}
	end,
	create_UI_rarities_popup = function(self, definition, card)
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
				self:get_UI_rarities(),
				{
					{
						n = G.UIT.R,
						config = {
							padding = 0.05,
							r = 0.1,
							colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.C,
								config = { minw = 0.1 },
							},
							{
								n = G.UIT.C,
								config = { align = "cm" },
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = "Ignore shop/booster slots",
											scale = 0.3,
											colour = G.C.WHITE,
										},
									},
								},
							},
							{
								n = G.UIT.C,
								nodes = {
									self:create_UI_keep_shop_slots_in_pool_toggle(definition),
								},
							},
							{
								n = G.UIT.C,
								config = { minw = 0.1 },
							},
						},
					},
				},
			},
		}
	end,
	create_UI_pool_popup = function(self, definition, card, pool, title, first_column)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = title,
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				self:get_UI_pool(pool, first_column),
				{
					create_option_cycle({
						options = { "Shop", "Standard Pack", "Illusion voucher" },
						opt_callback = "thefamily_update_pools_modifier_index",
						current_option = self.modifier_index,
						colour = G.C.RED,
						scale = 0.6,
						w = 4,
					}),
				},
			},
		}
	end,
	create_UI_vouchers_popup = function(self, definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Shop probabilities: Vouchers",
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				self:get_UI_vouchers(),
				{
					{
						n = G.UIT.R,
						nodes = TheFamily.UI.localize_text({
							"{C:inactive}Gray percents represent probability to{}",
							"{C:inactive}find{} {C:attention}one specific{} {C:inactive}voucher of this level{}",
						}, {
							align = "cm",
						}),
					},
				},
			},
		}
	end,
	create_UI_boosters_popup = function(self, definition, card)
		return {
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Shop probabilities: Booster types",
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				self:get_UI_boosters(),
			},
		}
	end,
}, {})
PoolProbabilities.tabs = {
	Pool = TheFamily.create_tab({
		key = "thefamily_pools_pools",
		order = 1,
		group_key = "thefamily_shop_pools",
		center = "v_overstock_norm",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Card types",
		},

		front_label = function()
			return {
				text = "Card types",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Pool = love.timer.getTime()
			return PoolProbabilities:create_UI_pools_popup(definition, card)
		end,
		update = function(definition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Pool + 3 < now then
				PoolProbabilities.last_rerender.Pool = now
				definition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
	Rarity = TheFamily.create_tab({
		key = "thefamily_pools_rarities",
		order = 2,
		group_key = "thefamily_shop_pools",
		center = "v_hone",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Rarities",
		},

		front_label = function()
			return {
				text = "Rarities",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Rarity = love.timer.getTime()
			return PoolProbabilities:create_UI_rarities_popup(definition, card)
		end,
		update = function(defuninition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Rarity + 3 < now then
				PoolProbabilities.last_rerender.Rarity = now
				defuninition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
	Enhanced = TheFamily.create_tab({
		key = "thefamily_pools_enhanced",
		order = 3,
		group_key = "thefamily_shop_pools",
		center = "v_tarot_tycoon",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Enhancements",
		},

		front_label = function()
			return {
				text = "Enhancements",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Enhanced = love.timer.getTime()
			return PoolProbabilities:create_UI_pool_popup(
				definition,
				card,
				"Enhanced",
				"Shop probabilities: Enhancements",
				"Enhancement"
			)
		end,
		update = function(defuninition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Enhanced + 3 < now then
				PoolProbabilities.last_rerender.Enhanced = now
				defuninition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
	Seal = TheFamily.create_tab({
		key = "thefamily_pools_seal",
		order = 4,
		group_key = "thefamily_shop_pools",
		center = "v_illusion",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Seals",
		},

		front_label = function()
			return {
				text = "Seals",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Seal = love.timer.getTime()
			return PoolProbabilities:create_UI_pool_popup(definition, card, "Seal", "Shop probabilities: Seals", "Seal")
		end,
		update = function(defuninition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Seal + 3 < now then
				PoolProbabilities.last_rerender.Seal = now
				defuninition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
	Edition = TheFamily.create_tab({
		key = "thefamily_pools_editions",
		order = 5,
		group_key = "thefamily_shop_pools",
		center = "v_glow_up",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Editions",
		},

		front_label = function()
			return {
				text = "Editions",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Edition = love.timer.getTime()
			return PoolProbabilities:create_UI_pool_popup(
				definition,
				card,
				"Edition",
				"Shop probabilities: Editions",
				"Edition"
			)
		end,
		update = function(defuninition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Edition + 3 < now then
				PoolProbabilities.last_rerender.Edition = now
				defuninition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
	Booster = TheFamily.create_tab({
		key = "thefamily_pools_boosters",
		order = 6,
		group_key = "thefamily_shop_pools",
		center = "v_overstock_plus",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Booster packs",
		},

		front_label = function()
			return {
				text = "Booster packs",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Booster = love.timer.getTime()
			return PoolProbabilities:create_UI_boosters_popup(definition, card)
		end,
		update = function(definition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Booster + 3 < now then
				PoolProbabilities.last_rerender.Booster = now
				definition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
	Voucher = TheFamily.create_tab({
		key = "thefamily_pools_vouchers",
		order = 7,
		group_key = "thefamily_shop_pools",
		center = "v_antimatter",
		type = "switch",

		original_mod_id = "TheFamily",
		loc_txt = {
			name = "Vouchers",
		},

		front_label = function()
			return {
				text = "Vouchers",
			}
		end,
		popup = function(definition, card)
			PoolProbabilities.last_rerender.Voucher = love.timer.getTime()
			return PoolProbabilities:create_UI_vouchers_popup(definition, card)
		end,
		update = function(definition, card, dt)
			local now = love.timer.getTime()
			if card and card.children.popup and PoolProbabilities.last_rerender.Voucher + 3 < now then
				PoolProbabilities.last_rerender.Voucher = now
				definition:rerender_popup()
			end
		end,

		keep_popup_when_highlighted = true,
	}),
}

TheFamily.own_tabs.pools_probabilities = PoolProbabilities

--

function G.FUNCS.thefamily_update_pools_modifier_index(arg)
	PoolProbabilities.modifier_index = arg.to_key
	for pool, tab in pairs(PoolProbabilities.tabs) do
		tab:rerender_popup()
	end
end
function G.FUNCS.thefamily_update_pools_page(arg)
	local pool = arg.cycle_config.thefamily_pool
	PoolProbabilities.pages[pool] = arg.to_key
	local tab = PoolProbabilities.tabs[arg.cycle_config.thefamily_pool]
	if tab then
		tab:rerender_popup()
	end
end
