function G.FUNCS.thefamily_empty() end

function G.FUNCS.thefamily_open_options(e)
	-- Because there's so much problems when area is created on pause,
	-- let's just don't pause a game! Crazy, isn't it?
	G.SETTINGS.paused = false
	TheFamily.UI.reset_config_variables()
	TheFamily.UI.config_opened = true
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.thefamily_options(),
	})
	-- TheFamily.utils.cleanup_dead_elements(G, "MOVEABLES")
end
function G.FUNCS.thefamily_exit_options(e)
	G.FUNCS.exit_overlay_menu()
	-- TheFamily.utils.cleanup_dead_elements(G, "MOVEABLES")
end
local exit_overlay_ref = G.FUNCS.exit_overlay_menu
function G.FUNCS.exit_overlay_menu(...)
	TheFamily.UI.reset_config_variables()
	local result = exit_overlay_ref(...)
	-- TheFamily.utils.cleanup_dead_elements(G, "MOVEABLES")
	return result
end

function G.FUNCS.thefamily_change_pagination_type(arg)
	TheFamily.cc.pagination_type = arg.to_key
	TheFamily.config.save()
	TheFamily.rerender_area()
end
function G.FUNCS.thefamily_change_screen_position(arg)
	TheFamily.cc.position_on_screen = arg.to_key
	TheFamily.config.save()
	TheFamily.rerender_area()
end
function G.FUNCS.thefamily_change_scaling(arg)
	TheFamily.cc.scaling = arg.to_key
	TheFamily.config.save()
	TheFamily.rerender_area()
end
