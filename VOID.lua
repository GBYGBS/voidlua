local ffi = require('ffi')
local vector = require("vector")
local pui = require("gamesense/pui")
local base64 = require("gamesense/base64")
local clipboard = require("gamesense/clipboard")
local weapons = require("gamesense/csgo_weapons")
local entity_lib = require("gamesense/entity")
local trace = require('gamesense/trace')
local csgo_weapons = require("gamesense/csgo_weapons")
local bit = require("bit")

local classptr = ffi.typeof('void***')
local rawientitylist = client.create_interface('client.dll', 'VClientEntityList003') or error('VClientEntityList003 wasnt found', 2)

local ientitylist = ffi.cast(classptr, rawientitylist) or error('rawientitylist is nil', 2)

local get_client_entity = ffi.cast('void*(__thiscall*)(void*, int)', ientitylist[0][3]) or error('get_client_entity is nil', 2)

-- =====================================================
-- GAME ENHANCER FEATURE (FROM HRISTIO.LUA)
-- =====================================================

local game_enhancer = {}
do
    local fps_cvars = {
        ['Fix chams color'] = {'mat_autoexposure_max_multiplier', 0.2, 1},
        ['Disable dynamic lighting'] = {'r_dynamic', 0, 1},
        ['Disable dynamic shadows'] = {'r_dynamiclighting', 0, 1},
        ['Disable first-person tracers'] = {'r_drawtracers_firstperson', 0, 1},
        ['Disable ragdolls'] = {'cl_disable_ragdolls', 1, 0},
        ['Disable eye gloss'] = {'r_eyegloss', 0, 1},
        ['Disable eye movement'] = {'r_eyemove', 0, 1},
        ['Disable muzzle flash light'] = {'muzzleflash_light', 0, 1},
        ['Enable low CPU audio'] = {'dsp_slow_cpu', 1, 0},
        ['Disable bloom'] = {'mat_disable_bloom', 1, 0},
        ['Disable particles'] = {'r_drawparticles', 0, 1},
        ['Reduce breakable objects'] = {'func_break_max_pieces', 0, 15}
    }

    local function table_contains(tbl, val)
        for _, v in ipairs(tbl) do
            if v == val then
                return true
            end
        end
        return false
    end

    local function on_setup_command()
        if not game_enhancer.enable or not ui.get(game_enhancer.enable) then
            for name, data in pairs(fps_cvars) do
                local cvar_name, boost_value, default_value = unpack(data)
                local success, err = pcall(function() cvar[cvar_name]:set_int(default_value) end)
            end
            return
        end

        local selected_boosts = ui.get(game_enhancer.settings)
        for name, data in pairs(fps_cvars) do
            local cvar_name, boost_value, default_value = unpack(data)
            local is_selected = table_contains(selected_boosts, name)
            local final_value = is_selected and boost_value or default_value
            local success, err = pcall(function() cvar[cvar_name]:set_int(final_value) end)
        end
    end

    -- Initialize UI elements
    game_enhancer.enable = ui.new_checkbox("RAGE", "Other", 'Game enhancer')
    game_enhancer.settings = ui.new_multiselect("RAGE", "Other", '\nGame enhancer list', {
        'Fix chams color', 'Disable dynamic lighting', 'Disable dynamic shadows',
        'Disable first-person tracers', 'Disable ragdolls', 'Disable eye gloss',
        'Disable eye movement', 'Disable muzzle flash light', 'Enable low CPU audio',
        'Disable bloom', 'Disable particles', 'Reduce breakable objects'
    })

    client.set_event_callback('setup_command', on_setup_command)
end

-- =====================================================
-- AIM PUNCH MISS FIX (FROM HRISTIO.LUA)
-- =====================================================

local aim_punch_fix_state = { last_health = 100, override_active = false }

local function aim_punch_fix_callback()
    if aim_punch_fix_checkbox == nil or not ui.get(aim_punch_fix_checkbox) then
        return
    end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        aim_punch_fix_state.last_health = 100
        if aim_punch_fix_state.override_active then
            client.exec("cl_min_hitchance 1")
            aim_punch_fix_state.override_active = false
        end
        return
    end

    local current_health = entity.get_prop(me, 'm_iHealth') or 100

    if current_health < aim_punch_fix_state.last_health then
        client.exec("cl_min_hitchance 100")
        aim_punch_fix_state.override_active = true
    elseif aim_punch_fix_state.override_active then
        client.exec("cl_min_hitchance 1")
        aim_punch_fix_state.override_active = false
    end

    aim_punch_fix_state.last_health = current_health
end

local aim_punch_fix_checkbox = ui.new_checkbox("RAGE", "Other", 'Aim punch miss fix')
client.set_event_callback('setup_command', aim_punch_fix_callback)

-- =====================================================
-- ENHANCED RESOLVER (MERGED FROM HRISTIO.LUA)
-- =====================================================

-- Define C structures for animation data access
ffi.cdef[[
struct animation_layer_t {
    char  pad_0000[20];
    uint32_t m_nOrder;
    uint32_t m_nSequence;
    float m_flPrevCycle;
    float m_flWeight;
    float m_flWeightDeltaRate;
    float m_flPlaybackRate;
    float m_flCycle;
    void *m_pOwner;
    char  pad_0038[4];
};
]]

-- Resolver state and variables
local resolver_state = {
    is_analyzing_aa = false,
    player_fired = nil,
    time_difference = nil,
    ticks_since_last_shot = nil
}

-- Player tracking for resolver analysis
local player_history = { cur = {}, prev = {}, pre_prev = {}, pre_pre_prev = {} }

-- Player anti-aim data storage
local player_aa_info = {}
local player_aa_data = {}

-- UI Elements for enhanced resolver
local enable_resolver_checkbox = nil
local resolver_mode = nil

-- Normalize angle to -180 - 180 range
local function normalize_angle(angle)
    while angle > 180 do
        angle = angle - 360
    end
    while angle < -180 do
        angle = angle + 360
    end
    return angle
end

-- Calculate angle between two vectors
local function calculate_angle(start_pos, end_pos)
    local delta = end_pos - start_pos
    local angle = math.atan(delta.y / delta.x)
    angle = normalize_angle(angle * 180 / math.pi)

    if delta.x >= 0 then
        angle = normalize_angle(angle + 180)
    end

    return angle
end

-- Convert seconds to ticks
local function seconds_to_ticks(seconds)
    return math.floor(0.5 + seconds / globals.tickinterval())
end

-- Get animation layer
local function get_anim_layer(entity_ptr, layer_index)
    layer_index = layer_index or 1
    entity_ptr = ffi.cast(classptr, entity_ptr)
    return ffi.cast("struct animation_layer_t**", ffi.cast("char*", entity_ptr) + 0x2990)[0][layer_index]
end

-- Track player history for anti-aim analysis
local function track_players(local_player)
    local enemy_players = entity.get_players(true)

    if #enemy_players == 0 then
        player_history = {
            cur = {},
            prev = {},
            pre_prev = {},
            pre_pre_prev = {}
        }
        return nil
    end

    for i, player in ipairs(enemy_players) do
        if entity.is_alive(player) and not entity.is_dormant(player) then
            -- Get simulation tick
            local sim_tick = 0
            local esp_flags = entity.get_esp_data(player).flags or 0

            -- Adjust for backtrack
            if bit.band(esp_flags, bit.lshift(1, 17)) ~= 0 then
                sim_tick = seconds_to_ticks(entity.get_prop(player, "m_flSimulationTime")) - 14
            else
                sim_tick = seconds_to_ticks(entity.get_prop(player, "m_flSimulationTime"))
            end

            -- Only record if tick changed
            if player_history.cur[player] == nil or sim_tick - player_history.cur[player].simtime >= 1 then
                -- Shift history
                player_history.pre_pre_prev[player] = player_history.pre_prev[player]
                player_history.pre_prev[player] = player_history.prev[player]
                player_history.prev[player] = player_history.cur[player]

                -- Get player origin and angles
                local local_origin = vector(entity.get_prop(local_player, "m_vecOrigin"))
                local eye_angles = vector(entity.get_prop(player, "m_angEyeAngles"))
                local player_origin = vector(entity.get_prop(player, "m_vecOrigin"))

                -- Calculate relative angle
                local angle_diff = math.floor(normalize_angle(eye_angles.y - calculate_angle(local_origin, player_origin)))
                local backwards_angle = math.floor(normalize_angle(calculate_angle(local_origin, player_origin)))

                -- Get player state
                local duck_amount = entity.get_prop(player, "m_flDuckAmount")
                local on_ground = bit.band(entity.get_prop(player, "m_fFlags"), 1) == 1
                local velocity = vector(entity.get_prop(player, "m_vecVelocity")):length2d()

                -- Determine player stance
                local stance = on_ground and
                              (duck_amount == 1 and "duck" or
                               (velocity > 1.2 and "running" or "standing")) or "air"

                -- Get last shot time
                local weapon = entity.get_player_weapon(player)
                local last_shot_time = entity.get_prop(weapon, "m_fLastShotTime")

                -- Record player data
                player_history.cur[player] = {
                    id = player,
                    origin = vector(entity.get_origin(player)),
                    pitch = eye_angles.x,
                    yaw = angle_diff,
                    yaw_backwards = backwards_angle,
                    simtime = sim_tick,
                    stance = stance,
                    esp_flags = entity.get_esp_data(player).flags or 0,
                    last_shot_time = last_shot_time
                }
            end
        end
    end
end

