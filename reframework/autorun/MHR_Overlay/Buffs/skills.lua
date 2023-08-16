local this = {};

local buffs;
local buff_UI_entity;
local config;
local singletons;
local players;
local utils;
local language;
local error_handler;
local env_creature;

local sdk = sdk;
local tostring = tostring;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local require = require;
local pcall = pcall;
local table = table;
local string = string;
local Vector3f = Vector3f;
local d2d = d2d;
local math = math;
local json = json;
local log = log;
local fs = fs;
local next = next;
local type = type;
local setmetatable = setmetatable;
local getmetatable = getmetatable;
local assert = assert;
local select = select;
local coroutine = coroutine;
local utf8 = utf8;
local re = re;
local imgui = imgui;
local draw = draw;
local Vector2f = Vector2f;
local reframework = reframework;
local os = os;
local ValueType = ValueType;
local package = package;

this.list = {
	burst = nil,
	kushala_daora_soul = nil,
	intrepid_heart = nil,
	dereliction = nil,
	latent_power = nil,
	wind_mantle = nil,
	grinder_s = nil,
	counterstrike = nil,
	affinity_sliding = nil,
	coalescence = nil,
	adrenaline_rush = nil,
	wall_runner = nil,
	offensive_guard = nil,
	hellfire_cloak = nil,
	agitator = nil,
	furious = nil,
	heaven_sent = nil,
	heroics = nil,
	resuscitate = nil
};

local skill_data_list = {
	peak_performance =	{ id = 3,	is_equipped = false },
	resentment =		{ id = 4,	is_equipped = false },
	resuscitate =		{ id = 5,	is_equipped = false },
	maximum_might =		{ id = 10,	is_equipped = false },
	heroics =			{ id = 91,	is_equipped = false },
	dragonheart =		{ id = 103, is_equipped = false },
	dereliction =		{ id = 113, is_equipped = false }
}

local burst_breakpoint = 5;
local kushara_daora_soul_breakpoint = 5;
local intrepid_heart_minimal_value = 400;
local dereliction_breakpoints = {100, 50};

local wind_mantle_duration = 15;
local wind_mantle_breakpoints = { 20, 10 }; -- Sword & Shield, Lance, Hammer, Switch Axe, Insect Glaive, Long Sword, Hunting Horn
local wind_mantle_special_breakpoints = {
	[0]  = { 10,  5 }, -- Great Sword
	[3]  = { 60, 30 }, -- Light Bowgun
	[4]  = { 60, 30 }, -- Heavy Bowgun
	[6]  = { 30, 15 }, -- Gunlance
	[9]  = { 40, 20 }, -- Dual Blades
	[11] = { 30, 15 }, -- Charge Blade
	[13] = { 60, 30 }, -- Bow
}

local player_manager_type_def = sdk.find_type_definition("snow.player.PlayerManager");
local get_player_data_method = player_manager_type_def:get_method("get_PlayerData");
local get_ref_item_parameter_method = player_manager_type_def:get_method("get_RefItemParameter");

local player_user_data_item_parameter_type_def = get_ref_item_parameter_method:get_return_type();
local demondrug_atk_up_field = player_user_data_item_parameter_type_def:get_field("_DemondrugAtkUp");

