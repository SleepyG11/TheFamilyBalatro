TheFamily.own_tabs = {}

TheFamily.create_tab_group({
	key = "thefamily_general",
	order = 0,
})

require("thefamily/tabs/time_tracker")
require("thefamily/tabs/pools_probabilities")

TheFamily.create_tab_group({
	key = "thefamily_default",
	order = 1e308,
})
