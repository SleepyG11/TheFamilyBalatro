local colours = {}
local localization_colours = {}

TheFamily.UI = {
	C = colours,
	LOC_COLOURS = localization_colours,

	r = -70,
	gap = 0.53,
	scale = 0.4,

	pagination_types = {
		"page",
		"scroll",
	},

	get_ui_values = function()
		return {
			r_deg = TheFamily.UI.r,
			r_rad = math.rad(TheFamily.UI.r),
			gap = TheFamily.UI.gap,
			scale = TheFamily.UI.scale,
			pagination_type = TheFamily.UI.pagination_types[TheFamily.cc.pagination_type] or "page",
		}
	end,

	page = 1,
	items_per_page = 20,
	utility_cards_per_page = 5,
	tabs_per_page = 15,

	area = nil,
	area_container = nil,

	create_UI_dark_alert = function(card, content)
		local info = TheFamily.UI.get_ui_values()
		return {
			definition = {
				n = G.UIT.R,
				config = {
					align = "cm",
					padding = 0.1 * info.scale,
					r = 0.02 * info.scale,
					colour = HEX("22222288"),
				},
				nodes = content,
			},
			config = {
				align = "tri",
				offset = {
					x = card.T.w * math.sin(info.r_rad) + 0.21 * info.scale,
					y = 0.15 * info.scale,
				},
			},
		}
	end,
}

local loc_colour_ref = loc_colour
function loc_colour(_c, _default, ...)
	return TheFamily.UI.LOC_COLOURS[_c] or loc_colour_ref(_c, _default, ...)
end

require("thefamily/ui/parts")
require("thefamily/ui/functions")
require("thefamily/ui/config_tabs")
require("thefamily/ui/config")
