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

function TheFamilyCardArea:init(...)
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
	}
	self.rendered_tabs = {
		--- @type table<string, TheFamilyTab>
		dictionary = {},
	}

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
		config = {
			align = "tr",
			major = G.ROOM_ATTACH,
			bond = "Weak",
			offset = {
				x = 0,
				y = 1,
			},
			instance_type = "POPUP",
		},
	})
	area_container.T.r = math.pi / 2

	if TheFamily.UI.area then
		TheFamily.UI.area:remove()
	end
	if TheFamily.UI.area_container then
		TheFamily.UI.area_container:remove()
	end
	TheFamily.UI.area = self
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
	card.T.x = self.T.x
		- (highlight_dx * math.sin(ui_values.r_rad))
		+ G.ROOM.T.x
		- G.CARD_W * (ui_values.scale - 0.5)
		- G.CARD_H / 2 * ui_values.scale
	card.T.y = self.T.y + (highlight_dx * math.cos(ui_values.r_rad)) + ui_values.gap * index
	card.T.r = ui_values.r_rad
	if force_position then
		-- TODO: force correct rotation
		card:hard_set_T()
	end
end
function TheFamilyCardArea:align_cards()
	if not self.cards or not self.cards[1] then
		return
	end
	self.thefamily_is_first_card_selected = self.cards[1].highlighted
	self.thefamily_is_any_card_hovered = self.states.hover.is
	if not self.thefamily_is_any_card_hovered then
		for _, card in ipairs(self.cards) do
			if card.states.hover.is then
				self.thefamily_is_any_card_hovered = true
				break
			end
		end
	end

	for index, card in ipairs(self.cards) do
		self:set_card_position(card, index)
	end
end
function TheFamilyCardArea:set_ranks()
	for k, card in ipairs(self.cards) do
		card.rank = k
	end
end
function TheFamilyCardArea:emplace(card)
	if not card then
		return
	end
	CardArea.emplace(self, card)
	local tab = card.thefamily_tab
	if tab and tab.key then
		if self:_is_tab_opened(tab) then
			self:_highlight_tab(tab)
		elseif tab:_can_force_highlight() then
			self:_open_and_highlight(tab)
		end
	end
end
function TheFamilyCardArea:replace(card, replace_index)
	if not card then
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
	self:emplace(card)
	table.insert(self.cards, replace_index, card)
	self.cards[#self.cards] = nil
	self:set_card_position(card, replace_index, true)
end
function TheFamilyCardArea:remove_card(card)
	if not card then
		return
	end
	local tab = card.thefamily_tab
	if tab and not tab.keep then
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
		if tab.is_enabled and tab.key then
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

function TheFamilyCardArea:create_page_cards()
	local tabs_to_render = {}
	local start_index = 1 + TheFamily.UI.tabs_per_page * (TheFamily.UI.page - 1)
	local end_index = start_index + TheFamily.UI.tabs_per_page
	local current_index = 1
	for _, group in ipairs(TheFamily.tab_groups.list) do
		if current_index >= end_index then
			break
		end
		if group.is_enabled then
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

	for i = 1, TheFamily.UI.tabs_per_page do
		if tabs_to_render[i] then
			self.rendered_tabs.dictionary[tabs_to_render[i].key] = tabs_to_render[i]
			tabs_to_render[i]:create_card(i + 2)
		else
			TheFamilyTab({
				type = "filler",
			}):create_card(i + 2)
		end
	end
end
function TheFamilyCardArea:create_initial_cards()
	local this = self

	local function change_page(dx)
		local old_page = TheFamily.UI.page
		TheFamily.UI.page = math.max(1, math.min(TheFamily.UI.max_page, TheFamily.UI.page + dx))
		if TheFamily.UI.page ~= old_page then
			this:create_page_cards()
		end
	end

	TheFamilyTab({
		center = "j_family",
		type = "switch",
		key = "thefamily_core",
	}):create_card(nil, true)
	TheFamilyTab({
		type = "separator",
	}):create_card(nil, true)
	for i = 1, TheFamily.UI.tabs_per_page do
		TheFamilyTab({
			type = "filler",
		}):create_card(nil, true)
	end
	TheFamilyTab({
		type = "separator",
	}):create_card(nil, true)
	TheFamilyTab({
		key = "thefamily_next_page",
		center = "c_base",
		front_label = function(definition, card)
			return {
				text = "Next page",
			}
		end,
		click = function(definition, card)
			change_page(1)
			return true
		end,
	}):create_card(nil, true)
	TheFamilyTab({
		key = "thefamily_prev_page",
		center = "c_base",
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
					return TheFamily.UI.create_UI_dark_alert(card, {
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
					})
				end,
			}
		end,
	}):create_card(nil, true)
end
function TheFamilyCardArea:init_cards()
	self:create_initial_cards()
	self:create_page_cards()
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
		if tab.type == "overlay" then
			self.opened_tabs.overlay_key = tab.key
		end
	end
end
function TheFamilyCardArea:_remove_opened_tab(tab)
	if tab and tab.key then
		self.opened_tabs.dictionary[tab.key] = nil
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

function TheFamilyCardArea:_open(tab)
	if tab and tab.key then
		if self:_is_tab_opened(tab) or not tab:_can_highlight() then
			return
		end
		if tab.type == "overlay" and not self:_close_overlay() then
			return
		end
		tab:highlight(tab.card)
		self:_add_opened_tab(tab)
		return true
	end
end
function TheFamilyCardArea:_close(tab)
	if tab and tab.key then
		if not self:_is_tab_opened(tab) or not tab:_can_unhighlight() then
			return
		end
		tab:unhighlight(tab.card)
		self:_remove_opened_tab(tab)
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

function TheFamilyCardArea:_open_and_highlight(tab)
	if self:_open(tab) then
		self:_highlight_tab(tab)
		return true
	end
end
function TheFamilyCardArea:_close_and_unhighlight(tab)
	if self:_close(tab) then
		self:_unhighlight_tab(tab)
		return true
	end
end
