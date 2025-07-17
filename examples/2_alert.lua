-- Now, when you know how to make tabs, let's try something more complicated

-- How often you forgot about 6th joker slot when you're playing on Black deck?
-- Let's make a tab which will show you how many empty joker slots you have!

-- We need to store temp data somewhere, for optimizing reasons
local joker_slots_data = {
	free_slots = 0,
	no_area = true,
}

TheFamily.create_tab({
	key = "thefamily_example_empty_joker_slots",
	group_key = "thefamily_example_group",

	-- Let's use mentioned deck as our card
	center = "b_black",

	loc_txt = {
		["en-us"] = {
			name = "Joker slots",
			text = {
				"Displays amount of joker",
				"slots available",
			},
		},
		["ru"] = {
			name = "Cлоты под джокеров",
			text = {
				"Показывает количество свободных",
				"слотов под джокеров",
			},
		},
	},

	can_be_disabled = true,

	front_label = function()
		return {
			text = "Joker slots",
		}
	end,

	-- For this example we'll make simple tab which only displays popup, no any other logic
	can_highlight = function()
		return false
	end,

	-- To keep track of amount of free joker slot, we can use update function, to check them every frame
	update = function(self, card, dt)
		if not G.jokers then
			joker_slots_data.no_area = true
			joker_slots_data.free_slots = 0
		else
			joker_slots_data.no_area = false
			joker_slots_data.free_slots = G.jokers.config.card_limit - #G.jokers.cards
		end
	end,

	-- Now - interesting part. How we can notify user about available joker slots?

	-- Option 1: show alert like in collection, red dot on corner with exclamation mark.
	-- Basically, all we are return will be passed as argument to function similar to `create_UIBox_card_alert`. Check in game's code what it does.
	-- Let's show J instead of !, and make this alert black instead of red
	alert = function(self, card)
		-- Return nothing if all slots occupied.
		-- Alert will be automatically removed, it's fully handled by tab.
		if joker_slots_data.no_area or joker_slots_data.free_slots <= 0 then
			return
		end

		return {
			text = "J",
			bg_col = HEX("000000"),
		}
	end,

	-- Option 2: show custom alert where we can put some more text
	alert = function(self, card)
		-- Same check
		if joker_slots_data.no_area or joker_slots_data.free_slots <= 0 then
			return
		end

		return {
			-- Declare definition function
			definition_function = function()
				-- Now we need pass a content which we want to render inside
				-- Since menu can be positioned or scaled differently, and because of UI works as it works,
				-- we need position and scale all manually. Not fun! To do this, get values like scale and angle.
				local ui_values = TheFamily.UI.get_ui_values()

				local content = {
					-- Create a text node which will show how much slots we have left.
					-- Instea of rerendering alert each time, use `ref_table` and `ref_value` to assign updating work to the UI (vanilla thing btw)
					{
						n = G.UIT.T,
						config = {
							-- Use our temp object to retrieve amount of free slots
							ref_table = joker_slots_data,
							ref_value = "free_slots",
							colour = G.C.WHITE,

							-- Use scale to adjust text size
							scale = 0.4 * ui_values.scale,
						},
					},
					{
						n = G.UIT.T,
						config = {
							text = " free joker slot" .. (joker_slots_data.free_slots == 1 and "" or "s"),
							colour = G.C.WHITE,
							scale = 0.4 * ui_values.scale,
						},
					},
				}

				if true then
					-- For this we can use UI utility function, which create stylish alert
					-- This functions created an alert with semi-transparent black background and position it on card's corner
					return TheFamily.UI.PARTS.create_dark_alert(card, content)
				else
					-- Or, you can render it yourself. Here's how this functions looks like.
					-- A lot of math and position checks, yea...
					-- But, it's a full freedom for you!
					-- Show your UI skills and draw everything you want, or at least everything you can...
					local config
					if ui_values.position_on_screen == "right" then
						config = {
							align = "tri",
							offset = {
								x = card.T.w * math.sin(ui_values.r_rad) + 0.22 * ui_values.scale,
								y = -0.1 * ui_values.scale,
							},
						}
					elseif ui_values.position_on_screen == "left" then
						config = {
							align = "tli",
							offset = {
								x = -1 * (card.T.w * math.sin(ui_values.r_rad) + 0.22 * ui_values.scale),
								y = -0.1 * ui_values.scale,
							},
						}
					else
						config = {
							align = "tri",
							offset = {
								x = card.T.w * math.sin(ui_values.r_rad) + 0.21 * ui_values.scale,
								y = 0.15 * ui_values.scale,
							},
						}
					end

					-- Returned value will be passed to UIBox
					return {
						definition = {
							n = G.UIT.ROOT,
							config = { align = "cm", colour = G.C.CLEAR },
							nodes = {
								{
									n = G.UIT.R,
									config = {
										align = "cm",
										padding = 0.1 * ui_values.scale,
										r = 0.02 * ui_values.scale,
										colour = HEX("22222288"),
									},
									nodes = content,
								},
							},
						},
						config = config,
					}
				end
			end,
		}
	end,
})
