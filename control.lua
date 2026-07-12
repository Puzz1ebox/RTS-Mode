-- control.lua
local RESTRICTION_RADIUS = 50

script.on_init(function()
    if remote.interfaces["freeplay"] then
        remote.call("freeplay", "set_skip_intro", true)
        remote.call("freeplay", "set_disable_crashsite", true)
    end
end)

-- Sets the player to God Mode and destroys their physical character entity
local function setup_player(player)
    if player.controller_type ~= defines.controllers.god then
        local old_character = player.character
        player.set_controller{type = defines.controllers.god}
        if old_character and old_character.valid then
            -- Transfer items from character to god inventory
            local inv_types = {
                defines.inventory.character_main,
                defines.inventory.character_guns,
                defines.inventory.character_ammo,
                defines.inventory.character_armor,
                defines.inventory.character_trash
            }
            for _, inv_type in ipairs(inv_types) do
                local inv = old_character.get_inventory(inv_type)
                if inv and not inv.is_empty() then
                    for i = 1, #inv do
                        local stack = inv[i]
                        if stack and stack.valid_for_read then
                            player.insert(stack)
                        end
                    end
                end
            end
            old_character.destroy()
        end
    end
end

script.on_event(defines.events.on_player_created, function(event)
    setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    setup_player(game.get_player(event.player_index))
end)

-- Prevents building entities near enemy bases
local function check_and_cancel_build(entity, player, robot)
    if not entity or not entity.valid then return end
    
    local surface = entity.surface
    local pos = entity.position
    
    -- Find nearby enemy spawners
    local enemies = surface.find_entities_filtered{
        type = "unit-spawner",
        position = pos,
        radius = RESTRICTION_RADIUS,
        limit = 1
    }
    
    if #enemies > 0 then
        local item_name = nil
        
        if entity.prototype.items_to_place_this and #entity.prototype.items_to_place_this > 0 then
            item_name = entity.prototype.items_to_place_this[1].name
        else
            item_name = entity.name -- fallback
        end

        if player then
            if item_name then
                player.insert({name = item_name, count = 1})
            end
            player.create_local_flying_text{
                text = {"message.too-close-to-enemy-base"},
                position = pos,
                color = {r=1, g=0.2, b=0.2}
            }
        elseif robot then
            local inv = robot.get_inventory(defines.inventory.robot_cargo)
            if inv and item_name then
                inv.insert({name = item_name, count = 1})
            end
        end
        entity.destroy()
    end
end

script.on_event(defines.events.on_built_entity, function(event)
    check_and_cancel_build(event.entity, game.get_player(event.player_index), nil)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    check_and_cancel_build(event.entity, nil, event.robot)
end)

-- Generic capsule usage restriction (UPS friendly since it only fires on player action)
script.on_event(defines.events.on_player_used_capsule, function(event)
    local player = game.get_player(event.player_index)
    local surface = player.surface
    local pos = player.position 
    
    local enemies = surface.find_entities_filtered{
        type = "unit-spawner",
        position = pos,
        radius = RESTRICTION_RADIUS,
        limit = 1
    }
    
    if #enemies > 0 then
        -- Find generic throwables created near the player camera view
        local entities = surface.find_entities_filtered{
            position = pos,
            radius = 10,
            type = {"projectile", "smoke-with-trigger", "combat-robot"}
        }
        
        for _, ent in pairs(entities) do
            ent.destroy()
        end
        
        player.insert({name = event.item.name, count = 1})
        player.create_local_flying_text{
            text = {"message.cannot-attack-bases-directly"},
            position = pos,
            color = {r=1, g=0.2, b=0.2}
        }
    end
end)
