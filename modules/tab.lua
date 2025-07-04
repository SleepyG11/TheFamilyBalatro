TheFamilyTab = Object:extend()

local function only_function(a, b)
	return type(a) == "function" and a or b
end

function TheFamilyTab:init(params)
	if TheFamily.tabs.dictionary[params.key] then
		print(string.format("[TheFamily]: Duplicate tab key: %s", params.key))
	end

	self.key = params.key
	self.order = params.order or #TheFamily.tabs.list

	self.group_key = params.group_key or nil
	self.group = nil

	self.type = params.type or "overlay"
	self.keep = params.keep or false

	self.front = params.front or nil
	self.center = params.center or "c_base"
	self.front_label = params.front_label or nil
	self.popup = params.popup or nil
	self.alert = params.alert or nil
	self.keep_popup_when_highlighted = params.keep_popup_when_highlighted or false

	self.can_highlight = only_function(params.can_highlight, self.can_highlight)
	self.highlight = only_function(params.highlight, self.highlight)
	self.unhighlight = only_function(params.unhighlight, self.unhighlight)

	self.update = only_function(params.update, self.update)
	self.click = only_function(params.click, self.click)

	self.enabled = only_function(params.enabled, self.enabled)
	self.is_enabled = false

	self.card = nil

	if self.group_key then
		local group = TheFamily.tab_groups.dictionary[self.group_key]
		if group then
			self.group = group
			table.insert(group.tabs, self)
		else
			self.group = nil
		end
	end

	table.insert(TheFamily.tabs.list, self)
	TheFamily.tabs.dictionary[self.key] = self
end

function TheFamilyTab:enabled()
	return true
end

function TheFamilyTab:can_highlight(card)
	return true
end
function TheFamilyTab:highlight(card) end
function TheFamilyTab:unhighlight(card) end
function TheFamilyTab:click(card) end
function TheFamilyTab:update(card, dt) end

function TheFamilyTab:front_label(card) end
function TheFamilyTab:popup(card) end
function TheFamilyTab:alert(card) end

