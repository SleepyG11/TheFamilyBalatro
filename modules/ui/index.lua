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

	localize_text = function(text, args)
		if type(text) == "string" then
			text = { text }
		elseif type(text) ~= "table" then
			return {}
		end

		args = args or {}
		args.default_col = args.default_col or G.C.UI.TEXT_DARK
		args.vars = args.vars or {}

		local collected_lines = {}
		for _, line in ipairs(text) do
			local localized = TheFamily.UI.localize_box(loc_parse_string(line), args)
			table.insert(collected_lines, {
				n = G.UIT.R,
				config = { align = args.align },
				nodes = localized,
			})
		end
		return collected_lines
	end,
	localize_box = (SMODS and SMODS.localize_box) or function(lines, args)
		local function format_ui_value(value)
			if type(value) ~= "number" then
				return tostring(value)
			end
			return number_format(value, 1000000)
		end
		local final_line = {}
		for _, part in ipairs(lines) do
			local assembled_string = ""
			for _, subpart in ipairs(part.strings) do
				assembled_string = assembled_string
					.. (
						type(subpart) == "string" and subpart
						or format_ui_value(args.vars[tonumber(subpart[1])])
						or "ERROR"
					)
			end
			local desc_scale = (G.FONTS[tonumber(part.control.f)] or G.LANG.font).DESCSCALE
			if G.F_MOBILE_UI then
				desc_scale = desc_scale * 1.5
			end
			if part.control.E then
				local _float, _silent, _pop_in, _bump, _spacing = nil, true, nil, nil, nil
				if part.control.E == "1" then
					_float = true
					_silent = true
					_pop_in = 0
				elseif part.control.E == "2" then
					_bump = true
					_spacing = 1
				end
				final_line[#final_line + 1] = {
					n = G.UIT.C,
					config = {
						align = "m",
						colour = part.control.X and loc_colour(part.control.X) or nil,
						r = 0.05,
						padding = 0.03,
						res = 0.15,
					},
					nodes = {},
				}
				final_line[#final_line].nodes[1] = {
					n = G.UIT.O,
					config = {
						object = DynaText({
							string = { assembled_string },
							colours = {
								part.control.V and args.vars.colours[tonumber(part.control.V)]
									or loc_colour(part.control.C or nil),
							},
							float = _float,
							silent = _silent,
							pop_in = _pop_in,
							bump = _bump,
							spacing = _spacing,
							font = (tonumber(part.control.f) and G.FONTS[tonumber(part.control.f)]),
							scale = 0.32
								* (part.control.s and tonumber(part.control.s) or args.scale or 1)
								* desc_scale,
						}),
					},
				}
			elseif part.control.X then
				final_line[#final_line + 1] = {
					n = G.UIT.C,
					config = {
						align = "m",
						colour = loc_colour(part.control.X),
						r = 0.05,
						padding = 0.03,
						res = 0.15,
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = assembled_string,
								colour = part.control.V and args.vars.colours[tonumber(part.control.V)]
									or loc_colour(part.control.C or nil),
								font = (tonumber(part.control.f) and G.FONTS[tonumber(part.control.f)]),
								scale = 0.32
									* (part.control.s and tonumber(part.control.s) or args.scale or 1)
									* desc_scale,
							},
						},
					},
				}
			else
				final_line[#final_line + 1] = {
					n = G.UIT.T,
					config = {
						detailed_tooltip = part.control.T and (G.P_CENTERS[part.control.T] or G.P_TAGS[part.control.T])
							or nil,
						text = assembled_string,
						shadow = args.shadow,
						colour = part.control.V and args.vars.colours[tonumber(part.control.V)]
							or not part.control.C and args.text_colour
							or loc_colour(part.control.C or nil, args.default_col),
						font = (tonumber(part.control.f) and G.FONTS[tonumber(part.control.f)]),
						scale = 0.32 * (part.control.s and tonumber(part.control.s) or args.scale or 1) * desc_scale,
					},
				}
			end
		end
		return final_line
	end,
	localize_loc_text = function(parsed, args)
		args = args or {}
		args.default_col = args.default_col or G.C.UI.TEXT_DARK
		args.vars = args.vars or {}

		local collected_lines = {}
		for _, line in ipairs(parsed) do
			local localized = TheFamily.UI.localize_box(line, args)
			table.insert(collected_lines, {
				n = G.UIT.R,
				config = { align = args.align },
				nodes = localized,
			})
		end
		return collected_lines
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
