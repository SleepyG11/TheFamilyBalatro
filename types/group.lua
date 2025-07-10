--- @meta

--- @class TheFamilyGroupOptions: table
--- @field key string Unique key. To prevent intersections, add prefix
--- @field order? number Value user for sorting, from lowest to highest
--- @field enabled? fun(self: TheFamilyGroup): boolean Function which determines can tabs inside this group be created.

--- @class TheFamilyGroup: TheFamilyGroupOptions
--- @field tabs { list: TheFamilyTab[], dictionary: table<string, TheFamilyTab> }
--- @field enabled_tabs { list: TheFamilyTab[], dictionary: table<string, TheFamilyTab> }
--- @field is_enabled boolean