function TheFamilyTab:create_card(replace_index)
	if not TheFamily.UI.area then
		return
	end
	local this = self
	local area = TheFamily.UI.area
	local card

	TheFamily.__prevent_used_jokers = true
	if self.separator or self.filler then
		card = Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_base, {
			bypass_discovery_center = true,
			bypass_discovery_ui = true,
			discover = false,
		})
		card.no_shadow = true
		if not self.filler then
			card.states.visible = false
			card.states.hover.can = false
		end
		card.states.collide.can = false
		card.states.drag.can = false
		function card:hover()
			return Node.hover(self)
		end
		function card:click() end
	elseif self.center then
		if type(self.center) == "string" then
			card = Card(
				area.T.x + area.T.w / 2,
				area.T.y,
				G.CARD_W,
				G.CARD_H,
				self.front and G.P_CARDS[self.front] or nil,
				G.P_CENTERS[self.center] or G.P_CENTERS.c_base,
				{
					bypass_discovery_center = true,
					bypass_discovery_ui = true,
					discover = false,
				}
			)
		elseif type(self.center) == "function" then
			card = self:center(area)
				or Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_base, {
					bypass_discovery_center = true,
					bypass_discovery_ui = true,
					discover = false,
				})
		end
		card.no_shadow = true
		card.states.collide.can = true
		card.states.hover.can = true
		card.states.drag.can = false
		card.states.visible = true
		function card:click()
			if self.highlighted ~= true then
				TheFamily.UI.area:add_to_highlighted(self)
			else
				TheFamily.UI.area:remove_from_highlighted(self)
			end
		end
	end
	TheFamily.__prevent_used_jokers = nil

	if self.emplace and area then
		area:emplace(card)
	elseif replace_index and area and (area.cards or {})[replace_index] then
		local target_index = replace_index
		local target_card = area.cards[target_index]
		if target_card.highlighted then
			area:remove_from_highlighted(target_card, target_card.thefamily_definition.keep)
		end
		target_card:remove()
		area:emplace(card)
		table.insert(area.cards, target_index, card)
		area.cards[#area.cards] = nil
		TheFamily.UI.set_card_position({
			card = card,
			index = target_index,
			force_position = true,
		})
	end

	self:set_card(card)

	return card
end
function TheFamilyTab:set_card(card)
	if not self.card then
		self:remove_card()
		return
	end
	local this = self
	self.card = card
	card.thefamily_definition = self

	local old_remove = card.remove
	function card:remove(...)
		old_remove(self, ...)
		this:remove_card()
	end

	local ui_values = TheFamily.UI.get_ui_values()
	card:hard_set_T(nil, nil, card.T.w * ui_values.scale, card.T.h * ui_values.scale)
	remove_all(card.children)
	card.children = {}
	card:set_sprites(card.config.center, next(card.config.card) and card.config.card or nil)

	function card:align_h_popup()
		return {}
	end
	function card:hover() end
	function card:stop_hover() end
	function card:update_alert() end

	local old_click = card.click
	function card:click()
		if not this:click(self) then
			old_click(self)
		end
	end

	local old_update = card.update
	function card:update(dt, ...)
		old_update(self, dt, ...)

		if self.highlighted and not this:can_highlight(self) then
			TheFamily.UI.area:remove_from_highlighted(self)
		end

		this:update(self, dt)

		this:render_popup()
		this:render_alert()
		this:render_front_label()
	end
end
function TheFamilyTab:remove_card()
	if self.card and not self.card.REMOVED then
		self.card:remove()
	end
	self.card = nil
end

function TheFamilyTab:remove_front_label()
	if self.card and not self.card.REMOVED then
		if self.card.children.front_label then
			self.card.children.front_label:remove()
			self.card.children.front_label = nil
		end
	end
end
function TheFamilyTab:remove_alert()
	if self.card and not self.card.REMOVED then
		if self.card.children.alert then
			self.card.children.alert:remove()
			self.card.children.alert = nil
		end
	end
end
function TheFamilyTab:remove_popup()
	if self.card and not self.card.REMOVED then
		self.card.config.h_popup = nil
		if self.card.children.h_popup then
			self.card.children.h_popup:remove()
			self.card.children.h_popup = nil
		end
	end
end

function TheFamilyTab:render_front_label()
	if not self.card or self.card.REMOVED then
		return
	end
	local front_label_result = self:front_label(self.card)
	if not front_label_result or type(front_label_result) ~= "table" or front_label_result.remove then
		self:remove_front_label()
		return
	end
	if self.card.children.front_label then
		return
	end

	local ui_values = TheFamily.UI.get_ui_values()
	local front_label, config
	front_label = {
		n = G.UIT.ROOT,
		config = { colour = G.C.CLEAR, align = "cm" },
		nodes = {
			{
				n = G.UIT.R,
				config = {
					padding = 0.025,
					colour = adjust_alpha(G.C.BLACK, 0.75),
					r = 0.1,
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = front_label_result.text or "",
							scale = (front_label_result.scale or 0.5) * ui_values.scale,
							colour = front_label_result.colour or G.C.WHITE,
						},
					},
				},
			},
		},
	}
	config = {
		align = "cmi",
		offset = {
			x = 0,
			y = 0,
		},
		parent = self.card,
	}

	local box = UIBox({
		definition = front_label,
		config = config,
	})
	box.states.collide.can = false
	box.states.hover.can = false
	box.states.click.can = false
	box.role.r_bond = "Weak"
	box.T.r = math.rad(ui_values.r_deg + 90)
	self.card.children.front_label = box
