if SMODS and SMODS.current_mod then
	if TheFamily then
		if not TheFamily.current_mod then
			TheFamily.emplace_steamodded()
		end
	end

	-- SMODS.Atlas({
	-- 	key = "modicon",
	-- 	path = "icon.png",
	-- 	px = 32,
	-- 	py = 32,
	-- })
end
