local colours = {}
local localization_colours = {}

TheFamily.UI = {
	C = colours,
	LOC_COLOURS = localization_colours,

	r = -70,
	gap = 0.53,
	scale = 0.4,

	pagination_types = {
		"scroll",
		"page",
	},
	positions_on_screen = {
		"right",
		"left",
		-- "top",
		-- "bottom",
	},
	scalings = {
		1,
		1.1,
		1.2,
	},

	get_ui_values = function()
		return {
			r_deg = TheFamily.UI.r,
			r_rad = math.rad(TheFamily.UI.r),
			gap = TheFamily.UI.gap * (TheFamily.UI.scalings[TheFamily.cc.scaling] or 1),
			scale = TheFamily.UI.scale * (TheFamily.UI.scalings[TheFamily.cc.scaling] or 1),
			pagination_type = TheFamily.UI.pagination_types[TheFamily.cc.pagination_type] or "page",
			position_on_screen = TheFamily.UI.positions_on_screen[TheFamily.cc.position_on_screen] or "right",
			tabs_per_page = math.floor(TheFamily.UI.tabs_per_page / (TheFamily.UI.scalings[TheFamily.cc.scaling] or 1)),
		}
	end,

	page = 1,
	items_per_page = 20,
	utility_cards_per_page = 5,
	tabs_per_page = 15,

	area = nil,
	area_container = nil,
}

local loc_colour_ref = loc_colour
function loc_colour(_c, _default, ...)
	return TheFamily.UI.LOC_COLOURS[_c] or loc_colour_ref(_c, _default, ...)
end

require("thefamily/ui/parts")
require("thefamily/ui/functions")
require("thefamily/ui/config_tabs")
require("thefamily/ui/config")
