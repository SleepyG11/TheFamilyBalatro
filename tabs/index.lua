TheFamily.own_tabs = {}

TheFamily.create_tab_group({
	key = "thefamily_general",
	order = 0,

	original_mod_id = "TheFamily",
	center = "j_family",

	loc_txt = {
		name = "General tabs",
		description = {
			"Collection of some miscellaneous",
			"tabs added by default",
		},
	},

	can_be_disabled = true,
})

require("thefamily/tabs/time_tracker")
require("thefamily/tabs/pools_probabilities")

TheFamily.create_tab_group({
	key = "thefamily_default",
	order = 1e308,

	original_mod_id = "TheFamily",
})
