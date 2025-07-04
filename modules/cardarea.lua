TheFamilyCardArea = CardArea:extend()

function TheFamilyCardArea:init(...)
	CardArea.init(self, ...)
end
function TheFamilyCardArea:align_cards()
	if not self.cards or not self.cards[1] then
		return
	end
	self.thefamily_is_first_card_selected = self.cards[1].highlighted
	self.thefamily_is_any_card_hovered = false
	for _, card in ipairs(self.cards) do
		if card and card.states.hover.is then
			self.thefamily_is_any_card_hovered = true
			break
		end
	end

	for index, card in ipairs(self.cards) do
		self:set_card_position(card, index)
	end
end
function TheFamilyCardArea:remove_from_highlighted(card, silent)
	if not self.cards or not self.cards[1] then
		return
	end
	-- TODO: check for force highlight
	self:unhighlight_tab(card, silent)
	if not silent then
		play_sound("cardSlide2", nil, 0.3)
	end
end
function TheFamilyCardArea:add_to_highlighted(card, silent)
	if not self.cards or not self.cards[1] then
		return
	end
	if not silent and not card.thefamily_definition:can_highlight(card) then
		return
	end
	self:highlight_tab(card, silent)
	if not silent then
		play_sound("cardSlide1")
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
	local tabs_to_remove = {}
	for key, _ in pairs(TheFamily.opened_tabs.dictionary) do
		if not TheFamily.rendered_tabs.dictionary[key] then
			local definition = TheFamily.tabs.dictionary[key]
			if type(definition.can_highlight) == "function" and not definition.can_highlight(definition, nil) then
				if type(definition.unhighlight) == "function" then
					definition.unhighlight(definition, nil)
				end
				table.insert(tabs_to_remove, definition.key)
			elseif type(definition.update) == "function" then
				definition.update(definition, nil, dt)
			end
		end
	end
	for _, key in ipairs(tabs_to_remove) do
		TheFamily.opened_tabs.dictionary[key] = nil
		if TheFamily.opened_tabs.overlay_key == key then
			TheFamily.opened_tabs.overlay_key = nil
		end
	end
	CardArea.update(self, dt)
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
		card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h)
	end
end

function TheFamilyCardArea:unhighlight_tab(card, silent)
	if card and card.thefamily_definition then
		for i = #self.highlighted, 1, -1 do
			if self.highlighted[i] == card then
				table.remove(self.highlighted, i)
				break
			end
		end
		card.highlighted = false
		if not silent then
			card.thefamily_definition:unhighlight(card)
			if card.thefamily_definition.key then
				TheFamily.opened_tabs.dictionary[card.thefamily_definition.key] = nil
				if TheFamily.opened_tabs.overlay_key == card.thefamily_definition.key then
					TheFamily.opened_tabs.overlay_key = nil
				end
			end
		end
	end
end
function TheFamilyCardArea:highlight_tab(card, silent)
	if card and card.thefamily_definition then
		if card.thefamily_definition.type == "overlay" and card ~= self.cards[1] then
			self:unhighlight_overlay_tab()
		end
		self.highlighted[#self.highlighted + 1] = card
		card.highlighted = true
		if not silent then
			card.thefamily_definition:highlight(card)
			if card.thefamily_definition.key then
				TheFamily.opened_tabs.dictionary[card.thefamily_definition.key] = true
				if card.thefamily_definition.type == "overlay" then
					TheFamily.opened_tabs.overlay_key = card.thefamily_definition.key
				end
			end
		end
	end
end
function TheFamilyCardArea:unhighlight_overlay_tab()
	-- First card can be selected over limit
	local is_first_selected = self.cards[1].highlighted
	local is_deselected = false
	if #self.highlighted - (is_first_selected and 1 or 0) >= self.config.highlighted_limit then
		-- search for eligible card for deselect
		for _, highlighted_card in ipairs(self.highlighted) do
			if highlighted_card ~= self.cards[1] and highlighted_card.thefamily_definition.type == "overlay" then
				self:remove_from_highlighted(highlighted_card)
				self:unhighlight_tab(highlighted_card)
				is_deselected = true
				break
			end
		end
	end
	if not is_deselected and TheFamily.opened_tabs.overlay_key then
		local deseleted_definition = TheFamily.tabs.dictionary[TheFamily.opened_tabs.overlay_key]
		deseleted_definition:unhighlight(nil)
		TheFamily.opened_tabs.dictionary[TheFamily.opened_tabs.overlay_key] = nil
		TheFamily.opened_tabs.overlay_key = nil
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
			if #group.enabled_tabs + current_index < start_index then
				current_index = current_index + #group.enabled_tabs
			else
				for _, tab in ipairs(group.enabled_tabs) do
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

	TheFamily.rendered_tabs.dictionary = {}

	for i = 1, TheFamily.UI.tabs_per_page do
		if tabs_to_render[i] then
			tabs_to_render[i]:create_card(i + 2)
			TheFamily.rendered_tabs.dictionary[tabs_to_render[i].key] = true
		else
			-- TODO: utility cards
			TheFamily.UI.create_card_area_card({
				filler = true,
			}, i + 2)
		end
	end
end
