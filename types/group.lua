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
--- @field original_mod_id? string
--- @field loc_txt? table

--- @class TheFamilyGroup: TheFamilyGroupOptions
--- @field load_index number
--- @field tabs { list: TheFamilyTab[], dictionary: table<string, TheFamilyTab> }
--- @field enabled_tabs { list: TheFamilyTab[], dictionary: table<string, TheFamilyTab> }
--- @field is_enabled boolean
