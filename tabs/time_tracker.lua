TheFamily.own_tabs.time_tracker = {
	alert_label = os.date("%I:%M:%S %p", os.time()),
	real_time_label = os.date("%I:%M:%S %p", os.time()),

	current_hand_start = 0,
	current_hand_time = 0,
	current_hand_label = "Not played yet",

	last_hand = 0,
	last_hand_label = "Not played yet",

	session_label = "00:00",

	this_run_start = 0,
	this_run_label = "00:00",

	acceleration_label = "1x",

	format_time = function(time, with_ms, always_h)
		local result = os.date("%M:%S", time)
		if with_ms then
			local ms = math.floor((time - math.floor(time)) * 1000 + 0.5)
			result = result .. "." .. string.format("%03d", ms)
		end

		local h = math.floor(time / 3600)
		if h > 0 or always_h then
			result = string.format(always_h and "%02d" or "%01d", h) .. ":" .. result
		end
		return result
	end,

	load = function()
		local self = TheFamily.own_tabs.time_tracker
		self.last_hand = 0
		self.last_hand_label = self.format_time(self.last_hand, true)
		self.current_hand_time = 0
		self.current_hand_start = 0
		self.current_hand_label = "Not played yet"
	end,

	update = function(dt)
		local self = TheFamily.own_tabs.time_tracker
		self.real_time_label = os.date("%I:%M:%S %p", os.time())
		self.session_label = self.format_time(G.TIMERS.UPTIME or 0, false, true)
		self.acceleration_label = string.format("x%.2f", G.SPEEDFACTOR or 0)
		self.this_run_label = self.format_time((G.TIMERS.UPTIME or 0) - self.this_run_start, true, true)
		if G.STATE == G.STATES.HAND_PLAYED then
			if self.current_hand_start == 0 then
				self.current_hand_start = love.timer.getTime()
			end
			self.current_hand_time = love.timer.getTime()
			self.current_hand_label = self.format_time(self.current_hand_time - self.current_hand_start, true)
			self.alert_label = string.format("%s (%s)", self.current_hand_label, self.acceleration_label)
		else
			if self.current_hand_time > 0 then
				self.last_hand = self.current_hand_time - self.current_hand_start
				self.last_hand_label = self.format_time(self.last_hand, true)
				self.current_hand_time = 0
				self.current_hand_start = 0
				self.current_hand_label = "Not played yet"
			end
			self.alert_label = os.date("%I:%M:%S %p", os.time())
		end
	end,

	create_UI_popup = function(card)
		local function create_time_row(row)
			return {
				n = G.UIT.R,
				config = {
					padding = 0.025,
				},
				nodes = {
					{
						n = G.UIT.C,
						config = {
							minw = 2.5,
							maxw = 2.5,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = row.text,
									colour = G.C.UI.TEXT_DARK,
									scale = 0.3,
								},
							},
						},
					},
					{
						n = G.UIT.C,
						config = {
							minw = 0.25,
							maxw = 0.25,
						},
					},
					{
						n = G.UIT.C,
						config = {
							minw = 2,
							maxw = 2,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									ref_table = row.ref_table,
									ref_value = row.ref_value,
									colour = G.C.CHIPS,
									maxw = 3,
									scale = 0.3,
								},
							},
						},
					},
				},
			}
		end
		return {
			name = {},
			description = {
				{
					create_time_row({
						text = "Real time",
						ref_table = TheFamily.own_tabs.time_tracker,
						ref_value = "real_time_label",
					}),
					create_time_row({
						text = "This session",
						ref_table = TheFamily.own_tabs.time_tracker,
						ref_value = "session_label",
					}),
					create_time_row({
						text = "This run",
						ref_table = TheFamily.own_tabs.time_tracker,
						ref_value = "this_run_label",
					}),
					create_time_row({
						text = "Game speed",
						ref_table = TheFamily.own_tabs.time_tracker,
						ref_value = "acceleration_label",
					}),
				},
				{
					create_time_row({
						text = "Last hand",
						ref_table = TheFamily.own_tabs.time_tracker,
						ref_value = "last_hand_label",
					}),
					create_time_row({
						text = "Current hand",
						ref_table = TheFamily.own_tabs.time_tracker,
						ref_value = "current_hand_label",
					}),
				},
			},
		}
	end,
	create_UI_alert = function(card)
		return {
			definition_function = function()
				local info = TheFamily.UI.get_ui_values()
				return TheFamily.UI.PARTS.create_dark_alert(card, {
					{
						n = G.UIT.T,
						config = {
							ref_table = TheFamily.own_tabs.time_tracker,
							ref_value = "alert_label",
							colour = G.C.WHITE,
							scale = 0.45 * info.scale,
						},
					},
				})
			end,
		}
	end,
}

TheFamily.create_tab({
	key = "thefamily_time",
	order = 0,
	group_key = "thefamily_default",
	center = "v_hieroglyph",
	type = "switch",

	front_label = function()
		return {
			text = "Time",
		}
	end,
	update = function(defitinion, card, dt)
		TheFamily.own_tabs.time_tracker.update(dt)
	end,
	alert = function(definition, card)
		return TheFamily.own_tabs.time_tracker.create_UI_alert(card)
	end,
	popup = function(definition, card)
		return TheFamily.own_tabs.time_tracker.create_UI_popup(card)
	end,

	keep_popup_when_highlighted = true,
})