local player_data_type_def = sdk.find_type_definition("snow.player.PlayerData");
-- Burst
local rengeki_power_up_count_field = player_data_type_def:get_field("_RengekiPowerUpCnt");
local rengeki_power_up_timer_field = player_data_type_def:get_field("_RengekiPowerUpTimer");
-- Kushala Daora Soul
local hyakuryu_dragon_power_up_count_field = player_data_type_def:get_field("_HyakuryuDragonPowerUpCnt");
local hyakuryu_dragon_power_up_timer_field = player_data_type_def:get_field("_HyakuryuDragonPowerUpTimer");
-- Intrepid Heart
local equip_skill_223_accumulator_field = player_data_type_def:get_field("_EquipSkill223Accumulator");
-- Derelection
local symbiosis_skill_lost_vital_field = player_data_type_def:get_field("_SymbiosisSkillLostVital");
-- Grinder (S)
local brand_new_sharpness_adjust_up_timer_field = player_data_type_def:get_field("_BrandNewSharpnessAdjustUpTimer");
-- Counterstrike
local counterattack_powerup_timer_field = player_data_type_def:get_field("_CounterattackPowerupTimer");
-- Affinity Sliding
local sliding_powerup_timer_field = player_data_type_def:get_field("_SlidingPowerupTimer");
-- Coalescence
local disaster_turn_powerup_timer_field = player_data_type_def:get_field("_DisasterTurnPowerUpTimer");
-- Adrenaline Rush
local equip_skill_208_atk_up_field = player_data_type_def:get_field("_EquipSkill208_AtkUpTimer");
-- Wall Runner
local wall_run_powerup_timer_field = player_data_type_def:get_field("_WallRunPowerupTimer");
-- Offensive Guard
local equip_skill_036_timer_field = player_data_type_def:get_field("_EquipSkill_036_Timer");
-- Hellfire Cloak
local onibi_powerup_timer_field = player_data_type_def:get_field("_OnibiPowerUpTiemr");
-- Agitator
local challenge_timer_field = player_data_type_def:get_field("_ChallengeTimer");
-- Furious
local furious_skill_stamina_buff_second_timer_field = player_data_type_def:get_field("_FuriousSkillStaminaBuffSecondTimer");



local player_base_type_def = sdk.find_type_definition("snow.player.PlayerBase");
local player_weapon_type_field = player_base_type_def:get_field("_playerWeaponType");
local get_player_skill_list_method = player_base_type_def:get_method("get_PlayerSkillList");

-- Latent Power
local power_freedom_timer_field = player_base_type_def:get_field("_PowerFreedomTimer");
-- Protective Polish
local sharpness_gauge_boost_timer_field = player_base_type_def:get_field("_SharpnessGaugeBoostTimer");
-- Heroics
local is_predicament_power_up_method = player_base_type_def:get_method("isPredicamentPowerUp");
-- Resuscitate
local is_debuff_state_method = player_base_type_def:get_method("isDebuffState");


local player_skill_list_type_def = get_player_skill_list_method:get_return_type();
local has_skill_method = player_skill_list_type_def:get_method("hasSkill");

local player_quest_base_type_def = sdk.find_type_definition("snow.player.PlayerQuestBase");
-- Wind Mantle
local equip_skill_226_attack_count_field = player_quest_base_type_def:get_field("_EquipSkill226AttackCount");
local equip_skill_226_attack_off_timer_field = player_quest_base_type_def:get_field("_EquipSkill226AttackOffTimer");
-- Heaven-Sent
local is_active_equip_skill_230_method = player_quest_base_type_def:get_method("isActiveEquipSkill230");

local system_array_type_def = sdk.find_type_definition("System.Array");
local length_method = system_array_type_def:get_method("get_Length");
local get_value_method = system_array_type_def:get_method("GetValue(System.Int32)");

