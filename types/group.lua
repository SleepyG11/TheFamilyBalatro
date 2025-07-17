--- @meta

--- Card which will represent a group in config.<br>
--- <br>
--- If string passed, card with center from `G.P_CENTERS` will be created.<br>
--- If function passed, returned card will be used instead. **DO NOT EMPLACE IT**<br>
--- If not passed, card center from first tab in group will be used instead.
--- @alias TheFamilyGroupCenterDefinition string | fun(self: TheFamilyTab, area: CardArea): Card

--- @class TheFamilyGroupOptions: table
--- @field key string Unique key. To prevent intersections, add prefix
--- @field order? number Value user for sorting, from lowest to highest
--- @field front? string Key from `G.P_CARDS` to set card's front
--- @field center? TheFamilyGroupCenterDefinition
--- @field enabled? fun(self: TheFamilyGroup): boolean Function which determines can tabs inside this group be created.
--- @field loc_txt? table SMODS-like localization definition with `name` and `text` fields. See https://github.com/Steamodded/smods/wiki/Localization#loc_txt
--- @field original_mod_id? string Mod id this group belongs to. Use only when your mod is not require SMODS. Default is `SMODS.current_mod.id`
--- @field can_be_disabled? boolean Determines can this group be disabled in mod config. If `true`, all tabs inside this group can be disabled aswell. Default is `false`
--- @field disabled_change? fun(self: TheFamilyTab, new_value: boolean) Callback when group is enabled/disabled by player in mod config. Ignores `TheFamilyGroup:enabled()`. Can be called in main menu too (from SMODS config page)

--- @class TheFamilyGroup: TheFamilyGroupOptions
--- @field load_index number
--- @field tabs { list: TheFamilyTab[], dictionary: table<string, TheFamilyTab> }
--- @field enabled_tabs { list: TheFamilyTab[], dictionary: table<string, TheFamilyTab> }

--- Create a new group
--- ```lua
--- TheFamily.create_tab_group({
---     key = "thefamily_example_group",
---
---     center = "j_family",
---
---     loc_txt = {
---         name = "Example group",
---         text = {
---             "Description for {C:attention}Example group{}"
---         }
---     },
--- })
--- ```
--- @param params TheFamilyGroupOptions
--- @return TheFamilyGroup
function TheFamily.create_tab_group(params) end
