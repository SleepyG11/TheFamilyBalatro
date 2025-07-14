-- Now, real situation: your mod created new card area, which places somewhere on a screen and player should have access for it.
-- Let's handle it properly

local start_run_ref = Game.start_run
function Game:start_run(...)
	start_run_ref(self, ...)

	-- Our card area we will messing with
	self.example_joker_area =
		CardArea(0, 0, CAI.joker_W, CAI.joker_H, { card_limit = 420, type = "joker", highlight_limit = 1 })

	-- Hide by default
	self.example_joker_area.states.visible = false
end

local temp_data = {
	tab = nil,
}

-- Let's make functions to open and close our card area
function G.FUNCS.example_open_funny_jokers(e)
	if not G.example_joker_area then
		return
	end
	if G.jokers then
		G.jokers.states.visible = false
	end
	G.example_joker_area.states.visible = true

	-- We'll store tab in out temp object for quick access
	-- When this function is called (for example, from other button or keybind, we should sync tab with it)
	-- In this case - open it
	-- We're passing `true` because at this moment basically all work is done and we want open tab without any effects, only visually.
	if temp_data.tab then
		temp_data.tab:open(true)
	end
end
function G.FUNCS.example_close_funny_jokers(e)
	if not G.example_joker_area then
		return
	end
	if G.jokers then
		G.jokers.states.visible = true
	end
	G.example_joker_area.states.visible = false

	-- Same logic but close
	if temp_data.tab then
		temp_data.tab:close(true)
	end
end

temp_data.tab = TheFamily.create_tab({
	key = "thefamily_example_cardarea_tab",
	group_key = "thefamily_example_group",

	-- All previous tabs was not openable, but this one is.
	-- There's 2 major types of tabs: overlay and switch.
	-- At the same time only 1 overlay can be opened.
	-- Switched, in other hand, independent. Let's use it.
	-- Default value is "overlay" btw.
	type = "switch",

	-- Multiple tabs can try to hide/show vanilla things like joker slots.
	-- To prevent cases where multiple things displayed on this spot, we should close all related tabs and open our one.
	-- To do this, we can which signals that we're affecting joker slots. This can be any key, but for our case we'll use pre-defined one.
	switch_overlays = { TheFamily.SWITCH_OVERLAYS.JOKERS },

	-- This time, let's do something different. Let's create own card with edition.
	-- What about negative Uranus?
	center = function(self, area)
		if SMODS then
			-- You're lucky
			-- DO NOT USE `SMODS.add_card`, game will think that this card is part of a game, not just UI
			local card = SMODS.create_card({
				key = "c_uranus",
				area = area,
				skip_materialize = true,
				no_edition = true,

				-- Don't forget pass this 2 params, to prevent unintented behavious or displaying undiscovered card instead of expected.
				bypass_discovery_center = true,
				discover = false,
			})
			-- Set edition separately, since you can't pass `silent` argument during creation
			card:set_edition("e_negative", true, true)
			return card
		else
			-- Better don't use it, of course. But when you mod doesn't require SMODS, you need to do it manually
			local card = Card(area.T.x + area.T.w / 2, area.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS.c_uranus, {
				-- Same here
				bypass_discovery_center = true,
				bypass_discovery_ui = true,
				discover = false,
			})
			card:set_edition({ negative = true }, true)
			return card
		end
	end,

	front_label = function(self, card)
		return {
			text = "Funny area",
		}
	end,

	-- Now, let's add a popup which will be displayed when we hover a tab
	-- It makes tab more interactive
	popup = function(self, card)
		-- We'll make simple one: name and short description with formatting
		return {
			-- Name elements
			name = {
				{
					n = G.UIT.R,
					config = {
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = "Toggle Funny Jokers area",
								colour = G.C.EDITION,
								scale = 0.4,
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = {
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = "Ha-ha, funny jokers!",
								colour = G.C.UI.TEXT_INACTIVE,
								scale = 0.25,
							},
						},
					},
				},
			},
			-- Like in SMODS, multiple boxes for descriptions is supported
			description = {
				-- First box
				{
					{
						n = G.UIT.R,
						config = { align = "cm" },
						-- It's a function which accepts text with formatting and and some params and allows to render this text properly.
						nodes = TheFamily.UI.localize_text({
							"Open {C:dark_edition}Funny jokers{} area",
							"{C:inactive}Only in Shop{}",
						}, {
							align = "cm",
						}),
					},
				},
				-- Second box
				{
					{
						n = G.UIT.R,
						config = { align = "cm" },
						-- More multiline text
						nodes = TheFamily.UI.localize_text({
							"{C:inactive,s:0.75}Hey, it's still funny!{}",
							"{C:mult,s:0.5}Please more fun!{}",
						}, {
							align = "cm",
						}),
					},
					-- You can put here not only text, but any UI elements: checkboxes, toggles, card areas, anything.
					{
						n = G.UIT.R,
						config = {
							padding = 0.05,
							r = 0.1,
							colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8),
							align = "cm",
						},
						nodes = {
							create_toggle({
								label = "No fun allowed",
								ref_table = { value = false },
								ref_value = "value",
								scale = 0.5,
								label_scale = 0.3,
								callback = function(new_value)
									if new_value then
										print("Fun is not allowed anymore")
									end
								end,
							}),
						},
					},
				},
			},
		}
	end,

	-- Let's also add an alert which will display how much cards in area and card limit
	alert = function(self, card)
		-- Don't show it outside of shop, and check for area to prevent possible crashes
		if G.STATE ~= G.STATES.SHOP or not G.example_joker_area then
			return
		end
		return {
			definition_function = function()
				local ui_values = TheFamily.UI.get_ui_values()
				return TheFamily.UI.PARTS.create_dark_alert(card, {
					{
						n = G.UIT.T,
						config = {
							ref_table = G.example_joker_area.config,
							ref_value = "card_count",
							colour = G.C.WHITE,
							scale = 0.4 * ui_values.scale,
						},
					},
					{
						n = G.UIT.T,
						config = {
							text = "/",
							colour = G.C.WHITE,
							scale = 0.4 * ui_values.scale,
						},
					},
					{
						n = G.UIT.T,
						config = {
							ref_table = G.example_joker_area.config,
							ref_value = "card_limit",
							colour = G.C.WHITE,
							scale = 0.4 * ui_values.scale,
						},
					},
				})
			end,
		}
	end,

	-- Now, this thing comes into play. Let's make this tab openable only on shop.
	-- When player leaves the shop or opens booster pack, tab will automatically close.
	can_highlight = function(self, card)
		return G.STATE == G.STATES.SHOP
	end,

	-- Now, opening and closing logic
	highlight = function(self, card)
		G.FUNCS.example_open_funny_jokers()
	end,
	unhighlight = function(self, card)
		G.FUNCS.example_close_funny_jokers()
	end,
})

-- And that's about it! Pretty easy, isn't it?