function this.update(player, player_data)
	--local item_parameter = get_ref_item_parameter_method:call(singletons.player_manager);
	--if item_parameter == nil then
	--	error_handler.report("skills.update", "Failed to access Data: item_parameter");
	--	return;
	--end

	this.update_equipped_skill_data(player);

	this.update_dereliction(player_data);
	this.update_wind_mantle(player);

	this.update_generic_number_value_field("burst", player_data,
		rengeki_power_up_count_field, rengeki_power_up_timer_field, false, nil, burst_breakpoint);

	this.update_generic_number_value_field("kushala_daora_soul", player_data,
		hyakuryu_dragon_power_up_count_field, hyakuryu_dragon_power_up_timer_field, false, nil, kushara_daora_soul_breakpoint);

	this.update_generic_number_value_field("intrepid_heart", player_data, equip_skill_223_accumulator_field, nil, true, intrepid_heart_minimal_value);
	this.update_generic_timer("latent_power", player, power_freedom_timer_field);
	this.update_generic_timer("protective_polish", player, sharpness_gauge_boost_timer_field);
	this.update_generic_timer("grinder_s", player_data, brand_new_sharpness_adjust_up_timer_field);
	this.update_generic_timer("counterstrike", player_data, counterattack_powerup_timer_field);
	this.update_generic_timer("affinity_sliding", player_data, sliding_powerup_timer_field);
	this.update_generic_timer("coalescence", player_data, disaster_turn_powerup_timer_field);
	this.update_generic_timer("adrenaline_rush", player_data, equip_skill_208_atk_up_field);
	this.update_generic_timer("wall_runner", player_data, wall_run_powerup_timer_field);
	this.update_generic_timer("offensive_guard", player_data, equip_skill_036_timer_field);
	this.update_generic_timer("hellfire_cloak", player_data, onibi_powerup_timer_field);
	this.update_generic_timer("agitator", player_data, challenge_timer_field, true);
	this.update_generic_timer("furious", player_data, furious_skill_stamina_buff_second_timer_field);

	this.update_generic_boolean_value_method("heaven_sent", player, is_active_equip_skill_230_method);
	this.update_generic_boolean_value_method("heroics", player, is_predicament_power_up_method);
	this.update_generic_boolean_value_method("resuscitate", player, is_debuff_state_method);
end

function this.update_equipped_skill_data(player)
	local player_skill_list = get_player_skill_list_method:call(player);
	if player_skill_list == nil then
		error_handler.report("skills.update_equipped_skill_data", "Failed to access Data: player_skill_list");
		return;
	end

	for skill_key, skill_data in pairs(skill_data_list) do
		local has_skill = has_skill_method:call(player_skill_list, skill_data.id, 1);
		if has_skill == nil then
			error_handler.report("skills.update_equipped_skill_data", string.format("Failed to access Data: %s -> has_skill", skill_key));
			goto continue;
		end

		skill_data.is_equipped = has_skill;

		::continue::
	end
end

function this.update_generic_timer(skill_key, timer_owner, timer_field, is_infinite)
	if is_infinite == nil then is_infinite = false; end

	local skill_data = skill_data_list[skill_key];
	if skill_data ~= nil and not skill_data.is_equipped then
		return;
	end

	local timer = nil;
	if timer_field ~= nil then
		timer = timer_field:get_data(timer_owner);
		if timer == nil then
			error_handler.report("skills.update_generic_timer", string.format("Failed to access Data: %s_timer", skill_key));
			return;
		end

		if utils.number.is_equal(timer, 0) then
			this.list[skill_key] = nil;
			return;
		end

		if is_infinite then
			timer = nil;
		else
			timer = timer / 60;
		end
	end

	this.update_generic(skill_key, 1, timer);
end

function this.update_generic_number_value_field(skill_key, timer_owner, value_field, timer_field, is_infinite, minimal_value, breakpoint)
	if minimal_value == nil then minimal_value = 1; end
	breakpoint = breakpoint or 1000000;
	if is_infinite == nil then is_infinite = false; end

	local skill_data = skill_data_list[skill_key];
	if skill_data ~= nil and not skill_data.is_equipped then
		return;
	end

	local level = 1;

	if value_field ~= nil then
		local value = value_field:get_data(timer_owner);
		
		if value == nil then
			error_handler.report("skills.update_generic_number_value_field", string.format("Failed to access Data: %s_value", skill_key));
			return;
		end

		if value < minimal_value then
			this.list[skill_key] = nil;
			return;
		end

		if value >= breakpoint then
			level = 2;
		end
	end

	local timer = nil;
	if timer_field ~= nil then
		timer = timer_field:get_data(timer_owner);
		if timer == nil then
			error_handler.report("skills.update_generic_number_value_field", string.format("Failed to access Data: %s_timer", skill_key));
			return;
		end

		if value_field == nil and utils.number.is_equal(timer, 0) then
			this.list[skill_key] = nil;
			return;
		end

		if is_infinite then
			timer = nil;
		else
			timer = timer / 60;
		end
	end

	this.update_generic(skill_key, level, timer);
