local default_config = {
	pagination_type = 1,
	position_on_screen = 1,
	scaling = 1,

	time_tracker = {
		format = 1,
		show_time_alert = true,
	},

	disabled_groups = {},
	groups_order = {},

	disabled_tabs = {},
	tabs_order = {},
}

TheFamily.config = {
	default = TheFamily.utils.table_merge({}, default_config),
	current = {},

	get_module = function(module)
		return module
	end,
	save = function()
		if SMODS and SMODS.save_mod_config and TheFamily.current_mod then
			TheFamily.current_mod.config = TheFamily.config.current
			SMODS.save_mod_config(TheFamily.current_mod)
		else
			love.filesystem.createDirectory("config")
			local serialized = "return " .. TheFamily.utils.serialize(TheFamily.config.current)
			love.filesystem.write("config/TheFamily.jkr", serialized)
		end
		if TheFamily.controller then
			TheFamily.controller.on_settings_save()
		end
	end,
	load = function()
		TheFamily.config.current = TheFamily.utils.table_merge({}, TheFamily.config.default)
		local lovely_mod_config = get_compressed("config/TheFamily.jkr")
		if lovely_mod_config then
			local unpacked = STR_UNPACK(lovely_mod_config)
			TheFamily.config.current = TheFamily.utils.table_merge(TheFamily.config.current, unpacked)
			TheFamily.config.current.groups_order = unpacked.groups_order or {}
			TheFamily.config.current.tabs_order = unpacked.tabs_order or {}
		end
		TheFamily.cc = TheFamily.config.current
	end,
}
TheFamily.config.load()
TheFamily.cc = TheFamily.config.current
