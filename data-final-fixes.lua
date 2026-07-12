-- data-final-fixes.lua
local god_controller = data.raw["god-controller"]["default"]
if not god_controller then return end

if not god_controller.crafting_categories then
    god_controller.crafting_categories = {}
end

local categories_map = {}
for _, category in pairs(god_controller.crafting_categories) do
    categories_map[category] = true
end

-- Collect crafting categories from all character prototypes
for name, character in pairs(data.raw["character"]) do
    if character.crafting_categories then
        for _, category in pairs(character.crafting_categories) do
            if not categories_map[category] then
                categories_map[category] = true
                table.insert(god_controller.crafting_categories, category)
            end
        end
    end
end
