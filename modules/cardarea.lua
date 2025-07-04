TheFamilyCardArea = CardArea:extend()

function TheFamilyCardArea:init(...)
	CardArea.init(self, 0, 0, G.CARD_W * 0.5, G.CARD_H * 0.5, {
		card_limit = 25,
		type = "thefamily_tabs",
		highlight_limit = 1,
	})
	self.states.collide.can = true
	self.states.hover.can = true

	self.opened_tabs = {
		list = {},
		dictionary = {},

		overlay_key = nil,
	}
	self.rendered_tabs = {
		list = {},
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
		card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h)
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
	CardArea.emplace(self, card)
	if
		card
		and card.thefamily_tab
		and card.thefamily_tab.key
		and self.opened_tabs.dictionary[card.thefamily_tab.key]
	then
		self:add_to_highlighted(card, true)
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
function TheFamilyCardArea:unhighlight_tab(card, silent)
	if card and card.thefamily_tab then
		for i = #self.highlighted, 1, -1 do
			if self.highlighted[i] == card then
				table.remove(self.highlighted, i)
				break
			end
		end
		card.highlighted = false
		if not silent then
			card.thefamily_tab:unhighlight(card)
			if card.thefamily_tab.key then
				self.opened_tabs.dictionary[card.thefamily_tab.key] = nil
				if self.opened_tabs.overlay_key == card.thefamily_tab.key then
					self.opened_tabs.overlay_key = nil
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
			if highlighted_card ~= self.cards[1] and highlighted_card.thefamily_tab.type == "overlay" then
				self:remove_from_highlighted(highlighted_card)
				is_deselected = true
				break
			end
		end
	end
	if not is_deselected and self.opened_tabs.overlay_key then
		local deseleted_definition = TheFamily.tabs.dictionary[self.opened_tabs.overlay_key]
		deseleted_definition:unhighlight(nil)
		self.opened_tabs.dictionary[self.opened_tabs.overlay_key] = nil
		self.opened_tabs.overlay_key = nil
	end
end

function TheFamilyCardArea:add_to_highlighted(card, silent)
	if not self.cards or not self.cards[1] then
		return
	end
	if not silent and not card.thefamily_tab:can_highlight(card) then
		return
	end
	self:highlight_tab(card, silent)
	if not silent then
		play_sound("cardSlide1")
	end
end
function TheFamilyCardArea:highlight_tab(card, silent)
	if card and card.thefamily_tab then
		if not silent then
			if card.thefamily_tab.type == "overlay" and card ~= self.cards[1] then
				self:unhighlight_overlay_tab()
			end
		end
		self.highlighted[#self.highlighted + 1] = card
		card.highlighted = true
		if not silent then
			card.thefamily_tab:highlight(card)
			if card.thefamily_tab.key then
				self.opened_tabs.dictionary[card.thefamily_tab.key] = true
				if card.thefamily_tab.type == "overlay" then
					self.opened_tabs.overlay_key = card.thefamily_tab.key
				end
			end
		end
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
	for key, _ in pairs(self.opened_tabs.dictionary) do
		if not self.rendered_tabs.dictionary[key] then
			local tab = TheFamily.tabs.dictionary[key]
			if not tab:can_highlight(nil) then
				tab:unhighlight(nil)
				table.insert(tabs_to_remove, tab.key)
			else
				tab:update(nil, dt)
			end
		end
	end
	for _, key in ipairs(tabs_to_remove) do
		self.opened_tabs.dictionary[key] = nil
		if self.opened_tabs.overlay_key == key then
			self.opened_tabs.overlay_key = nil
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

	self.rendered_tabs.dictionary = {}

	for i = 1, TheFamily.UI.tabs_per_page do
		if tabs_to_render[i] then
			self.rendered_tabs.dictionary[tabs_to_render[i].key] = true
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
