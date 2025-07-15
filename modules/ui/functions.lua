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
function G.FUNCS.thefamily_can_user_toggle_group(e)
	local card = e.config.ref_table
	local group = card.thefamily_group
	if group.can_be_disabled then
		e.config.button = "thefamily_user_toggle_group"
		if group:_disabled_by_user() then
			e.config.colour = G.C.GREEN
		else
			e.config.colour = G.C.MULT
		end
	else
		e.config.button = nil
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
	end
end
function G.FUNCS.thefamily_user_toggle_group(e)
	local card = e.config.ref_table
	card.thefamily_group:_toggle_by_user()
	card.debuff = card.thefamily_group:_disabled_by_user()
	TheFamily.config.save()
	TheFamily.rerender_area()
end
