local monster = {};
local small_monster;
local large_monster;

local enemy_character_base_type_def = sdk.find_type_definition("snow.enemy.EnemyCharacterBase");
local enemy_character_base_type_def_update_method = enemy_character_base_type_def:get_method("update");

local is_boss_enemy_method = sdk.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("get_isBossEnemy");

sdk.hook(enemy_character_base_type_def_update_method, function(args)
	monster.update_monster(sdk.to_managed_object(args[2]));
end, function(retval)
	return retval;
end);

local tick_count = 0
local last_update_tick = 0
local recorded_monsters = {}
local updated_monsters = {}
local known_big_monsters = {}
local num_known_monsters = 0
local num_updated_monsters = 0

local updates_this_tick = 0
local MAX_UPDATES_PER_TICK = 2

-- run every tick to keep track of msonsters
-- whenever we've updated enough monsters to surpass how many we've seen,
-- we reset and start over
-- this allows us to only update N monsters per tick to save on performance
-- the reason for this is that the hooks on all the monsters' update functions
-- causes a HUGE performance hit (adds ~3+ ms to UpdateBehavior and frame time)
re.on_pre_application_entry("UpdateBehavior", function()
    tick_count = tick_count + 1;
	updates_this_tick = 0;
 
    if num_known_monsters ~= 0 and num_updated_monsters >= num_known_monsters or tick_count >= num_known_monsters * 2 then
        recorded_monsters = {};
        updated_monsters = {};
		known_big_monsters = {};
        last_update_tick = 0;
        tick_count = 0;
        num_known_monsters = 0;
        num_updated_monsters = 0;
		updates_this_tick = 0;
    end
end)

function monster.update_monster(enemy)
	if enemy == nil then
		return;
	end

    if not recorded_monsters[enemy] then
        num_known_monsters = num_known_monsters + 1
        recorded_monsters[enemy] = true
    end

	-- saves on a method call.
	if not known_big_monsters[enemy] then
		known_big_monsters[enemy] = is_boss_enemy_method:call(enemy);
	end

	local is_large = known_big_monsters[enemy];

	if is_large == nil then
		return;
	end

	if updated_monsters[enemy] then
		-- this is the VERY LEAST thing we should do all the time
		-- so the position doesn't lag all over the place
		-- due to how infrequently we update the monster(s).
		if is_large then
			large_monster.update_position(enemy);
		else
			small_monster.update_position(enemy);
		end

		return
	end

    -- only updates N monsters per tick to increase performance
    if tick_count == last_update_tick then
		if updates_this_tick >= MAX_UPDATES_PER_TICK then
			-- this is the VERY LEAST thing we should do all the time
			-- so the position doesn't lag all over the place
			-- due to how infrequently we update the monster(s).
			if is_large then
				large_monster.update_position(enemy);
			else
				small_monster.update_position(enemy);
			end

        	return
		end
    end

	updates_this_tick = updates_this_tick + 1;
    last_update_tick = tick_count;
    num_updated_monsters = num_updated_monsters + 1;
    updated_monsters[enemy] = true;
	
	-- actually update the enemy now. we don't do this very often
	-- due to how much CPU time it takes to update each monster.
	if is_large then
		large_monster.update(enemy);
	else
		small_monster.update(enemy);
	end
end

function monster.init_module()
	small_monster = require("MHR_Overlay.Monsters.small_monster");
	large_monster = require("MHR_Overlay.Monsters.large_monster");
end

return monster;