end
function TheFamilyTab:render_alert()
	if not self.card or self.card.REMOVED then
		return
	end
	local alert_result = self:alert(self.card)
	if not alert_result or type(alert_result) ~= "table" or alert_result.remove then
		self:remove_alert()
		return
	end
	if self.card.children.alert then
		return
	end

	local ui_values = TheFamily.UI.get_ui_values()
	local alert, config
	if type(alert_result.definition_function) == "function" then
		local definition_result = alert_result.definition_function()
		alert = definition_result.definition
		config = definition_result.config
	end
	alert = alert
		or {
			n = G.UIT.R,
			config = {
				align = "cm",
				r = 0.15 * ui_values.scale,
				minw = 0.42 * ui_values.scale,
				minh = 0.42 * ui_values.scale,
				colour = alert_result.no_bg and G.C.CLEAR
					or alert_result.bg_col
					or (alert_result.red_bad and darken(G.C.RED, 0.1) or G.C.RED),
				draw_layer = 1,
				emboss = 0.05,
				refresh_movement = true,
			},
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = DynaText({
							string = alert_result.text or "!",
							colours = { G.C.WHITE },
							shadow = true,
							rotate = true,
							H_offset = alert_result.y_offset or 0,
							bump_rate = alert_result.bump_rate or 3,
							bump_amount = alert_result.bump_amount or 3,
							bump = true,
							maxw = alert_result.maxw,
							text_rot = alert_result.text_rot or 0.2,
							spacing = 3 * (alert_result.scale or 1) * ui_values.scale,
							scale = (alert_result.scale or 0.48) * ui_values.scale,
						}),
					},
				},
			},
		}
	config = config or {
		offset = {
			x = -0.1 * ui_values.scale,
			y = -0.1 * ui_values.scale,
		},
	}

	local box = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { align = "cm", colour = G.C.CLEAR, refresh_movement = true },
			nodes = { alert },
		},
		config = {
			align = config.align or "tli",
			offset = {
				x = (config.offset or {}).x or (-0.1 * ui_values.scale),
				y = (config.offset or {}).y or (-0.1 * ui_values.scale),
			},
			parent = self.card,
		},
	})
	box.states.collide.can = false
	box.states.hover.can = false
	box.states.click.can = false
	box.role.r_bond = "Weak"
	box.T.r = 0
	box.T.scale = ui_values.scale
	self.card.children.alert = box
end
function TheFamilyTab:render_popup()
	if not self.card or self.card.REMOVED then
		return
	end
	if not (self.card.states.hover.is or (self.card.highlighted and self.keep_popup_when_highlighted)) then
		self.card.thefamily_popup_checked = nil
		self:remove_popup()
		return
	end
	if self.card.thefamily_popup_checked then
		return
	end
	self.card.thefamily_popup_checked = true
	if self.card.children.popup then
		return
	end
	local popup_result = self:popup(self.card)
	if not popup_result or type(popup_result) ~= "table" or popup_result.remove then
		self:remove_popup()
		return
	end

	local popup, popup_config

	if type(popup_result.definition_function) == "function" then
		local definition_result = popup_result.definition_function()
		if definition_result then
			popup = definition_result.definition
			popup_config = definition_result.config
		end
	elseif popup_result.name or popup_result.description then
		local result_content = {
			popup_result.name and name_from_rows(popup_result.name) or nil,
		}
		for _, item in ipairs(popup_result.description or {}) do
			table.insert(
				result_content,
				desc_from_rows({
					item,
				})
			)
		end
		popup = {
			n = G.UIT.ROOT,
			config = { align = "cm", colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.C,
					config = {
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.R,
							config = {
								padding = 0.05,
								r = 0.12,
								colour = lighten(G.C.JOKER_GREY, 0.5),
								emboss = 0.07,
							},
							nodes = {
								{
									n = G.UIT.R,
									config = {
										align = "cm",
										padding = 0.07,
										r = 0.1,
										colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
									},
									nodes = result_content,
								},
							},
						},
					},
				},
			},
		}
	else
		self:remove_popup()
		return
	end

	if popup then
		popup_config = popup_config
			or {
				align = "cl",
				offset = { x = -0.25, y = 0 },
				major = self.card,
				xy_bond = "Strong",
				r_bond = "Weak",
				wh_bond = "Weak",
			}
		popup_config.instance_type = "POPUP"
		self.card.children.popup = UIBox({
			definition = popup,
			config = popup_config,
		})
	end
end

function TheFamilyTab:rerender_front_label()
	self:remove_front_label()
	self:render_front_label()
end
function TheFamilyTab:rerender_alert()
	self:remove_alert()
	self:render_alert()
end
function TheFamilyTab:rerender_popup()
	self.card.thefamily_popup_checked = nil
	self:remove_popup()
	self:render_popup()
end
