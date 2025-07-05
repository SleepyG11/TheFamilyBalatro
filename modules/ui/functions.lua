function G.FUNCS.thefamily_empty() end

function G.FUNCS.thefamily_open_options(e)
	G.SETTINGS.paused = true
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
	if TheFamily.UI.request_area_rerender then
		TheFamily.UI.request_area_rerender = nil
		TheFamilyCardArea():init_cards()
	end
	-- TheFamily.utils.cleanup_dead_elements(G, "MOVEABLES")
	return result
end

function G.FUNCS.thefamily_change_pagination_type(arg)
	TheFamily.cc.pagination_type = arg.to_key
	TheFamily.config.save()
	TheFamily.UI.request_area_rerender = true
end