end

function this.update_generic_boolean_value_field(skill_key, timer_owner, value_field, timer_field, is_infinite, minimal_value)
	if minimal_value == nil then minimal_value = true; end
	if is_infinite == nil then is_infinite = false; end

	local skill_data = skill_data_list[skill_key];
	if skill_data ~= nil and not skill_data.is_equipped then
		return;
	end

	if value_field ~= nil then
		local value = value_field:get_data(timer_owner);
		
		if value == nil then
			error_handler.report("skills.update_generic_boolean_value_field", string.format("Failed to access Data: %s_value", skill_key));
			return;
		end

		if value < minimal_value then
			this.list[skill_key] = nil;
			return;
		end
	end

	local timer = nil;
	if timer_field ~= nil then
		timer = timer_field:get_data(timer_owner);
		if timer == nil then
			error_handler.report("skills.update_generic_boolean_value_field", string.format("Failed to access Data: %s_timer", skill_key));
			return;
		end

		if value_field == nil and utils.number.is_equal(timer, 0) then
			this.list[skill_key] = nil;
			return;
		end

		if is_infinite then
			timer = nil;
		else
			timer = timer / 60;
		end
	end

	this.update_generic(skill_key, 1, timer);
end

function this.update_generic_number_value_method(skill_key, timer_owner, value_method, timer_field, is_infinite, minimal_value, breakpoint)
	if minimal_value == nil then minimal_value = 1; end
	breakpoint = breakpoint or 1000000;
	if is_infinite == nil then is_infinite = false; end

	local skill_data = skill_data_list[skill_key];
	if skill_data ~= nil and not skill_data.is_equipped then
		return;
	end

	local level = 1;

	if value_method ~= nil then
		local value = value_method:call(timer_owner);
		
		if value == nil then
			error_handler.report("skills.update_generic_number_value_method", string.format("Failed to access Data: %s_value", skill_key));
			return;
		end

		if value < minimal_value then
			this.list[skill_key] = nil;
			return;
		end

		if value >= breakpoint then
			level = 2;
		end
	end

	local timer = nil;
	if timer_field ~= nil then
		timer = timer_field:get_data(timer_owner);
		if timer == nil then
			error_handler.report("skills.update_generic_number_value_method", string.format("Failed to access Data: %s_timer", skill_key));
			return;
		end

		if value_method == nil and utils.number.is_equal(timer, 0) then
			this.list[skill_key] = nil;
			return;
		end

		if is_infinite then
			timer = nil;
		else
			timer = timer / 60;
		end
	end

	this.update_generic(skill_key, level, timer);
end

function this.update_generic_boolean_value_method(skill_key, timer_owner, value_method, timer_field, is_infinite, minimal_value)
	if minimal_value == nil then minimal_value = true; end
	if is_infinite == nil then is_infinite = false; end

	local skill_data = skill_data_list[skill_key];
	if skill_data ~= nil and not skill_data.is_equipped then
		return;
	end

	if value_method ~= nil then
		local value = value_method:call(timer_owner);
		
		if value == nil then
			error_handler.report("skills.update_generic_boolean_value_method", string.format("Failed to access Data: %s_value", skill_key));
			return;
		end

		if value ~= minimal_value then
			this.list[skill_key] = nil;
			return;
		end
	end

	local timer = nil;
	if timer_field ~= nil then
		timer = timer_field:get_data(timer_owner);
		if timer == nil then
			error_handler.report("skills.update_generic_boolean_value_method", string.format("Failed to access Data: %s_timer", skill_key));
			return;
		end

		if value_method == nil and utils.number.is_equal(timer, 0) then
			this.list[skill_key] = nil;
			return;
		end

		if is_infinite then
			timer = nil;
		else
			timer = timer / 60;
		end
	end

	this.update_generic(skill_key, 1, timer);
