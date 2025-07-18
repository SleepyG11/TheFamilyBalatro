local TimeTracker = setmetatable({
	alert_label = "",
	real_time_label = os.date("%I:%M:%S %p", os.time()),

	time_formats = {
		"%I:%M:%S %p",
		"%H:%M:%S",
		"%I:%M %p",
		"%H:%M",
	},

	current_hand_start = 0,
	current_hand_time = 0,
	current_hand_label = "Not played yet",

	last_hand = 0,
	last_hand_label = "Not played yet",

	session_label = "00:00",

	this_run_start = 0,
	this_run_label = "00:00",

	acceleration_label = "1x",

	format_time = function(self, time, with_ms, always_h)
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

	load = function(self)
		self.last_hand = 0
		self.last_hand_label = self:format_time(self.last_hand, true)
		self.current_hand_time = 0
		self.current_hand_start = 0
		self.current_hand_label = "Not played yet"
	end,

	update = function(self, dt)
		self.real_time_label = os.date(self.time_formats[TheFamily.cc.time_tracker.format], os.time())
		self.session_label = self:format_time(G.TIMERS.UPTIME or 0, false, true)
		self.acceleration_label = string.format("x%.2f", G.SPEEDFACTOR or 0)
		self.this_run_label = self:format_time((G.TIMERS.UPTIME or 0) - self.this_run_start, true, true)
		if G.STATE == G.STATES.HAND_PLAYED then
			if self.current_hand_start == 0 then
				self.current_hand_start = love.timer.getTime()
			end
			self.current_hand_time = love.timer.getTime()
			self.current_hand_label = self:format_time(self.current_hand_time - self.current_hand_start, true)
			self.alert_label = string.format("%s (%s)", self.current_hand_label, self.acceleration_label)
		else
			if self.current_hand_time > 0 then
				self.last_hand = self.current_hand_time - self.current_hand_start
				self.last_hand_label = self:format_time(self.last_hand, true)
				self.current_hand_time = 0
				self.current_hand_start = 0
				self.current_hand_label = "Not played yet"
			end
			self.alert_label = self.real_time_label
		end
	end,

	create_UI_popup = function(self, card)
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
			name = {
				{
					n = G.UIT.T,
					config = {
						text = "Time info",
						scale = 0.35,
						colour = G.C.WHITE,
					},
				},
			},
			description = {
				{
					create_time_row({
						text = "Real time",
						ref_table = self,
						ref_value = "real_time_label",
					}),
					create_time_row({
						text = "This session",
						ref_table = self,
						ref_value = "session_label",
					}),
					create_time_row({
						text = "This run",
						ref_table = self,
						ref_value = "this_run_label",
					}),
					create_time_row({
						text = "Game speed",
						ref_table = self,
						ref_value = "acceleration_label",
					}),
				},
				{
					create_time_row({
						text = "Last hand",
						ref_table = self,
						ref_value = "last_hand_label",
					}),
					create_time_row({
						text = "Current hand",
						ref_table = self,
						ref_value = "current_hand_label",
					}),
					not card.highlighted and {
						n = G.UIT.R,
						config = { align = "cm", padding = 0.1 },
						nodes = TheFamily.UI.localize_text({
							"{C:inactive}Select to configure{}",
						}, {
							align = "cm",
							scale = 0.8,
						}),
					} or nil,
				},
				card.highlighted and {
					create_option_cycle({
						options = { "Long 12h", "Long 24h", "Short 12h", "Short 24h" },
						opt_callback = "thefamily_update_time_tracker_time_format",
						current_option = TheFamily.cc.time_tracker.format,
						colour = G.C.RED,
						scale = 0.6,
						w = 4,
					}),
					{
						n = G.UIT.R,
						config = {
							padding = 0.05,
							r = 0.1,
							colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
						},
						nodes = {
							create_toggle({
								label = "Display time alert",
								ref_table = TheFamily.cc.time_tracker,
								ref_value = "show_time_alert",
								scale = 0.5,
								label_scale = 0.3,
								callback = function(b)
									G.FUNCS.thefamily_update_time_tracker_show_alert(b)
								end,
							}),
						},
					},
				} or nil,
			},
		}
	end,
	create_UI_alert = function(self, card)
		if G.STATE ~= G.STATES.HAND_PLAYED and not TheFamily.cc.time_tracker.show_time_alert then
			return nil
		end
		return {
			definition_function = function()
				local info = TheFamily.UI.get_ui_values()
				return TheFamily.UI.PARTS.create_dark_alert(card, {
					{
						n = G.UIT.T,
						config = {
							ref_table = self,
							ref_value = "alert_label",
							colour = G.C.WHITE,
							scale = 0.45 * info.scale,
						},
					},
				})
			end,
		}
	end,
}, {})

TimeTracker.tab = TheFamily.create_tab({
	key = "thefamily_time",
	order = 0,
	group_key = "thefamily_general",
	center = "v_hieroglyph",
	type = "switch",

	original_mod_id = "TheFamily",
	loc_txt = {
		name = "Time",
		text = {
			"Real time display and info about",
			"current session/hand time duration",
		},
	},

	front_label = function()
		return {
			text = "Time",
		}
	end,
	update = function(defitinion, card, dt)
		TimeTracker:update(dt)
	end,
	alert = function(definition, card)
		return TimeTracker:create_UI_alert(card)
	end,
	popup = function(definition, card)
		return TimeTracker:create_UI_popup(card)
	end,

	keep_popup_when_highlighted = true,
})

TheFamily.own_tabs.time_tracker = TimeTracker

function G.FUNCS.thefamily_update_time_tracker_time_format(arg)
	TheFamily.config.current.time_tracker.format = arg.to_key
	TheFamily.config.save()
end
function G.FUNCS.thefamily_update_time_tracker_show_alert(b)
	TheFamily.config.current.time_tracker.show_time_alert = b
	TheFamily.config.save()
end
