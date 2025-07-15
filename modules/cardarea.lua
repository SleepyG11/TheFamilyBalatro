-- function printCallerInfo()
-- 	-- Get debug info for the caller of the function that called printCallerInfo
-- 	local info = debug.getinfo(3, "Sl")
-- 	if info then
-- 		print((info.short_src or "???") .. ":" .. (info.currentline or "unknown"))
-- 	else
-- 		print("Caller information not available")
-- 	end
-- end

TheFamilyCardArea = CardArea:extend()

function TheFamilyCardArea:init()
	CardArea.init(self, 0, 0, G.CARD_W * 0.5, G.CARD_H * 0.5, {
		card_limit = 25,
		type = "thefamily_tabs",
		highlight_limit = 1,
	})
	self.cards = self.cards or {}
	self.states.collide.can = true
	self.states.hover.can = true

	self.opened_tabs = {
		--- @type table<string, TheFamilyTab>
		dictionary = {},

		--- @type string | nil
		overlay_key = nil,

		--- @type table<string, table<string, TheFamilyTab>>
		switch_overlays = {},
	}
	self.rendered_tabs = {
		--- @type table<string, TheFamilyTab>
		dictionary = {},
	}

	if TheFamily.UI.area then
		TheFamily.UI.area:remove()
	end
	TheFamily.UI.area = self

	self:_create_container()
end

function TheFamilyCardArea:_create_container()
	local ui_values = TheFamily.UI.get_ui_values()
	local config = {
		align = "tr",
		major = G.ROOM_ATTACH,
		bond = "Strong",
		offset = {
			x = 0,
			y = 1,
		},
		instance_type = "POPUP",
	}
	if ui_values.position_on_screen == "right" then
		config.align = "tr"
		config.offset = {
			x = 0,
			y = 1,
		}
	elseif ui_values.position_on_screen == "left" then
		config.align = "tl"
		config.offset = {
			x = 0.75,
			y = 1,
		}
	elseif ui_values.position_on_screen == "bottom" then
		config.align = "bl"
		config.offset = {
			x = 0,
			y = 0,
		}
	elseif ui_values.position_on_screen == "top" then
		config.align = "tl"
		config.offset = {
			x = 0,
			y = 0,
		}
	end

	local area_container = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = self,
					},
				},
			},
		},
		config = config,
	})
	if TheFamily.UI.area_container then
		TheFamily.UI.area_container:remove()
	end
	TheFamily.UI.area_container = area_container
end

function TheFamilyCardArea:set_card_position(card, index, force_position)
	local ui_values = TheFamily.UI.get_ui_values()
	index = index or 1
	local is_first_card_selected = self.thefamily_is_first_card_selected
	local is_any_card_hovered = self.thefamily_is_any_card_hovered

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

	local dx_scale = ui_values.scale / 0.4

	if ui_values.position_on_screen == "right" then
		card.T.x = self.T.x
			- (highlight_dx * math.sin(ui_values.r_rad) * dx_scale)
			+ G.ROOM.T.x
			- G.CARD_W * -0.1 * dx_scale
			- G.CARD_H / 2 * ui_values.scale
		card.T.y = self.T.y + (highlight_dx * math.cos(ui_values.r_rad) * dx_scale) + ui_values.gap * index
		card.T.r = ui_values.r_rad
	elseif ui_values.position_on_screen == "left" then
		card.T.x = self.T.x
			+ (highlight_dx * math.sin(ui_values.r_rad) * dx_scale)
			- G.ROOM.T.x
			+ G.CARD_W * -0.1 * dx_scale
		card.T.y = self.T.y + (highlight_dx * math.cos(ui_values.r_rad) * dx_scale) + ui_values.gap * index
		card.T.r = -ui_values.r_rad
	elseif ui_values.position_on_screen == "bottom" then
		card.T.y = self.T.y
			+ (highlight_dx * math.cos(ui_values.r_rad + math.rad(90)) * dx_scale)
			+ G.ROOM.T.y / 2
			- G.CARD_H * -0.1 * dx_scale
			+ G.CARD_W / 2 * ui_values.scale
		card.T.x = self.T.x
			- (highlight_dx * math.sin(ui_values.r_rad + math.rad(90)) * dx_scale)
			+ ui_values.gap * index
		card.T.r = ui_values.r_rad + math.rad(90)
	else
		card.T.x = self.T.x
			- (highlight_dx * math.sin(ui_values.r_rad) * dx_scale)
			+ G.ROOM.T.x
			- G.CARD_W * -0.1 * dx_scale
			- G.CARD_H / 2 * ui_values.scale
		card.T.y = self.T.y + (highlight_dx * math.cos(ui_values.r_rad) * dx_scale) + ui_values.gap * index
		card.T.r = ui_values.r_rad
	end
	if force_position then
		-- TODO: force correct rotation SOMEHOW GODDAMNIT
		card:hard_set_T()
	end