end

function this.update_generic(skill_key, level, timer)
	local skill = this.list[skill_key];
	if skill == nil then
		local name = language.current_language.skills[skill_key];

		skill = buffs.new(buffs.types.skill, skill_key, name, level, timer);
		this.list[skill_key] = skill;
	else
		skill.level = level;

		if timer ~= nil then
			buffs.update_timer(skill, timer);
		end
	end
end

function this.update_dereliction(player_data)
	local dereliction_value = symbiosis_skill_lost_vital_field:get_data(player_data);
	if dereliction_value == nil then
		error_handler.report("skills.update_derelection", "Failed to access Data: dereliction_value");
		return;
	end

	if dereliction_value == 0 then
		this.list.dereliction = nil;
		return;
	end

	local level = 1;
	for index, breakpoint in ipairs(dereliction_breakpoints) do
		if dereliction_value >= breakpoint then
			level = 4 - index;
			break;
		end
	end

	local skill = this.list.dereliction;
	if skill == nil then
		local name = language.current_language.skills.dereliction;

		skill = buffs.new(buffs.types.skill, "dereliction", name, level);
		this.list.dereliction = skill;
	else
		skill.level = level;
	end
end

function this.update_wind_mantle(player)
	local wind_mantle_timer = equip_skill_226_attack_off_timer_field:get_data(player);
	if wind_mantle_timer == nil then
		error_handler.report("skills.update_wind_mantle", "Failed to access Data: wind_mantle_timer");
		return;
	end

	if utils.number.is_equal(wind_mantle_timer, 0) then
		this.list.wind_mantle = nil;
		return;
	end

	local wind_mantle_value = equip_skill_226_attack_count_field:get_data(player);
	if wind_mantle_value == nil then
		error_handler.report("skills.update_wind_mantle", "Failed to access Data: wind_mantle_value");
		return;
	end

	local weapon_type = player_weapon_type_field:get_data(player);
	if player == nil then
		error_handler.report("skills.update_wind_mantle", "Failed to access Data: weapon_type");
		return;
	end

	local breakpoints = wind_mantle_breakpoints;
	for weapon_type_index, special_breakpoints in pairs(wind_mantle_special_breakpoints) do
		if weapon_type == weapon_type_index then
			breakpoints = special_breakpoints;
			break;
		end
	end

	local level = 1;
	for index, breakpoint in ipairs(breakpoints) do
		if wind_mantle_value >= breakpoint then
			level = 4 - index;
			break;
		end
	end

	local buff = this.list.wind_mantle;
	if buff == nil then
		local name = language.current_language.skills.wind_mantle;

		buff = buffs.new(buffs.types.skill, "wind_mantle", name, level, wind_mantle_duration);
		this.list.wind_mantle = buff;
	else
		buff.level = level;
		buffs.update_timer(buff, wind_mantle_duration - (wind_mantle_timer / 60));
	end
end

function this.init_names()
	for skill_key, skill in pairs(this.list) do
		local name = language.current_language.skills[skill_key];

		if name == nil then
			name = skill_key;
		end

		skill.name = name;
	end
end

function this.init_dependencies()
	buffs = require("MHR_Overlay.Buffs.buffs");
	config = require("MHR_Overlay.Misc.config");
	utils = require("MHR_Overlay.Misc.utils");
	buff_UI_entity = require("MHR_Overlay.UI.UI_Entities.buff_UI_entity");
	singletons = require("MHR_Overlay.Game_Handler.singletons");
	players = require("MHR_Overlay.Damage_Meter.players");
	language = require("MHR_Overlay.Misc.language");
	error_handler = require("MHR_Overlay.Misc.error_handler");
	env_creature = require("MHR_Overlay.Endemic_Life.env_creature");
end

function this.init_module()
end

return this;