-- Analyze player anti-aim patterns
local function analyze_anti_aim(local_player)
    if not entity.is_alive(local_player) then
        if resolver_state.is_analyzing_aa then
            -- Reset when dead
        end
        resolver_state.is_analyzing_aa = false
        return
    end

    local enemy_players = entity.get_players(true)

    if #enemy_players == 0 then
        return nil
    end

    for i, player in ipairs(enemy_players) do
        if entity.is_alive(player) and not entity.is_dormant(player) then
            -- Skip if missing history
            if player_history.cur[player] == nil or
               player_history.prev[player] == nil or
               player_history.pre_prev[player] == nil or
               player_history.pre_pre_prev[player] == nil then
                return
            end

            local aa_type = nil

            -- Calculate yaw delta
            local yaw_delta_abs = math.abs(normalize_angle(player_history.cur[player].yaw - player_history.prev[player].yaw))
            local yaw_delta = normalize_angle(player_history.cur[player].yaw - player_history.prev[player].yaw)

            -- Check if player fired recently
            if player_history.cur[player].last_shot_time ~= nil then
                resolver_state.time_difference = globals.curtime() - player_history.cur[player].last_shot_time
                resolver_state.ticks_since_last_shot = resolver_state.time_difference / globals.tickinterval()
                resolver_state.player_fired = resolver_state.ticks_since_last_shot <= math.floor(0.2 / globals.tickinterval())
            end

            -- Initialize player data table if needed
            if player_aa_data[player] == nil then
                player_aa_data[player] = {
                    stand = {},
                    stand_type = {},
                    run = {},
                    run_type = {},
                    air = {},
                    air_type = {},
                    duck = {},
                    duck_type = {}
                }
            end

            -- Analyze anti-aim patterns when enabled
            if enable_resolver_checkbox and ui.get(enable_resolver_checkbox) then
                resolver_state.is_analyzing_aa = true

                -- Get yaw values from history
                local current_yaw = player_history.cur[player].yaw
                local prev_yaw = player_history.prev[player].yaw
                local pre_prev_yaw = player_history.pre_prev[player].yaw
                local pre_pre_prev_yaw = player_history.pre_pre_prev[player].yaw

                -- Calculate yaw differences
                local delta_cur_prev = normalize_angle(current_yaw - prev_yaw)
                local delta_cur_pre_prev = normalize_angle(current_yaw - pre_prev_yaw)
                local delta_prev_pre_pre_prev = normalize_angle(prev_yaw - pre_pre_prev_yaw)
                local delta_prev_pre_prev = normalize_angle(prev_yaw - pre_prev_yaw)
                local delta_pre_prev_pre_pre_prev = normalize_angle(pre_prev_yaw - pre_pre_prev_yaw)
                local delta_pre_pre_prev_cur = normalize_angle(pre_pre_prev_yaw - current_yaw)
                local delta_yaw_difference = normalize_angle(yaw_delta_abs - delta_pre_pre_prev_cur)

                -- Determine anti-aim type (removed !! and !!! flags as requested)
                if resolver_state.player_fired and
                   math.abs(math.abs(player_history.cur[player].pitch) - math.abs(player_history.prev[player].pitch)) > 30 and
                   player_history.cur[player].pitch < player_history.prev[player].pitch then
                    aa_type = "ON SHOT"
                else
                    if math.abs(player_history.cur[player].pitch) > 60 then
                        if yaw_delta_abs > 30 and
                           math.abs(delta_cur_pre_prev) < 15 and
                           math.abs(delta_prev_pre_pre_prev) < 15 then
                            aa_type = "DESYNC"
                        elseif math.abs(delta_cur_prev) > 15 or
                               math.abs(delta_prev_pre_prev) > 15 or
                               math.abs(delta_pre_prev_pre_pre_prev) > 15 or
                               math.abs(delta_pre_pre_prev_cur) > 15 then
                            aa_type = "JITTER"
                        end
                    end
                end

                -- Apply anti-aim correction if detected
                if player_history.cur[player].pitch >= 78 and player_history.prev[player].pitch > 78 then
                    if aa_type == "JITTER" or aa_type == "DESYNC" then
                        if aa_type == "DESYNC" then
                            if normalize_angle(current_yaw - prev_yaw) > 0 then
                                plist.set(player, "Force body yaw", true)
                                plist.set(player, "Force body yaw value", 60)
                            elseif normalize_angle(current_yaw - prev_yaw) < 0 then
                                plist.set(player, "Force body yaw", true)
                                plist.set(player, "Force body yaw value", -60)
                            end
                        elseif aa_type == "JITTER" then
                            local last_yaw = 0
                            local current_forced_yaw = 0

                            -- Pattern detection for special desync
                            if (prev_yaw == normalize_angle(current_yaw - yaw_delta_abs) or
                                prev_yaw == normalize_angle(current_yaw + yaw_delta_abs)) and
                               (pre_prev_yaw == normalize_angle(current_yaw + yaw_delta_abs) or
                                pre_prev_yaw == current_yaw) and
                               (pre_prev_yaw == normalize_angle(current_yaw + yaw_delta_abs) or
                                pre_prev_yaw == current_yaw) then

                                plist.set(player, "Force body yaw", true)
                                plist.set(player, "Force body yaw value", 0)
                                last_yaw = current_yaw
                            else
                                if current_yaw ~= last_yaw then
                                    if current_yaw < 0 then
                                        plist.set(player, "Force body yaw", true)
                                        plist.set(player, "Force body yaw value", 60)
                                    else
                                        plist.set(player, "Force body yaw", true)
                                        plist.set(player, "Force body yaw value", -60)
                                    end
                                end
                            end
                        end
                    else
                        plist.set(player, "Force body yaw", false)
                        plist.set(player, "Force body yaw value", 0)
                    end
                end

            -- Reset all corrections if disabled
            else
                aa_type = nil
                plist.set(player, "Force body yaw", false)
                plist.set(player, "Force body yaw value", 0)
                resolver_state.is_analyzing_aa = false
            end

            -- Store results for ESP flag
            player_aa_info[player] = {
                anti_aim_type = aa_type,
                yaw_delta = yaw_delta
            }
        else
            resolver_state.player_fired = false
            resolver_state.time_difference = 0
            resolver_state.ticks_since_last_shot = 0
        end
    end
end

-- ESP flag callback for enhanced resolver
local function esp_flag_callback(player)
    if not entity.is_alive(entity.get_local_player()) then
        return
    end

    if enable_resolver_checkbox and ui.get(enable_resolver_checkbox) and entity.is_alive(player) and not entity.is_dormant(player) then
        if player_aa_info[player] ~= nil and player_aa_info[player].anti_aim_type ~= nil then
            return true, string.upper(player_aa_info[player].anti_aim_type)
        end
    end
end

-- Main resolver update function
local function on_net_update_end()
    local local_player = entity.get_local_player()

    if not entity.is_alive(local_player) then
        return
    end

    -- Track players for anti-aim analysis (always needed for ESP flags)
    track_players(local_player)

    -- Analyze anti-aim patterns only if resolver is enabled
    if enable_resolver_checkbox and ui.get(enable_resolver_checkbox) then
        analyze_anti_aim(local_player)
    else
        -- Reset resolver state when disabled
        resolver_state.is_analyzing_aa = false
        resolver_state.player_fired = false
        resolver_state.time_difference = 0
        resolver_state.ticks_since_last_shot = 0
    end
end

-- Initialize enhanced resolver UI elements
local function init_enhanced_resolver_ui()
    if enable_resolver_checkbox == nil then
        enable_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable enhanced resolver")
    end

    if resolver_mode == nil then
        resolver_mode = ui.new_combobox("RAGE", "Other", "Enhanced resolver mode", {"desync", "off"})
    end
end

-- Register enhanced resolver callbacks
client.set_event_callback("net_update_end", on_net_update_end)
client.register_esp_flag("", 255, 255, 255, esp_flag_callback)

-- =====================================================
-- ORIGINAL AMBANI CODE STARTS HERE
-- =====================================================

