-- Basic example how to create group and tab

-- You can store group if you need it
local group = TheFamily.create_tab_group({
	-- Unique key. Include prefix to prevent intersections with other mods.
	key = "thefamily_example_group",

	-- Order used for sorting, from lowest to highest.Optional.
	-- By default group added to the end.
	order = 0,

	-- Function which determines is this group enabled. Called once when run is loaded. By default all groups and tabs enabled.
	-- Let's disable this tab when we are in Multiplayer lobby.
	enabled = function()
		return not (MP and MP.LOBBY and MP.LOBBY.code)
	end,
})

-- Same, you can store tab to call it's methods later, which can be really useful in further examples
local tab = TheFamily.create_tab({
	-- Same as for groups, unique key. Include prefix to prevent intersections with other mods.
	key = "thefamily_example_basic_tab",

	-- Set group's key. Without group tab will not be shown.
	group_key = "thefamily_example_group",

	-- Tabs represented as cards. Let's pick Shortcut joker
	center = "j_shortcut",

	-- Let's add a label on a card, so it will be easier to determine what this tab do.
	front_label = function(self, card)
		return {
			-- Returned value here is config for text node (G.UIT.T), so we can use all we want.
			text = "Main menu",

			-- Further values are optional, text is enough to render white text with correct scaling.
			-- But if you like, you can customize it further.
			-- Luckily for you, all scaling, rotating and aikoyori's shenanigans handled here!
			-- In other hand, for alerts, you need to do it manually. But about that in next example.
			scale = 0.4,
			colour = G.C.MULT,
			shadow = true,
		}
	end,

	-- Let's make a tab, which saves a game and moves to main menu when is clicked.

	-- We need to make this tab non-selectable, since we executing action immediately after press.
	can_highlight = function(self, card)
		return false
	end,

	-- Now, actual logic. Go to main menu when tab's card is pressed.
	-- If this callback returns true, all further events, like checks for highlight, will not be called.
	-- Useful when you want to just do something without executing more tab's logic. Which is exactly what we need here.
	click = function(self, card)
		-- Just for fun, let's add some randomness!
		if math.random() > 0.5 then
			-- In this case, card is a card which represents tab. So, this will juice up card we just pressed
			card:juice_up()
		else
			-- Enough fun, go to menu
			G.FUNCS.go_to_menu()
		end
		return true
	end,
})

-- Congratulations! You make your first fully working and good looking tab. Pretty easy, isn't it?