end
function TheFamilyCardArea:align_cards()
	if not self.cards or not self.cards[1] then
		return
	end
	self.thefamily_is_first_card_selected = self.cards[1].highlighted
	self.thefamily_is_any_card_hovered = self.states.hover.is
	self.thefamily_is_any_card_clicked = false
	if not self.thefamily_is_any_card_hovered then
		for _, card in ipairs(self.cards) do
			if card.states.hover.is then
				self.thefamily_is_any_card_hovered = true
			end
			if card.states.click.is then
				self.thefamily_is_any_card_clicked = true
			end
		end
	end

	for index, card in ipairs(self.cards) do
		card.states.collide.can = not G.SETTINGS.paused
		self:set_card_position(card, index)
	end
end
function TheFamilyCardArea:set_ranks()
	for k, card in ipairs(self.cards) do
		card.rank = k
	end
end
function TheFamilyCardArea:emplace(card)
	if TheFamily.__prevent_used_jokers or not card then
		return
	end

	if self.__emplace_index then
		table.insert(self.cards, self.__emplace_index, card)
	else
		self.cards[#self.cards + 1] = card
	end

	card:set_card_area(self)
	self:set_ranks()

	local tab = card.thefamily_tab
	if tab and tab.key then
		if self:_is_tab_opened(tab) then
			self:_highlight_tab(tab)
		elseif tab:_can_force_highlight() then
			self:_open_and_highlight(tab)
		end
	end

	self:align_cards()
	self:set_card_position(card, self.__emplace_index or #self.cards, true)
end
function TheFamilyCardArea:replace(card, replace_index)
	if TheFamily.__prevent_used_jokers or not card then
		return
	end

	local target_card = self.cards[replace_index]
	if not target_card then
		return
	end
	local tab = target_card.thefamily_tab
	if tab then
		if not tab.keep then
			self:_close(tab)
		end
		self:_unhighlight_tab(tab)
	end
	target_card:remove()

	self.__emplace_index = replace_index
	self:emplace(card)
	self.__emplace_index = nil
end
function TheFamilyCardArea:remove_card(card)
	if not card then
		return
	end
	local tab = card.thefamily_tab
	if tab and not tab.keep and not self.thefamily_self_remove then
		self:_close(tab)
	end
	for i = #self.highlighted, 1, -1 do
		if self.highlighted[i] == card then
			table.remove(self.highlighted, i)
			break
		end
	end
	for i = #self.cards, 1, -1 do
		if self.cards[i] == card then
			card:remove_from_area()
			table.remove(self.cards, i)
			break
		end
	end
	self:set_ranks()
	return card
end

function TheFamilyCardArea:add_to_highlighted(card)
	if self:_open_and_highlight(card and card.thefamily_tab) then
		play_sound("cardSlide1")
	end
end
function TheFamilyCardArea:remove_from_highlighted(card)
	if self:_close_and_unhighlight(card and card.thefamily_tab) then
		play_sound("cardSlide2", nil, 0.3)
	end
end

function TheFamilyCardArea:draw()
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
function TheFamilyCardArea:update(dt)
	for _, tab in ipairs(TheFamily.tabs.list) do
		if tab:_enabled() and tab.key then
			local is_opened = self:_is_tab_opened(tab)
			if is_opened and not tab:_can_highlight() then
				self:_close_and_unhighlight(tab)
			elseif not is_opened and tab:_can_force_highlight() then
				self:_open_and_highlight(tab)
			end
			tab:update(tab.card, dt)
		end
	end
end

function TheFamilyCardArea:_highlight_tab(tab)
	if tab.card and not tab.card.highlighted then
		self.highlighted[#self.highlighted + 1] = tab.card
		tab.card.highlighted = true
	end
end
function TheFamilyCardArea:_unhighlight_tab(tab)
	if tab.card and tab.card.highlighted then
		for i = #self.highlighted, 1, -1 do
			if self.highlighted[i] == tab.card then
				table.remove(self.highlighted, i)
				break
			end
		end
		tab.card.highlighted = false
	end
end

function TheFamilyCardArea:_add_opened_tab(tab)
	if tab and tab.key then
		self.opened_tabs.dictionary[tab.key] = tab
		if tab.type == "switch" then
			for _, switch_overlay in ipairs(tab.switch_overlays or {}) do
				if not self.opened_tabs.switch_overlays[switch_overlay] then
					self.opened_tabs.switch_overlays[switch_overlay] = {}
				end
				self.opened_tabs.switch_overlays[switch_overlay][tab.key] = tab
			end
		elseif tab.type == "overlay" then
			self.opened_tabs.overlay_key = tab.key
		end
	end
end
function TheFamilyCardArea:_remove_opened_tab(tab)
	if tab and tab.key then
		self.opened_tabs.dictionary[tab.key] = nil
		if tab.type == "switch" then
			for _, switch_overlay in ipairs(tab.switch_overlays or {}) do
				if self.opened_tabs.switch_overlays[switch_overlay] then
					self.opened_tabs.switch_overlays[switch_overlay][tab.key] = nil
				end
			end
		end
		if self.opened_tabs.overlay_key == tab.key then
			self.opened_tabs.overlay_key = nil
		end
	end
end
function TheFamilyCardArea:_add_rendered_tab(tab)
	if tab and tab.key then
		self.rendered_tabs.dictionary[tab.key] = tab
	end
end
function TheFamilyCardArea:_remove_rendered_tab(tab)
	if tab and tab.key then
		self.rendered_tabs.dictionary[tab.key] = nil
	end
end
function TheFamilyCardArea:_is_tab_opened(tab)
	return tab and tab.key and self.opened_tabs.dictionary[tab.key] and true
end

function TheFamilyCardArea:_open(tab, without_callbacks)
	if tab and tab.key then
		if self:_is_tab_opened(tab) or not tab:_can_highlight() then
			return
		end
		if tab.type == "overlay" and not self:_close_overlay() then
			return
		end
		if tab.type == "switch" then
			self:_close_switch_overlays(tab)
		end
		self:_add_opened_tab(tab)
		if not without_callbacks then
			tab:highlight(tab.card)
		end
		return true
	end
end
function TheFamilyCardArea:_close(tab, without_callbacks)
	if tab and tab.key then
		if not self:_is_tab_opened(tab) or not tab:_can_unhighlight() then
			return
		end
		self:_remove_opened_tab(tab)
		if not without_callbacks then
			tab:unhighlight(tab.card)
		end
		return true
	end
end
function TheFamilyCardArea:_close_overlay()
	if self.opened_tabs.overlay_key then
		return self:_close_and_unhighlight(TheFamily.tabs.dictionary[self.opened_tabs.overlay_key])
	else
		return true
	end
end
function TheFamilyCardArea:_close_switch_overlays(tab)
	for _, switch_overlay in ipairs(tab.switch_overlays or {}) do
		if self.opened_tabs.switch_overlays[switch_overlay] then
			local tabs_to_close = {}
			for key, _tab in pairs(self.opened_tabs.switch_overlays[switch_overlay]) do
				if key ~= tab.key then
					table.insert(tabs_to_close, _tab)
				end
			end
			for _, _tab in ipairs(tabs_to_close) do
				_tab:close()
			end
		end
	end
end

function TheFamilyCardArea:_open_and_highlight(tab, without_callbacks)
	if self:_open(tab, without_callbacks) then
		self:_highlight_tab(tab)
		return true
	end
end
function TheFamilyCardArea:_close_and_unhighlight(tab, without_callbacks)
	if self:_close(tab, without_callbacks) then
		self:_unhighlight_tab(tab)
		return true
	end
end

function TheFamilyCardArea:_scroll(dx)
	if not self.thefamily_is_any_card_hovered then
		return
	end
	local ui_values = TheFamily.UI.get_ui_values()
	if ui_values.pagination_type ~= "scroll" then
		return
	end

	local area_width = #TheFamily.UI.area.cards * ui_values.gap
	if ui_values.position_on_screen == "right" or ui_values.position_on_screen == "left" then
		local max_y = 1
		local min_y = math.min(max_y, -area_width + G.ROOM_ATTACH.T.h + 0.5)
		local current_y = TheFamily.UI.area_container.config.offset.y
		local diff_y = (dx > 0 and 0.5) or (dx < 0 and -0.5) or 0
		local new_y = math.min(max_y, math.max(min_y, current_y + diff_y))
		TheFamily.UI.area_container.config.offset.y = new_y
	elseif ui_values.position_on_screen == "top" or ui_values.position_on_screen == "bottom" then
		local max_x = 0
		local min_x = math.min(max_x, -area_width + G.ROOM_ATTACH.T.h + 0.5)
		local current_x = TheFamily.UI.area_container.config.offset.x
		local diff_x = (dx > 0 and -0.5) or (dx < 0 and 0.5) or 0
		local new_x = math.min(max_x, math.max(min_x, current_x + diff_x))
		TheFamily.UI.area_container.config.offset.x = new_x
	end
end

function TheFamilyCardArea:_init_core_tabs()
	if TheFamilyCardArea.core_tabs then
		return
	end
	local function change_page(dx)
		local old_page = TheFamily.UI.page
		TheFamily.UI.page = math.max(1, math.min(TheFamily.UI.max_page, TheFamily.UI.page + dx))
		if TheFamily.UI.page ~= old_page then
			TheFamily.UI.area:create_page_cards()
		end
	end
	TheFamilyCardArea.core_tabs = {
		mod_toggle = TheFamilyTab({
			center = "j_family",
			type = "switch",
			key = "thefamily_core",

			original_mod_id = "TheFamily",

			alert = function(self, card)
				if not card.highlighted then
					return nil
				end
				local ui_values = TheFamily.UI.get_ui_values()
				return {
					definition_function = function()
						local result = TheFamily.UI.PARTS.create_dark_alert(card, {
							{
								n = G.UIT.T,
								config = {
									text = "Config",
									colour = G.C.WHITE,
									scale = 0.45 * ui_values.scale,
								},
							},
						})
						result.definition.config.button = "thefamily_open_options"
						result.definition.config.button_dist = 0.2
						result.config.collideable = true
						return result
					end,
				}
			end,
		}),
		prev_page = TheFamilyTab({
			key = "thefamily_next_page",
			center = "c_base",

			original_mod_id = "TheFamily",

			front_label = function(definition, card)
				return {
					text = "Next page",
				}
			end,
			click = function(definition, card)
				change_page(1)
				return true
			end,
		}),
		next_page = TheFamilyTab({
			key = "thefamily_prev_page",
			center = "c_base",

			original_mod_id = "TheFamily",

			front_label = function(definition, card)
				return {
					text = "Prev page",
				}
			end,
			click = function(definition, card)
				change_page(-1)
				return true
			end,
			alert = function(definition, card)
				local info = TheFamily.UI.get_ui_values()
				return {
					definition_function = function()
						return TheFamily.UI.PARTS.create_dark_alert(card, {
							{
								n = G.UIT.T,
								config = {
									ref_table = TheFamily.UI,
									ref_value = "page",
									scale = 0.4 * info.scale,
									colour = G.C.WHITE,
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
								n = G.UIT.T,
								config = {
									ref_table = TheFamily.UI,
									ref_value = "max_page",
									scale = 0.4 * info.scale,
									colour = G.C.WHITE,
								},
							},
						})
					end,
				}
			end,
		}),
	}
end

function TheFamilyCardArea:_save_rerender_data()
	return {
		opened_tabs = self.opened_tabs,
	}
end
function TheFamilyCardArea:safe_remove()
	self.thefamily_self_remove = true
	self:remove()
	self.thefamily_self_remove = nil
end

function TheFamilyCardArea:create_page_cards()
	local tabs_to_render = {}
	local ui_values = TheFamily.UI.get_ui_values()
	if ui_values.pagination_type == "page" then
		local start_index = 1 + ui_values.tabs_per_page * (TheFamily.UI.page - 1)
		local end_index = start_index + ui_values.tabs_per_page
		local current_index = 1
		for _, group in ipairs(TheFamily.tab_groups.list) do
			if current_index >= end_index then
				break
			end
			if group:_enabled() then
				if #group.enabled_tabs.list + current_index < start_index then
					current_index = current_index + #group.enabled_tabs.list
				else
					for _, tab in ipairs(group.enabled_tabs.list) do
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
		end

		EMPTY(self.rendered_tabs.dictionary)

		for i = 1, ui_values.tabs_per_page do
			if tabs_to_render[i] then
				self.rendered_tabs.dictionary[tabs_to_render[i].key] = tabs_to_render[i]
				tabs_to_render[i]:create_tab_card(self, i + 2)
			else
				TheFamilyTab({
					type = "filler",
				}):create_tab_card(self, i + 2)
			end
		end
	elseif ui_values.pagination_type == "scroll" then
		for _, group in ipairs(TheFamily.tab_groups.list) do
			if group:_enabled() then
				for _, tab in ipairs(group.enabled_tabs.list) do
					table.insert(tabs_to_render, tab)
				end
			end
		end

		EMPTY(self.rendered_tabs.dictionary)

		for i = 1, #tabs_to_render do
			self.rendered_tabs.dictionary[tabs_to_render[i].key] = tabs_to_render[i]
			tabs_to_render[i]:create_tab_card(self, i + 2)
		end
	end
	self:calculate_parrallax()
	self:align_cards()
	self:hard_set_cards()
end
function TheFamilyCardArea:create_initial_cards()
	self:_init_core_tabs()
	TheFamilyCardArea.core_tabs.mod_toggle:create_tab_card(self, nil, true)
	TheFamilyTab({
		type = "separator",
	}):create_tab_card(self, nil, true)
	local ui_values = TheFamily.UI.get_ui_values()
	if ui_values.pagination_type == "page" then
		for i = 1, ui_values.tabs_per_page do
			TheFamilyTab({
				type = "filler",
			}):create_tab_card(self, nil, true)
		end
		TheFamilyTab({
			type = "separator",
		}):create_tab_card(self, nil, true)
		TheFamilyCardArea.core_tabs.prev_page:create_tab_card(self, nil, true)
		TheFamilyCardArea.core_tabs.next_page:create_tab_card(self, nil, true)
	elseif ui_values.pagination_type == "scroll" then
		local items_to_render = 0
		for _, group in ipairs(TheFamily.tab_groups.list) do
			if group:_enabled() then
				items_to_render = items_to_render + #group.enabled_tabs.list
			end
		end
		for i = 1, items_to_render do
			TheFamilyTab({
				type = "filler",
			}):create_tab_card(self, nil, true)
		end
	end
	self:calculate_parrallax()
	self:align_cards()
	self:hard_set_cards()
end
function TheFamilyCardArea:init_cards(rerender_data)
	if rerender_data then
		self.opened_tabs = rerender_data.opened_tabs or self.opened_tabs
	end
	self.thefamily_rerender = not not rerender_data
	self:create_initial_cards()
	self:create_page_cards()
	self.thefamily_rerender = nil
end