local global_data_saved_somewhere = [[{"t":{"hideshots":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":5,"hold_time":2,"body_yaw_add":-1,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"default"},"slow walk":{"enable":false,"yaw_base":"local view","options":["~"],"body_yaw":"off","yaw_jitter_add":0,"hold_time":2,"body_yaw_add":0,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"off","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"defensive"},"run":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-25,"yaw_jitter":"off","yaw_add_r":28,"defensive_pitch_mode":"zero","defensive_builder":"default"},"duck jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","air tick","safe head (lc)","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":1,"hold_delay":3,"defensive_yaw_mode":"spin - static","yaw_add":-22,"yaw_jitter":"center","yaw_add_r":25,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"global":{"defensive_builder":"defensive","yaw_base":"at targets","options":["anti-backstab","safe head (lc)","~"],"body_yaw":"jitter","hold_time":2,"yaw_jitter_add":61,"hold_delay":2,"defensive_yaw_mode":"spin - static","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"body_yaw_add":0,"defensive_pitch_mode":"ambani"},"duck":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"up","defensive_builder":"default"},"stand":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-180,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-20,"yaw_jitter":"center","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"duck move":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","defensive yaw","~"],"body_yaw":"jitter","yaw_jitter_add":-16,"hold_time":5,"body_yaw_add":1,"hold_delay":4,"defensive_yaw_mode":"spin - static","yaw_add":13,"yaw_jitter":"center","yaw_add_r":13,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"}},"ct":{"hideshots":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":5,"hold_time":2,"body_yaw_add":-1,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"default"},"slow walk":{"enable":true,"yaw_base":"at targets","options":["defensive yaw","safe head (lc)","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":26,"defensive_yaw_mode":"spin","yaw_add":-20,"yaw_jitter":"off","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"run":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":3,"defensive_yaw_mode":"spin - static","yaw_add":-30,"yaw_jitter":"off","yaw_add_r":41,"defensive_pitch_mode":"zero","defensive_builder":"defensive"},"duck jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","air tick","safe head (lc)","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-18,"yaw_jitter":"off","yaw_add_r":37,"defensive_pitch_mode":"up","defensive_builder":"default"},"global":{"defensive_builder":"defensive","yaw_base":"at targets","options":["anti-backstab","safe head (lc)","~"],"body_yaw":"jitter","hold_time":2,"yaw_jitter_add":61,"hold_delay":2,"defensive_yaw_mode":"spin - static","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"body_yaw_add":0,"defensive_pitch_mode":"ambani"},"duck":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-31,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"up","defensive_builder":"default"},"stand":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-180,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-20,"yaw_jitter":"center","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"duck move":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"off","yaw_add_r":36,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":-16,"hold_time":5,"body_yaw_add":1,"hold_delay":4,"defensive_yaw_mode":"spin - static","yaw_add":13,"yaw_jitter":"center","yaw_add_r":13,"defensive_pitch_mode":"up","defensive_builder":"default"}}}]]]

json.encode_sparse_array(true)

local unpack = unpack
local next = next
local line = renderer.line
local world_to_screen = renderer.world_to_screen
local unpack_vec = vector().unpack
local resolver_flag = {}
local resolver_status = false

local function construct_points(origin, min, max)
	local points = {
		-- construct initial 4 points, we can extrapolate vertically in a moment
		vector(origin.x + min.x, origin.y + min.y, origin.z + min.z),
		vector(origin.x + max.x, origin.y + min.y, origin.z + min.z),
		vector(origin.x + max.x, origin.y + max.y, origin.z + min.z),
		vector(origin.x + min.x, origin.y + max.y, origin.z + min.z),
	}

	-- create our top 4 points
	for i = 1, 4 do
		local point = points[i]
		points[#points + 1] = vector(point.x, point.y, point.z + min.z + max.z)
	end
	
	-- replace all of our points with w2s results
	for i = 1, 8 do
		points[i] = {world_to_screen(unpack_vec(points[i]))}
	end

	return points
end

local function draw_box(origin, min, max, r, g, b, a)
	local points = construct_points(origin, min, max)
	local connections = {
		[1] = { 2, 4, 5 },
		[2] = { 3, 6 },
		[3] = { 4, 7 },
		[4] = { 8 },
		[5] = { 6, 8 },
		[6] = { 7 },
		[7] = { 8 }
	}

	for idx, point_list in next, connections do
		local fx, fy = unpack(points[idx])
		for _, connecting_point in next, point_list do
			local tx, ty = unpack(points[connecting_point])
			line(fx, fy, tx, ty, r, g, b, a)
		end
	end
end

local flags = {
	['H'] = {0, 1},
	['K'] = {1, 2},
	['HK'] = {2, 4},
	['ZOOM'] = {3, 8},
	['BLIND'] = {4, 16},
	['RELOAD'] = {5, 32},
	['C4'] = {6, 64},
	['VIP'] = {7, 128},
	['DEFUSE'] = {8, 256},
	['FD'] = {9, 512},
	['PIN'] = {10, 1024},
	['HIT'] = {11, 2048},
	['O'] = {12, 4096},
	['X'] = {13, 8192},
	['DEF'] = {17, 131072}
}

local function entity_has_flag(entindex, flag_name)
	if not entindex or not flag_name then
		return false
	end

	local flag_data = flags[flag_name]

	if flag_data == nil then
		return false
	end

	local esp_data = entity.get_esp_data(entindex) or {}

	return bit.band(esp_data.flags or 0, bit.lshift(1, flag_data[1])) == flag_data[2]
end

local new_class = function()
	local mt, mt_data, this_mt = { }, { }, { }

	mt.__metatable = false
	mt_data.struct = function(self, name)
		assert(type(name) == 'string', 'invalid class name')
		assert(rawget(self, name) == nil, 'cannot overwrite subclass')

		return function(data)
			assert(type(data) == 'table', 'invalid class data')
			rawset(self, name, setmetatable(data, {
				__metatable = false,
				__index = function(self, key)
					return
						rawget(mt, key) or
						rawget(this_mt, key)
				end
			}))

			return this_mt
		end
	end

	this_mt = setmetatable(mt_data, mt)

	return this_mt
end

local ctx = new_class()
	:struct 'globals' {
		states = {"stand", "slow walk", "run", "duck", "duck move", "jump", "duck jump", "fakelag", "hideshots"},
		extended_states = {"global", "stand", "slow walk", "run", "duck", "duck move", "jump", "duck jump", "fakelag", "hideshots"},
		teams = {"t", "ct"},
		in_ladder = 0,
		nade = 0,
		resolver_data = {}
	}

	:struct 'ref' {
		aa = {
			enabled = {ui.reference("aa", "anti-aimbot angles", "enabled")},
			pitch = {ui.reference("aa", "anti-aimbot angles", "pitch")},
			yaw_base = {ui.reference("aa", "anti-aimbot angles", "Yaw base")},
			yaw = {ui.reference("aa", "anti-aimbot angles", "Yaw")},
			yaw_jitter = {ui.reference("aa", "anti-aimbot angles", "Yaw Jitter")},
			body_yaw = {ui.reference("aa", "anti-aimbot angles", "Body yaw")},
			freestanding_body_yaw = {ui.reference("aa", "anti-aimbot angles", "Freestanding body yaw")},
			freestand = {ui.reference("aa", "anti-aimbot angles", "Freestanding")},
			roll = {ui.reference("aa", "anti-aimbot angles", "Roll")},
			edge_yaw = {ui.reference("aa", "anti-aimbot angles", "Edge yaw")}
		},
		fakelag = {
			enable = {ui.reference("aa", "fake lag", "enabled")},
			amount = {ui.reference("aa", "fake lag", "amount")},
			variance = {ui.reference("aa", "fake lag", "variance")},
			limit = {ui.reference("aa", "fake lag", "limit")},
		},
		rage = {
			dt = {ui.reference("rage", "aimbot", "Double tap")},
			dt_limit = {ui.reference("rage", "aimbot", "Double tap fake lag limit")},
			fd = {ui.reference("rage", "other", "Duck peek assist")},
			os = {ui.reference("aa", "other", "On shot anti-aim")},
			silent = {ui.reference("rage", "Other", "Silent aim")},
			quickpeek = {ui.reference("RAGE", "Other", "Quick peek assist")},
			quickpeek2 = {ui.reference("RAGE", "Other", "Quick peek assist mode")},
			mindmg = {ui.reference('rage', 'aimbot', 'minimum damage')},
			ovr = {ui.reference('rage', 'aimbot', 'minimum damage override')}
		},
		slow_motion = {ui.reference("aa", "other", "Slow motion")},
	}

	:struct 'ui' {
		menu = {
			global = {},
			aa = {},
			vis = {},
			misc = {},
			cfg = {},
			debug = {}
		},

		execute = function(self)
			local group = pui.group("AA", "anti-aimbot angles")
			local debug_group = pui.group("AA", "Other")

			self.menu.global.label = group:label("\badcbff\bffadb4[V O I D]\n")
			self.menu.global.tab = group:combobox(" \ntab", {"aa", "misc", "vis", "cfg"})

			-- aa
			self.menu.aa.mode = group:combobox("configuration mode", {"preset", "builder"})
			self.menu.aa.preset_list = group:listbox("presets", {"ambani", "STRONK"}):depend({self.menu.aa.mode, "preset"})

			self.menu.aa.state = group:combobox("state", self.globals.extended_states):depend({self.menu.aa.mode, "builder"})
			self.menu.aa.team = group:combobox("\nteam", self.globals.teams):depend({self.menu.aa.mode, "builder"})
      self.menu.aa.space = group:label("\n space builder")

			self.menu.aa.states = {}

			for _, team in ipairs(self.globals.teams) do
				self.menu.aa.states[team] = {}
				for _, state in ipairs(self.globals.extended_states) do
					self.menu.aa.states[team][state] = {}
					local menu = self.menu.aa.states[team][state]

					if state ~= "global" then
						menu.enable = group:checkbox("activate " .. state .. "\n" .. team)
					end

					menu.options = group:multiselect("options" .. "\n" .. state .. team, {'jitter delay', 'customize defensive', 'anti backstab', 'safe head'})
					menu.jitter_delay = group:slider('\n jitter delay slider' .. state .. team, 1, 4, 1, true, 'x', 1, {'Strong'}):depend({menu.options, 'jitter delay'})
					menu.defensive_conditions = group:multiselect("defensive triggers" .. "\n" .. state .. team, {'always', 'on weapon switch', 'on reload', 'on hittable', 'on dormant peek', 'on freestand'}):depend({menu.options, 'customize defensive'})
					menu.defensive_yaw = group:checkbox("defensive yaw" .. "\n" .. state .. team):depend({menu.options, 'customize defensive'})
					menu.defensive_yaw_mode = group:combobox("\ndefensive yaw mode" .. "\n" .. state .. team, {'default', 'custom spin'}):depend({menu.options, 'customize defensive'}, {menu.defensive_yaw, true})
					menu.defensive_freestand = group:checkbox("defensive freestand" .. "\n" .. state .. team):depend({menu.options, 'customize defensive'}, {menu.defensive_yaw, true})

          menu.space = group:label("\n ".. state .. team)

					menu.yaw_base = group:combobox("yaw" .. "\n" .. state .. team, {"local view", "at targets"})
          menu.yaw_jitter = group:combobox("\nyaw jitter" .. "\n" .. state .. team, {"off", "offset", "center", "random", "skitter"})
					menu.yaw_jitter_add = group:slider("\nyaw jitter add" .. state .. team, -180, 180, 0, true, "°", 1):depend({menu.yaw_jitter, "off", true})
					menu.yaw_add = group:slider("yaw add (l)" .. "\n" .. state .. team, -180, 180, 0, true, "°", 1)
					menu.yaw_add_r = group:slider("yaw add (r)" .. "\n" .. state .. team, -180, 180, 0, true, "°", 1)

          menu.space2 = group:label("\n 2".. state .. team)

          menu.desync_mode = group:combobox("desync" .. '\n' .. state .. team, {'gamesense', 'bambani'})
					menu.body_yaw = group:combobox("\n body yaw" .. "\n" .. state .. team, {"off", "static", "opposite", "jitter"})
					menu.body_yaw_side = group:combobox('body yaw side' .. "\n" .. state .. team, {'left', 'right', 'freestanding'}):depend({menu.body_yaw, "static", false})

					for _, v in pairs(menu) do
						local arr =  { {self.menu.aa.state, state}, {self.menu.aa.team, team}, {self.menu.aa.mode, "builder"} }
						if _ ~= "enable" and state ~= "global" then
							arr =  { {self.menu.aa.state, state}, {self.menu.aa.team, team}, {self.menu.aa.mode, "builder"}, {menu.enable, true} }
						end

						v:depend(table.unpack(arr))
						end
					end
			end

			self.menu.aa.space = group:label(" ")
			self.menu.aa.export_from = group:combobox("export:", {"selected state", "selected team"}):depend({self.menu.aa.mode, "builder"})
			self.menu.aa.export_to = group:combobox("to:", {"opposite team", "clipboard"}):depend({self.menu.aa.mode, "builder"})
			self.menu.aa.export = group:button("export", function ()
				local type = "team"
				local team = self.menu.aa.team:get() == "ct" and "t" or "ct"
				if self.menu.aa.export_from:get() == "selected state" then
					type = "state"
				end

				data = self.config:export(type, self.menu.aa.team:get(), self.menu.aa.state:get())

				if self.menu.aa.export_to:get() == "clipboard" then
					clipboard.set(data)
				else
					self.config:import(data, type, team, self.menu.aa.state:get())
				end
			end):depend({self.menu.aa.mode, "builder"})
			self.menu.aa.import = group:button("import", function ()
				local data = clipboard.get()
				local type = data:match("{ambani:(.+)}")
						self.config:import(data, type, self.menu.aa.team:get(), self.menu.aa.state:get())
			end):depend({self.menu.aa.mode, "builder"})

			--misc
			self.menu.misc.freestanding = group:multiselect("freestanding", {"activate disablers", "force static", "force local view"}, 0x0)
			self.menu.misc.freestanding_disablers = group:multiselect("\nfreestanding disablers", self.globals.states):depend({self.menu.misc.freestanding, "activate disablers"})
			self.menu.misc.edge_yaw = group:label("edge yaw", 0x0)
			self.menu.misc.manual_aa = group:checkbox("manual aa")
			self.menu.misc.manual_left = group:hotkey("manual left"):depend({self.menu.misc.manual_aa, true})
			self.menu.misc.manual_right = group:hotkey("manual right"):depend({self.menu.misc.manual_aa, true})
			self.menu.misc.manual_forward = group:hotkey("manual forward"):depend({self.menu.misc.manual_aa, true})
			self.menu.misc.resolver = group:checkbox("activate jitter helper")
			self.menu.misc.resolver_flag = group:checkbox("activate jitter helper flags"):depend({self.menu.misc.resolver, true})
			self.menu.misc.animations = group:checkbox("activate animations")
			self.menu.misc.animations_selector = group:multiselect("animations", {"walk in air", "static legs", "moon walk"}):depend({self.menu.misc.animations, true})
			self.menu.misc.aipeek = group:hotkey("\ac0abffff[debug]\r peek bot")
			self.menu.misc.quickpeekdefault = group:multiselect("\ac0abffff[debug]\r quick peek default settings", {"retreat on shot", "retreat on key release"})
			self.menu.misc.quickpeekmode = group:combobox("\ac0abffff[debug]\r quick peek default mode", {"on hotkey", "toggle"})

			--vis
			self.menu.vis.indicators = group:checkbox("enable indicators", {140, 125, 255})
			
			self.menu.vis.indicatorfont = group:combobox("indicator font", {"small", "normal", "bold"}):depend({self.menu.vis.indicators, true})
			--config
			self.menu.cfg.list = group:listbox("configs", {})
			self.menu.cfg.list:set_callback(function() self.config:update_name() end)
			self.menu.cfg.name = group:textbox("config name")
			self.menu.cfg.save = group:button("save", function() self.config:save() end)
			self.menu.cfg.load = group:button("load", function() self.config:load() end)
			self.menu.cfg.delete = group:button("delete", function() self.config:delete() end)
			self.menu.cfg.export = group:button("export", function() clipboard.set(self.config:export("config")) end)
			self.menu.cfg.import = group:button("import", function() self.config:import(clipboard.get(), "config") end)

			--debug
			self.menu.global.export_preset = debug_group:button("\ac0abffff[debug]\r export current preset", function ()
				local config = pui.setup(self.menu.aa.states)
				local data = config:save()

				local serialized = json.stringify(data)

				clipboard.set(serialized)
			end)

			-- set item dependencies (visibility)
			for tab, arr in pairs(self.menu) do
				if type(arr) == "table" and tab ~= "global" then
					Loop = function (arr, tab)
						for _, v in pairs(arr) do
							if type(v) == "table" then
								if v.__type == "pui::element" then
									v:depend({self.menu.global.tab, tab})
								else
									Loop(v, tab)
								end
							end
						end
					end

					Loop(arr, tab)
				end
			end
			
		end,

		shutdown = function(self)
			self.helpers:menu_visibility(true)
		end
	}

	:struct 'helpers' {
    last_eye_yaw = 0,
		was_in_air = true,
		last_tick = globals.tickcount(),

		contains = function(self, tbl, val)
			for k, v in pairs(tbl) do
				if v == val then
					return true
				end
			end
			return false
		end,

		get_lerp_time = function(self)
			local ud_rate = cvar.cl_updaterate:get_int()
			
			local min_ud_rate = cvar.sv_minupdaterate:get_int()
			local max_ud_rate = cvar.sv_maxupdaterate:get_int()
			
			if (min_ud_rate and max_ud_rate) then
				ud_rate = max_ud_rate
			end

			local ratio = cvar.cl_interp_ratio:get_float()
			
			if (ratio == 0) then
				ratio = 1
			end

			local lerp = cvar.cl_interp:get_float()
			local c_min_ratio = cvar.sv_client_min_interp_ratio:get_float()
			local c_max_ratio = cvar.sv_client_max_interp_ratio:get_float()
			
			if (c_min_ratio and  c_max_ratio and  c_min_ratio ~= 1) then
				ratio = clamp(ratio, c_min_ratio, c_max_ratio)
			end

			return math.max(lerp, (ratio / ud_rate));
		end,

		rgba_to_hex = function(self, r, g, b, a)
			return bit.tohex(
			(math.floor(r + 0.5) * 16777216) + 
			(math.floor(g + 0.5) * 65536) + 
			(math.floor(b + 0.5) * 256) + 
			(math.floor(a + 0.5))
			)
		end,

		easeInOut = function(self, t)
			return (t > 0.5) and 4*((t-1)^3)+1 or 4*t^3;
		end,

		animate_text = function(self, time, string, r, g, b, a)
			local t_out, t_out_iter = { }, 1

			local l = string:len( ) - 1
	
			local r_add = (255 - r)
			local g_add = (255 - g)
			local b_add = (255 - b)
			local a_add = (155 - a)
	
			for i = 1, #string do
				local iter = (i - 1)/(#string - 1) + time
				t_out[t_out_iter] = "\a" .. self:rgba_to_hex( r + r_add * math.abs(math.cos( iter )), g + g_add * math.abs(math.cos( iter )), b + b_add * math.abs(math.cos( iter )), a + a_add * math.abs(math.cos( iter )) )
	
				t_out[t_out_iter + 1] = string:sub( i, i )
	
				t_out_iter = t_out_iter + 2
			end
	
			return t_out
		end,

		clamp = function(self, val, lower, upper)
			assert(val and lower and upper, "not very useful error message here")
			if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
			return math.max(lower, math.min(upper, val))
		end,

		get_damage = function(self)
			local mindmg = ui.get(self.ref.rage.mindmg[1])
			if ui.get(self.ref.rage.ovr[1]) and ui.get(self.ref.rage.ovr[2]) then
				return ui.get(self.ref.rage.ovr[3])
			else
				return mindmg
			end
		end,

		normalize = function(self, angle)
			angle =  angle % 360 
			angle = (angle + 360) % 360
			if (angle > 180)  then
				angle = angle - 360
			end
			return angle
		end,

		fetch_data = function(self, ent)
			return {
				origin = vector(entity.get_origin(ent)), -- +
				vev_velocity = vector(entity.get_prop(ent, "m_vecVelocity")),
				view_offset = entity.get_prop(ent, "m_vecViewOffset[2]"), -- +
				eye_angles = vector(entity.get_prop(ent, "m_angEyeAngles")), -- +
				lowerbody_target = entity.get_prop(ent, "m_flLowerBodyYawTarget"),
				simulation_time = self.helpers:time_to_ticks(entity.get_prop(ent, "m_flSimulationTime")),
				tickcount = globals.tickcount(),
				curtime = globals.curtime(),
				tickbase = entity.get_prop(ent, "m_nTickBase"),
				origin = vector(entity.get_prop(ent, "m_vecOrigin")),
				flags = entity.get_prop(ent, "m_fFlags"),
			}
		end,

		time_to_ticks = function(self, t)
			return math.floor(0.5 + (t / globals.tickinterval()))
		end,

		menu_visibility = function(self, visible)
			for _, v in pairs(self.ref.aa) do
				for _, item in ipairs(v) do
					ui.set_visible(item, visible)
				end
			end
		end,

		in_ladder = function(self)
			local me = entity.get_local_player()

			if entity.is_alive(me) then
				if entity.get_prop(me, "m_MoveType") == 9 then
					self.globals.in_ladder = globals.tickcount() + 8
				end
			else
				self.globals.in_ladder = 0
			end

		end,

		in_air = function(self, ent)
			local flags = entity.get_prop(ent, "m_fFlags")
			return bit.band(flags, 1) == 0
		end,

		in_duck = function(self, ent)
			local flags = entity.get_prop(ent, "m_fFlags")
			return bit.band(flags, 4) == 4
		end,

    get_eye_yaw = function (self, ent)
      if ent == nil then
        return
      end

      local player_ptr = get_client_entity(ientitylist, ent)
      if player_ptr == nil then
        return
      end

      if globals.chokedcommands() == 0 then
	      self.last_eye_yaw = ffi.cast("float*", ffi.cast("char*", ffi.cast("void**", ffi.cast("char*", player_ptr) + 0x9960)[0]) + 0x78)[0]
      end

      return self.last_eye_yaw
    end,

    get_closest_angle = function(self, max, min, dir, ang)
      -- Calculate the absolute angular difference between d and a, b, and c
      max = self.helpers:normalize(max)
      min = self.helpers:normalize(min)
      dir = self.helpers:normalize(dir)
      ang = self.helpers:normalize(ang)

      --check if ang is between max and min and also in the same side as dir
      local diff_maxang = math.abs((max - ang + 180) % 360 - 180)
      local diff_minang = math.abs((min - ang + 180) % 360 - 180)
      local diff_maxdir = math.abs((max - dir + 180) % 360 - 180)
      local diff_mindir = math.abs((min - dir + 180) % 360 - 180)
      local diff_minmax = math.abs((min - max + 180) % 360 - 180)

      local ang_side = diff_maxang > diff_minmax or diff_minang > diff_minmax

      local dir_side = diff_maxdir > diff_minmax or diff_mindir > diff_minmax

      if dir_side ~= ang_side then
        if diff_minang < diff_maxang then
          return 0
        else
          return 1
        end
        return
      end

      return 2
    end,

		get_freestanding_side = function(self, data)
			local me = entity.get_local_player()
			local target = client.current_threat()
			local _, yaw = client.camera_angles()
			local pos = vector(client.eye_position())

      if not target then
        return 2
      end
			
			_, yaw = (pos - vector(entity.get_origin(target))):angles()
			
			local yaw_offset = data.offset
			local yaw_jitter_type = string.lower(data.type)
			local yaw_jitter_amount = data.value
			
			local offset = math.abs(yaw_jitter_amount)
			
			if yaw_jitter_type == 'skitter' then
				offset = math.abs(yaw_jitter_amount) + 33
			elseif yaw_jitter_type == 'offset' then
				offset = math.max(0, yaw_jitter_amount)
			elseif yaw_jitter_type == 'center' then
				offset = math.abs(yaw_jitter_amount)/2
			end
			
			local max_yaw = self.helpers:normalize(yaw + yaw_offset + offset)
			
			local min_offset = offset
			if yaw_jitter_type == 'offset' then
				min_offset = math.abs(math.min(0, yaw_jitter_amount))
			end
			
			local min_yaw = self.helpers:normalize(yaw + yaw_offset - min_offset)
			
			local current_yaw = self:get_eye_yaw(me)

      local left_offset = max_yaw - current_yaw
      local right_offset = min_yaw - current_yaw

      local closest = self:get_closest_angle(min_yaw, max_yaw, yaw, current_yaw)
			
      return closest
		end,

		get_state = function(self)
			local me = entity.get_local_player()
			local velocity = vector(entity.get_prop(me, "m_vecVelocity")):length2d()
			local duck = self:in_duck(me) or ui.get(self.ref.rage.fd[1])

			local state = velocity > 1.5 and "run" or "stand"
			
			if self:in_air(me) or self.was_in_air then
				state = duck and "duck jump" or "jump"
			elseif velocity > 1.5 and duck then
				state = "duck move"
			elseif ui.get(self.ref.slow_motion[1]) and ui.get(self.ref.slow_motion[2]) then
				state = "slow walk"
			elseif duck then
				state = "duck"
			end
			if globals.tickcount() ~= self.last_tick then
				self.was_in_air = self:in_air(me)
				self.last_tick = globals.tickcount()
			end
			return state
		end,

		get_team = function(self)
			local me = entity.get_local_player()
			local index = entity.get_prop(me, "m_iTeamNum")

			return index == 2 and "t" or "ct"
		end,

		loop = function (arr, func)
			if type(arr) == "table" and arr.__type == "pui::element" then
				func(arr)
			else
				for k, v in pairs(arr) do
					loop(v, func)
				end
			end
		end,

		get_charge = function ()
			local me = entity.get_local_player()
			local simulation_time = entity.get_prop(entity.get_local_player(), "m_flSimulationTime")
			return (globals.tickcount() - simulation_time/globals.tickinterval())
		end,
	}

	:struct 'config' {
		configs = {},

		write_file = function (self, path, data)
			if not data or type(path) ~= "string" then
				return
			end

			return writefile(path, json.stringify(data))
		end,

		update_name = function (self)
			local index = self.ui.menu.cfg.list()
			local i = 1

			for k, v in pairs(self.configs) do
				if index == i or index == 0 then
					return self.ui.menu.cfg.name(k)
				end
				i = i + 1
			end
		end,

		update_configs = function (self)
			local names = {}
			for k, v in pairs(self.configs) do
				table.insert(names, k)
			end
			
			if #names > 0 then
				self.ui.menu.cfg.list:update(names)
			end
			self:write_file("ambani_configs.txt", self.configs)
			self:update_name()
		end,

		setup = function (self)
			local data = readfile('ambani_configs.txt')
			if data == nil then
				self.configs = {}
				return
			end

			self.configs = json.parse(data)

			self:update_configs()

			self:update_name()
		end,

		export_config = function(self, ...)
			local config = pui.setup({self.ui.menu.global, self.ui.menu.aa, self.ui.menu.misc, self.ui.menu.vis})

			local data = config:save()
			local encrypted = base64.encode( json.stringify(data) )

			return encrypted
		end,

		export_state = function (self, team, state)
			local config = pui.setup({self.ui.menu.aa.states[team][state]})

			local data = config:save()
			local encrypted = base64.encode( json.stringify(data) )

			return encrypted
		end,

		export_team = function (self, team)
			local config = pui.setup({self.ui.menu.aa.states[team]})

			local data = config:save()
			local encrypted = base64.encode( json.stringify(data) )

			return encrypted
		end,

		export = function (self, type, ...)
			local success, result = pcall(self['export_' .. type], self, ...)
			if not success then
				print(result)
				return
			end

			return "{ambani:" .. type .. "}:" .. result
		end,

		import_config = function (self, encrypted)
			local data = json.parse(base64.decode(encrypted))

			local config = pui.setup({self.ui.menu.global, self.ui.menu.aa, self.ui.menu.misc, self.ui.menu.vis})
			config:load(data)
		end,

		import_state = function (self, encrypted, team, state)
			local data = json.parse(base64.decode(encrypted))

			local config = pui.setup({self.ui.menu.aa.states[team][state]})
			config:load(data)
		end,

		import_team = function (self, encrypted, team)
			local data = json.parse(base64.decode(encrypted))

			local config = pui.setup({self.ui.menu.aa.states[team]})
			config:load(data)
		end,

		import = function (self, data, type, ...)
			local name = data:match("{ambani:(.+)}")
			if not name or name ~= type then
				return error('This is not valid ambani data. 1')
			end

			local success, err = pcall(self['import_'..name], self, data:gsub("{ambani:" .. name .. "}:", ""), ...)
			if not success then
				print(err)
				return error('This is not valid ambani data. 2')
			end
		end,

		save = function (self)
			local name = self.ui.menu.cfg.name()
			if name:match("%w") == nil then
				return print("Invalid config name")
			end

			local data = self:export("config")

			self.configs[name] = data

			self:update_configs()
		end,

		load = function (self)
			local name = self.ui.menu.cfg.name()
			local data = self.configs[name]
			if not data then
				return print("Invalid config name")
			end

			self:import(data, "config")
		end,

		delete = function(self)
			local name = self.ui.menu.cfg.name()
			local data = self.configs[name]
			if not data then
				return print("Invalid config name")
			end

			self.configs[name] = nil

			self:update_configs()
		end,


	}
	
	:struct 'prediction' {
		run = function (self, ent, ticks)
			local origin = vector(entity.get_origin(ent))
			local velocity = vector(entity.get_prop(ent, 'm_vecVelocity'))
			velocity.z = 0
			local predicted = origin + velocity * globals.tickinterval() * ticks
			
			return {
				origin = predicted
			}
		end
	}

	:struct 'fakelag' {
		send_packet = true,

		get_limit = function (self)
			if not ui.get(self.ref.fakelag.enable[1]) then
				return 1
			end

			local limit = ui.get(self.ref.fakelag.limit[1])
			local charge = self.helpers:get_charge()

      local dt = ui.get(self.ref.rage.dt[1]) and ui.get(self.ref.rage.dt[2])
      local os = ui.get(self.ref.rage.os[1]) and ui.get(self.ref.rage.os[2])

			if (dt or os) and not ui.get(self.ref.rage.fd[1]) then
				if charge > 0 then
					limit = 1
				else
					limit = ui.get(self.ref.rage.dt_limit[1])
				end
			end
			
			return limit
		end,

		run = function (self, cmd)
			local limit = self:get_limit()

			if cmd.chokedcommands < limit and (not cmd.no_choke or (cmd.chokedcommands == 0 and limit == 1)) then
				self.send_packet = false
				cmd.no_choke = false
			else
				cmd.no_choke = true
				self.send_packet = true
			end

			cmd.allow_send_packet = self.send_packet

			return self.send_packet
		end
	}

	:struct 'desync' {
		switch_move = true,

		get_yaw_base = function (self, base)
			local threat = client.current_threat()
			local _, yaw = client.camera_angles()
			if base == "at targets" and threat then
				local pos = vector(entity.get_origin(entity.get_local_player()))
				local epos = vector(entity.get_origin(threat))
		
				_, yaw = pos:to(epos):angles()
			end
		
			return yaw
		end,

		do_micromovements = function(self, cmd, send_packet)
			local me = entity.get_local_player()
			local speed = 1.01
			local vel = vector(entity.get_prop(me, "m_vecVelocity")):length2d()

			if vel > 3 then
				return
			end

			if self.helpers:in_duck(me) or ui.get(self.ref.rage.fd[1]) then
				speed = speed * 2.94117647
			end

			self.switch_move = self.switch_move or false

			if self.switch_move then
				cmd.sidemove = cmd.sidemove + speed
			else
				cmd.sidemove = cmd.sidemove - speed
			end

			self.switch_move = not self.switch_move
		end,

		can_desync = function (self, cmd)
			local me = entity.get_local_player()

			if cmd.in_use == 1 then
				return false
			end
			local weapon_ent = entity.get_player_weapon(me)

			if cmd.in_attack == 1 then
				local weapon = entity.get_classname(weapon_ent)

				if weapon == nil then
					return false
				end
          if weapon:find("Grenade") or weapon:find('Flashbang') then
            self.globals.nade = globals.tickcount()
				  else
					if math.max(entity.get_prop(weapon_ent, "m_flNextPrimaryAttack"), entity.get_prop(me, "m_flNextAttack")) - globals.tickinterval() - globals.curtime() < 0 then
						return false
					end
				end
			end
			local throw = entity.get_prop(weapon_ent, "m_fThrowTime")

			if self.globals.nade + 15 == globals.tickcount() or (throw ~= nil and throw ~= 0) then 
        return false 
      end
			if entity.get_prop(entity.get_game_rules(), "m_bFreezePeriod") == 1 then
				return false
			end
		
			if entity.get_prop(me, "m_MoveType") == 9 or self.globals.in_ladder > globals.tickcount() then
				return false
			end
			if entity.get_prop(me, "m_MoveType") == 10 then
				return false
			end
		
			return true
		end,

		run = function (self, cmd, send_packet, data)
			if not self:can_desync(cmd) then
				return
			end

			self:do_micromovements(cmd, send_packet)

			local yaw = self:get_yaw_base(data.base)

			if send_packet then
				cmd.pitch = data.pitch or 88.9
				cmd.yaw = yaw + 180 + data.offset
			else
				cmd.pitch = 88.9
				cmd.yaw = yaw + 180 + data.offset + (data.side == 2 and 0 or (data.side == 0 and 120 or -120))
			end
		end
	}

	:struct 'antiaim' {
		side = 0,
		last_rand = 0,
		skitter_counter = 0,
		last_skitter = 0,
		last_count = 0,
		cycle = 0,

		manual_side = 0,
    freestanding_side = 0,

		anti_backstab = function (self)
			local me = entity.get_local_player()
			local target = client.current_threat()
			if not target then
				return false
			end

			local weapon_ent = entity.get_player_weapon(target)

			if not weapon_ent then
				return false
			end

			local weapon_name = entity.get_classname(weapon_ent)

			if not weapon_name:find('Knife') then
				return false
			end

			local lpos = vector(entity.get_origin(me))
			local epos = vector(entity.get_origin(target))

			local predicted = self.prediction:run(target, 16)

			return epos:dist2d(lpos) < 128 or predicted.origin:dist2d(lpos) < 128
		end,

		calculate_additional_states = function (self, team, state)
			local dt = (ui.get(self.ref.rage.dt[1]) and ui.get(self.ref.rage.dt[2]))
			local os = (ui.get(self.ref.rage.os[1]) and ui.get(self.ref.rage.os[2]))
			local fd = ui.get(self.ref.rage.fd[1])

			if self.ui.menu.aa.states[team]['fakelag'].enable() and ((not dt and not os) or fd) then
				state = 'fakelag'
			end

			if self.ui.menu.aa.states[team]['hideshots'].enable() and os and not dt and not fd then
				state = 'hideshots'
			end

			return state
		end,

		get_best_side = function (self, opposite)
			local me = entity.get_local_player()
			local eye = vector(client.eye_position())
			local target = client.current_threat()
			local _, yaw = client.camera_angles()

			local epos
			if target then
				epos = vector(entity.get_origin(target)) + vector(0,0,64)
				_, yaw = (epos - eye):angles()
			end

			local angles = {60,45,30,-30,-45,-60}
			local data = {left = 0, right = 0}

			for _, angle in ipairs(angles) do
				local forward = vector():init_from_angles(0, yaw + 180 + angle, 0)

				if target then
					local vec = eye + forward:scaled(128)
					local _, dmg = client.trace_bullet(target, epos.x, epos.y, epos.z, vec.x, vec.y, vec.z, me)
					data[angle < 0 and 'left' or 'right'] = data[angle < 0 and 'left' or 'right'] + dmg
				else
					local vec = eye + forward:scaled(8192)
					local fraction = client.trace_line(me, eye.x, eye.y, eye.z, vec.x, vec.y, vec.z)
					data[angle < 0 and 'left' or 'right'] = data[angle < 0 and 'left' or 'right'] + fraction
				end
			end

			if data.left == data.right then
				return 2
			elseif data.left > data.right then
				return opposite and 1 or 0
			else
				return opposite and 0 or 1
			end
		end,

		get_manual = function (self)
			local me = entity.get_local_player()

			local left = self.ui.menu.misc.manual_left:get()
			local right = self.ui.menu.misc.manual_right:get()
			local forward = self.ui.menu.misc.manual_forward:get()

			if self.last_forward == nil then
				self.last_forward, self.last_right, self.last_left = forward, right, left
			end

			if left ~= self.last_left then
				if self.manual_side == 1 then
					self.manual_side = nil
				else
					self.manual_side = 1
				end
			end

			if right ~= self.last_right then
				if self.manual_side == 2 then
					self.manual_side = nil
				else
					self.manual_side = 2
				end
			end

			if forward ~= self.last_forward then
				if self.manual_side == 3 then
					self.manual_side = nil
				else
					self.manual_side = 3
				end
			end

			self.last_forward, self.last_right, self.last_left = forward, right, left

			if not self.manual_side then
				return
			end

			return ({-90, 90, 180})[self.manual_side]
		end,

		run = function (self, cmd)
			local me = entity.get_local_player()

			if not entity.is_alive(me) then
				return
			end

			local state = self.helpers:get_state()
			local team = self.helpers:get_team()
			state = self:calculate_additional_states(team, state)

			if self.ui.menu.aa.mode() == "builder" then
				self:set_builder(cmd, state, team)
			else
				self:set_preset(cmd, state, team)
			end

		end,

		set_builder = function (self, cmd, state, team)
			if not self.ui.menu.aa.states[team][state].enable() then
				state = "global"
			end
		
			local data = {}

			for k, v in pairs(self.ui.menu.aa.states[team][state]) do
				data[k] = v()
			end
			
			self:set(cmd, data)
		end,

		set_preset = function (self, cmd, state, team)
			local preset = self.ui.menu.aa.preset_list:get()

			local presets = {
				[0] = function ()
					local preset_data = json.parse(global_data_saved_somewhere)

					if not preset_data[team][state].enable then
						state = "global"
					end

					local data = {}

					for k, v in pairs(preset_data[team][state]) do
						data[k] = v
					end
				
					self:set(cmd, data)
				end,
				[1] = function ()
					local preset_data = json.parse(global_data_saved_somewhere2)

					if not preset_data[team][state].enable then
						state = "global"
					end

					local data = {}

					for k, v in pairs(preset_data[team][state]) do
						data[k] = v
					end
				
					self:set(cmd, data)
				end

			}

			return presets[preset](cmd)
		end,

		airtick = function(self, cmd)
			cmd.force_defensive = true
		end, 

		animations = function(self)
			local me = entity.get_local_player()

			if not entity.is_alive(me) then
				return
			end

			local self_index = entity_lib.new(me)
			local self_anim_overlay = self_index:get_anim_overlay(6)
			
			if not self_anim_overlay then
				return
			end

			local x_velocity = entity.get_prop(me, "m_flPoseParameter", 7)
			local state = self.helpers:get_state()

			if string.find(state, "jump") and self.helpers:contains(self.ui.menu.misc.animations_selector:get(), "walk in air") then
				self_anim_overlay.weight = 1
				self_anim_overlay.cycle = 0
			end

			if self.helpers:contains(self.ui.menu.misc.animations_selector:get(), "moon walk") then
				self_anim_overlay.cycle = 0.5
			end

			if self.helpers:contains(self.ui.menu.misc.animations_selector:get(), "static legs") then
				entity.set_prop(me, "m_flPoseParameter", 1, 6) 
			end
		end,

		get_defensive = function (self, conditions, state)
			local target = client.current_threat()
			local me = entity.get_local_player()
			if self.helpers:contains(conditions, 'always') then
				return true
			end

			if self.helpers:contains(conditions, 'on weapon switch') then
				local next_attack = entity.get_prop(me, 'm_flNextAttack') - globals.curtime()
				if next_attack / globals.tickinterval() > self.defensive.defensive + 2 then
					return true
				end
			end

			if self.helpers:contains(conditions, 'on reload') then
				local weapon = entity.get_player_weapon(me)
				if weapon then
					local next_attack = entity.get_prop(me, 'm_flNextAttack') - globals.curtime()
					local next_primary_attack = entity.get_prop(weapon, 'm_flNextPrimaryAttack') - globals.curtime()

					if next_attack > 0 and next_primary_attack > 0 and next_attack * globals.tickinterval() > self.defensive.defensive then
						return true
					end
				end
			end

			if self.helpers:contains(conditions, 'on hittable') and entity_has_flag(target, 'HIT') then
				return true
			end

			if self.helpers:contains(conditions, 'on dormant peek') and target then
				local weapon_ent = entity.get_player_weapon(target)
				if entity.is_dormant(target) and weapon_ent then
					if entity_has_flag(me, 'HIT') then
						return true
					end

					local weapon = csgo_weapons(weapon_ent)

					local predicted = self.prediction:run(me, 14).origin
					local origin = vector(entity.get_origin(me))
					
					local offset = predicted - origin
					local biggest_damage = 0

					for i = 2, 8 do
						local to = vector(entity.hitbox_position(me, i)) + offset
						local from = vector(entity.get_origin(target)) + vector(0,0, 64)

						local _, dmg = client.trace_bullet(target, from.x, from.y, from.z, to.x, to.y, to.z, target)

						if dmg > biggest_damage then
							biggest_damage = dmg
						end
					end

					if biggest_damage > weapon.damage / 3 then
						return true
					end
				end
			end

			if self.helpers:contains(conditions, 'on freestand') and self.ui.menu.misc.freestanding:get_hotkey() and not (self.ui.menu.misc.freestanding:get('activate disablers') and self.ui.menu.misc.freestanding_disablers:get(state)) then
				return true
			end
		end,

		set = function (self, cmd, data)
      local state = self.helpers:get_state()
			local delay = {math.random(1, math.random(3, 4)), 2, 4, 5}
			local manual = self:get_manual()
			local delayed = true

			if not self.helpers:contains(data.options, 'jitter delay') then
				delay[data.jitter_delay] = 1
			end

      if globals.chokedcommands() == 0 and self.cycle == delay[data.jitter_delay] then
        delayed = false
        self.side = self.side == 1 and 0 or 1
      end

			local best_side = self:get_best_side()
      local side = self.side
      local body_yaw = data.body_yaw
      local pitch = 'default'

      if body_yaw == "jitter" then
        body_yaw = "static"
      else
        if data.body_yaw_side == "left" then
          side = 1
        elseif data.body_yaw_side == "right" then
          side = 0
        else
          side = best_side
        end
      end

			
			local yaw_offset = 0
      if data.yaw_jitter == 'offset' then
        if self.side == 1 then
        yaw_offset = yaw_offset + data.yaw_jitter_add
        end
      elseif data.yaw_jitter == 'center' then
        yaw_offset = yaw_offset + (self.side == 1 and data.yaw_jitter_add/2 or -data.yaw_jitter_add/2)
      elseif data.yaw_jitter == 'random' then
        local rand = (math.random(0, data.yaw_jitter_add) - data.yaw_jitter_add/2)
        if not delayed then
          yaw_offset = yaw_offset + rand

          self.last_rand = rand
        else
          yaw_offset = yaw_offset + self.last_rand
        end
      elseif data.yaw_jitter == 'skitter' then
        local sequence = {0, 2, 1, 0, 2, 1, 0, 1, 2, 0, 1, 2, 0, 1, 2}

        local next_side
        if self.skitter_counter == #sequence then
          self.skitter_counter = 1
      	elseif not delayed then
          self.skitter_counter = self.skitter_counter + 1
        end

        next_side = sequence[self.skitter_counter]

        self.last_skitter = next_side

        if data.body_yaw == "jitter" then
          side = next_side
        end

        if next_side == 0 then
          yaw_offset = yaw_offset - 16 - math.abs(data.yaw_jitter_add)/2
        elseif next_side == 1 then
          yaw_offset = yaw_offset + 16 + math.abs(data.yaw_jitter_add)/2
        end
      end

      yaw_offset = yaw_offset + (side == 0 and data.yaw_add_r or (side == 1 and data.yaw_add or 0))

			if self.helpers:contains(data.options, 'customize defensive') and self:get_defensive(data.defensive_conditions, state) then
				cmd.force_defensive = true
			end

			ui.set(self.ref.aa.freestand[1], false)
			ui.set(self.ref.aa.edge_yaw[1], self.ui.menu.misc.edge_yaw:get_hotkey())
			ui.set(self.ref.aa.freestand[2], 'Always on')

			if self.helpers:contains(data.options, 'safe head') then
				local me = entity.get_local_player()
				local target = client.current_threat()
				if target then
					local weapon = entity.get_player_weapon(me)
					if weapon and (entity.get_classname(weapon):find('Knife') or entity.get_classname(weapon):find('Taser')) then
						yaw_offset = 0
						side = 2
					end
				end
			end

			if manual then
				yaw_offset = manual
			elseif self.ui.menu.misc.freestanding:get_hotkey() and not (self.ui.menu.misc.freestanding:get('activate disablers') and self.ui.menu.misc.freestanding_disablers:get(state)) then
        data.desync_mode = 'gamesense'
        ui.set(self.ref.aa.freestand[1], true)

			  if self.ui.menu.misc.freestanding:get("force static") then
			  	yaw_offset = 0
			  	side = 0
			  end
      elseif self.helpers:contains(data.options, 'anti backstab') and self:anti_backstab() then
				yaw_offset = yaw_offset + 180
			end

			local defensive = self.defensive.ticks * self.defensive.defensive > 0 and math.max(self.defensive.defensive, self.defensive.ticks) or 0

			if data.defensive_yaw and self.helpers:contains(data.options, 'customize defensive') then
				local defensive_freestand = false

				if data.defensive_freestand and ui.get(self.ref.aa.freestand[1]) then
					if defensive == 1 then
      		  self.freestanding_side = self.helpers:get_freestanding_side({
      		    offset = 0,
      		    type = data.yaw_jitter,
      		    value = data.yaw_jitter_add,
      		    base = data.yaw_base
      		  })
      		end

					if self.freestanding_side ~= 2 then
						defensive_freestand = true
					
        	  if defensive > 0 then
        	    yaw_offset = yaw_offset + (self.freestanding_side == 1 and 120 or -120)
        	    pitch = 0
        	    ui.set(self.ref.aa.freestand[1], false)
        	  end
					end
				end
				
				if data.defensive_yaw_mode == 'default' and defensive > 0 and not defensive_freestand then
					yaw_offset = (side == 1) and 120 or -120 + math.random(-20, 20)
					pitch = -87
				elseif data.defensive_yaw_mode == 'custom spin' and defensive > 0 then
					yaw_offset = math.abs(yaw_offset) + defensive * (360 - math.abs(yaw_offset) * 2)/14
					pitch = 0
				end
			end

      if data.desync_mode == 'gamesense' then
        ui.set(self.ref.aa.enabled[1], true)
        ui.set(self.ref.aa.pitch[1], pitch == 'default' and pitch or 'custom')
        ui.set(self.ref.aa.pitch[2], type(pitch) == "number" and pitch or 0)
        ui.set(self.ref.aa.yaw_base[1], data.yaw_base)
        ui.set(self.ref.aa.yaw[1], 180)
        ui.set(self.ref.aa.yaw[2], self.helpers:normalize(yaw_offset))
        ui.set(self.ref.aa.yaw_jitter[1], 'off')
        ui.set(self.ref.aa.yaw_jitter[2], 0)
        ui.set(self.ref.aa.body_yaw[1], body_yaw)
        ui.set(self.ref.aa.body_yaw[2], (side == 2) and 0 or (side == 1 and 90 or -90))
			elseif data.desync_mode == 'bambani' then
        local send_packet = self.fakelag:run(cmd)

        if pitch == 'default' then
          pitch = nil
        end
        
        self.desync:run(cmd, send_packet, {
          pitch = pitch,
          base = data.yaw_base,
          side = side,
          offset = yaw_offset,
        })
      end

      self.last_count = globals.tickcount()

      if globals.chokedcommands() == 0 then
      	if self.cycle >= delay[data.jitter_delay] then
        self.cycle = 1
        else
        	self.cycle = self.cycle + 1
        end
      end
            
    end,
	}

	:struct 'resolver' {
		state = {},
		counter = {},
		jitterhelper = function(self)
			if self.ui.menu.misc.resolver() then
				local players = entity.get_players(true)      
				if #players == 0 then
					return
				end
				resolver_status = self.ui.menu.misc.resolver_flag()
				for _, i in next, players do

					local target = i
					if self.globals.resolver_data[target] == nil then
						local data = self.helpers:fetch_data(target)
						self.globals.resolver_data[target] = {
							current = data,
							last_valid_record = data
						}
					else
						local simulation_time = self.helpers:time_to_ticks(entity.get_prop(target, "m_flSimulationTime"))
						if simulation_time ~= self.globals.resolver_data[target].current.simulation_time then
							table.insert(self.globals.resolver_data[target], 1, self.globals.resolver_data[target].current)
							local data = self.helpers:fetch_data(target)
							if simulation_time - self.globals.resolver_data[target].current.simulation_time >= 1 then
								self.globals.resolver_data[target].last_valid_record = data
							end
							self.globals.resolver_data[target].current = data
							for i = #self.globals.resolver_data[target], 1, -1 do
								if #self.globals.resolver_data[target] > 16 then 
									table.remove(self.globals.resolver_data[target], i)
								end
							end
						end
					end

					if self.globals.resolver_data[target][1] == nil or self.globals.resolver_data[target][2] == nil or self.globals.resolver_data[target][3] == nil or self.globals.resolver_data[target][6] == nil or self.globals.resolver_data[target][7] == nil then
						return
					end
					
					local yaw_delta = self.helpers:normalize(self.globals.resolver_data[target].current.eye_angles.y - self.globals.resolver_data[target][1].eye_angles.y)
					local yaw_delta2 = self.helpers:normalize(self.globals.resolver_data[target][2].eye_angles.y - self.globals.resolver_data[target][3].eye_angles.y)
					local yaw_delta3 = self.helpers:normalize(self.globals.resolver_data[target][6].eye_angles.y - self.globals.resolver_data[target][7].eye_angles.y)

					if math.abs(yaw_delta) >= 33 then
						self.globals.resolver_data[target].lastyawupdate = globals.tickcount() + 10
						self.globals.resolver_data[target].side = yaw_delta
					end

					if self.globals.resolver_data[target].lastyawupdate == nil then self.globals.resolver_data[target].lastyawupdate = 0 end
					if self.globals.resolver_data[target].lastplistupdate == nil then self.globals.resolver_data[target].lastplistupdate = 0 end
					if self.globals.resolver_data[target].skitterupdate == nil then self.globals.resolver_data[target].skitterupdate = 0 end

					if math.abs(yaw_delta2 - yaw_delta3) > 90 then
						self.globals.resolver_data[target].skitterupdate = globals.tickcount() + 10
					end
					if self.globals.resolver_data[target].skitterupdate - globals.tickcount() > 0 then
						self.state[target] = "SKITTER"
						resolver_flag[target] = "SKITTER"
						if math.abs(yaw_delta2 - yaw_delta3) == 0 then
							plist.set(target, "Force body yaw value", 0)
						else
							plist.set(target, "Force body yaw value", (yaw_delta) > 0 and 60 or -60)
						end
					elseif self.globals.resolver_data[target].lastyawupdate > globals.tickcount() and yaw_delta == 0 and self.globals.resolver_data[target].skitterupdate - globals.tickcount() < 0 then
						plist.set(target, "Force body yaw", true)
						plist.set(target, "Force body yaw value", (self.globals.resolver_data[target].side) > 0 and 60 or -60)
						self.globals.resolver_data[target].lastplistupdate = globals.tickcount() + 10
						self.state[target] = "CENTER"
						resolver_flag[target] = "JITTER"
					elseif math.abs(yaw_delta) >= 33 then
						plist.set(target, "Force body yaw", true)
						plist.set(target, "Force body yaw value", (yaw_delta) > 0 and 60 or -60)
						self.state[target] = "CENTER"
						resolver_flag[target] = "JITTER"
						self.globals.resolver_data[target].lastplistupdate = globals.tickcount() + 10
					elseif self.globals.resolver_data[target].lastplistupdate < globals.tickcount() then
						plist.set(target, "Force body yaw", false)
						self.state[target] = ""
						resolver_flag[target] = ""
					else
						plist.set(target, "Force body yaw", false)
						self.state[target] = ""
						resolver_flag[target] = ""
					end

				end

			end

		end,
	}

	:struct 'net_channel' {
		run = function (self)
			local me = entity.get_local_player()
			if not entity.is_alive(me) then
				return
			end

			local net_channel = entity.get_prop(me, "m_hNetworkedSequence")
			if net_channel then
				self.globals.net_channel = net_channel
			end
		end
	}

	:struct 'defensive' {
		ticks = 0,
		defensive = 0,

		run = function (self, cmd)
			if cmd.force_defensive then
				self.ticks = self.ticks + 1
				self.defensive = self.defensive + 1
			else
				self.ticks = 0
				self.defensive = 0
			end
		end
	}

	:struct 'predict' {
		run = function (self, cmd)
			local me = entity.get_local_player()
			if not entity.is_alive(me) then
				return
			end

			local weapon = entity.get_player_weapon(me)
			if not weapon then
				return
			end

			local weapon_name = entity.get_classname(weapon)
			if not weapon_name then
				return
			end

			if weapon_name:find('Knife') or weapon_name:find('Taser') then
				return
			end

			local target = client.current_threat()
			if not target then
				return
			end

			local predicted = self.prediction:run(target, 16)
			local origin = vector(entity.get_origin(me))
			local epos = vector(entity.get_origin(target))

			if predicted.origin:dist2d(origin) < epos:dist2d(origin) then
				cmd.force_defensive = true
			end
		end
	}

	:struct 'peekbot' {
		run = function (self, cmd)
			if not self.ui.menu.misc.peekbot:get() then
				return
			end

			local me = entity.get_local_player()
			if not entity.is_alive(me) then
				return
			end

			local target = client.current_threat()
			if not target then
				return
			end

			local weapon = entity.get_player_weapon(me)
			if not weapon then
				return
			end

			local weapon_name = entity.get_classname(weapon)
			if not weapon_name then
				return
			end

			if weapon_name:find('Knife') or weapon_name:find('Taser') then
				return
			end

			local predicted = self.prediction:run(target, 16)
			local origin = vector(entity.get_origin(me))
			local epos = vector(entity.get_origin(target))

			if predicted.origin:dist2d(origin) < epos:dist2d(origin) then
				cmd.force_defensive = true
			end
		end
	}

	:struct 'visuals' {
		run = function (self)
			if not self.ui.menu.visuals.enable() then
				return
			end

			local players = entity.get_players(true)
			if #players == 0 then
				return
			end

			for _, player in ipairs(players) do
				if not entity.is_alive(player) then
					continue
				end

				local x, y, w, h = entity.get_bounding_box(player)
				if not x then
					continue
				end

				local color = self.ui.menu.visuals.color()
				local r, g, b, a = color.r, color.g, color.b, color.a

				if self.ui.menu.visuals.box() then
					renderer.rectangle(x, y, w, h, r, g, b, a)
				end

				if self.ui.menu.visuals.name() then
					local name = entity.get_player_name(player)
					renderer.text(x + w/2, y - 12, 255, 255, 255, 255, 'c', 0, name)
				end

				if self.ui.menu.visuals.health() then
					local health = entity.get_prop(player, "m_iHealth")
					local health_color = health > 50 and {255, 255, 0, 255} or {255, 0, 0, 255}
					renderer.text(x - 5, y, health_color[1], health_color[2], health_color[3], health_color[4], 'r', 0, tostring(health))
				end
			end
		end
	}
}

-- Event callbacks
client.set_event_callback('load', function()
	ctx:init()
end)

client.set_event_callback('setup_command', function(cmd)
	ctx.antiaim:run(cmd)
	ctx.fakelag:run(cmd)
	ctx.defensive:run(cmd)
	ctx.predict:run(cmd)
	ctx.peekbot:run(cmd)
	ctx.antiaim:animations()
end)

client.set_event_callback('shutdown', function()
	ctx:shutdown()
end)

client.set_event_callback('run_command', function(cmd)
	ctx.net_channel:run()
end)

client.set_event_callback('paint', function()
	ctx.visuals:run()
end)

client.set_event_callback('paint_ui', function()
	ctx.ui:run()
end)

client.set_event_callback('pre_render', function()
	ctx.antiaim:airtick()
end)

client.set_event_callback('predict_command', function(cmd)
	ctx.resolver:jitterhelper()
end)

client.set_event_callback('level_init', function()
	ctx.globals.resolver_data = {}
end)

client.set_event_callback('net_update_start', function()
	ctx.resolver:jitterhelper()
end)

client.set_event_callback('net_update_end', function()
	ctx.resolver:jitterhelper()
end)

-- Register ESP flag for resolver
client.register_esp_flag('VOID', 255, 255, 255, function(player)
	return resolver_flag[player] or ''
end)