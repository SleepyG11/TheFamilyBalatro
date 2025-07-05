function TheFamily.UI.reset_config_variables()
	TheFamily.UI.config_opened = nil
	TheFamily.UI.config_tab_index = 1
end
TheFamily.UI.reset_config_variables()

function G.UIDEF.thefamily_options(from_smods)
	local tabs = TheFamily.UI.get_options_tabs()
	tabs[TheFamily.UI.config_tab_index or 1].chosen = true
	local t = create_UIBox_generic_options({
		back_func = from_smods and "mods_button" or "exit_overlay_menu",
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0 },
				nodes = {
					create_tabs({
						tabs = tabs,
						snap_to_nav = true,
						no_shoulders = true,
						colour = G.C.BOOSTER,
					}),
				},
			},
		},
	})
	return t
end

if SMODS then
	local create_UIBox_mods_ref = create_UIBox_mods
	function create_UIBox_mods(...)
		if G.ACTIVE_MOD_UI and G.ACTIVE_MOD_UI == TheFamily.current_mod then
			TheFamily.UI.reset_config_variables()
			TheFamily.UI.config_opened = true
			return G.UIDEF.thefamily_options(true)
		end
		return create_UIBox_mods_ref(...)
	end

	local mods_button_ref = G.FUNCS.mods_button
	function G.FUNCS.mods_button(...)
		TheFamily.UI.reset_config_variables()
		return mods_button_ref(...)
	end
end
