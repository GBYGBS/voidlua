-- =====================================================
-- CORE DEPENDENCIES
-- =====================================================

local ffi = require("ffi")
local bit = require("bit")
local vector = require("vector")

-- Global objects
local client = client
local entity = entity
local globals = globals
local plist = plist
local ui = ui
local cvar = cvar

-- Gamesense modules
local csgo_weapons = safe and safe:require('gamesense/csgo_weapons') or nil
local antiaim_funcs = require("gamesense/antiaim_funcs")

-- UI References
local on_shot_anti_aim_ref, on_shot_anti_aim_hotkey_ref = ui.reference("AA", "Other", "On shot anti-aim")
local fake_duck_ref = ui.reference("RAGE", "Other", "Duck peek assist")
local minimum_hitchance_ref = ui.reference("RAGE", "Aimbot", "Minimum hit chance")

-- =====================================================
-- GAME ENHANCER FEATURE (FROM EMBERLASH)
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
            -- print("[Game Enhancer] Disabled - Resetting all CVars to defaults")
            for name, data in pairs(fps_cvars) do
                local cvar_name, boost_value, default_value = unpack(data)
                local success, err = pcall(function() cvar[cvar_name]:set_int(default_value) end)
                if success then
                    -- print(string.format("[Game Enhancer] Reset %s = %d", cvar_name, default_value))
                else
                    -- print(string.format("[Game Enhancer] Failed to reset %s: %s", cvar_name, err))
                end
            end
            return
        end

        -- print("[Game Enhancer] Enabled - Applying selected optimizations")
        local selected_boosts = ui.get(game_enhancer.settings)
        for name, data in pairs(fps_cvars) do
            local cvar_name, boost_value, default_value = unpack(data)
            local is_selected = table_contains(selected_boosts, name)
            local final_value = is_selected and boost_value or default_value
            local success, err = pcall(function() cvar[cvar_name]:set_int(final_value) end)
            if success then
                -- print(string.format("[Game Enhancer] %s: %s = %d", is_selected and "APPLIED" or "SKIPPED", cvar_name, final_value))
            else
                -- print(string.format("[Game Enhancer] Failed to set %s: %s", cvar_name, err))
            end
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
-- SECRET EXPLOIT FEATURE (FROM EMBERLASH)
-- =====================================================

local secret_exploit = {}
do
    local function on_setup_command(e)
        if not secret_exploit.enable or not ui.get(secret_exploit.enable) then
            return
        end

        local local_player = entity.get_local_player()
        if not local_player or not entity.is_alive(local_player) then
            return
        end

        -- Disable anti-untrusted for exploit to work
        local anti_untrusted_ref = ui.reference("MISC", "Settings", "Anti-untrusted")
        if anti_untrusted_ref then
            ui.set(anti_untrusted_ref, false)
        end

        -- Set extreme pitch for exploit
        e.pitch = -540

        -- Calculate yaw with offset from builder
        e.yaw = e.yaw + 180 + 0  -- TODO: integrate with builder angles system

        -- Set fakelag for exploit
        local _, fakelag_amount_ref = ui.reference("AA", "Fake lag", "Amount")
        local _, fakelag_limit_ref = ui.reference("AA", "Fake lag", "Limit")
        if fakelag_amount_ref then
            fakelag_amount_ref:override('Dynamic')
        end
        if fakelag_limit_ref then
            fakelag_limit_ref:override(14)
        end
    end

    -- Initialize UI elements
    secret_exploit.enable = ui.new_checkbox("RAGE", "Other", '\vSecret\r exploit')

    client.set_event_callback('setup_command', on_setup_command)
end

-- Setup FFI for entity access
local pointer_type = ffi.typeof("void***")
local entity_list_ptr = client.create_interface("client.dll", "VClientEntityList003") or error("VClientEntityList003 not found", 2)
local entity_list = ffi.cast(pointer_type, entity_list_ptr) or error("entity list is nil", 2)
local get_client_entity = ffi.cast("void*(__thiscall*)(void*, int)", entity_list[0][3]) or error("get_client_entity is nil", 2)
local get_client_networkable = ffi.cast("void*(__thiscall*)(void*, int)", entity_list[0][0]) or error("get_client_networkable is nil", 2)

-- =====================================================
-- RESOLVER STATE AND VARIABLES
-- =====================================================

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

-- UI Elements
local enable_resolver_checkbox = nil
local resolver_mode = nil

-- Global aim punch fix state
local aim_punch_fix_state = { last_health = 100, override_active = false }

-- Aim punch fix callback function (defined globally)
local function aim_punch_fix_callback()
    -- Check if UI element exists and is enabled
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

-- Aim punch fix UI element
local aim_punch_fix_checkbox = ui.new_checkbox("RAGE", "Other", 'Aim punch miss fix')

-- Register callback after function is defined
client.set_event_callback('setup_command', aim_punch_fix_callback)

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

-- =====================================================
-- RESOLVER STATE AND VARIABLES
-- =====================================================

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

-- UI Elements
local enable_resolver_checkbox = nil
local resolver_mode = nil

-- =====================================================
-- RESOLVER UTILITY FUNCTIONS
-- =====================================================

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

-- Check if value exists in table
local function table_contains(table, value)
    for i = 1, #table do
        if table[i] == value then
            return true
        end
    end
    return false
end

-- Linear interpolation
local function lerp(start, end_val, amount)
    return start + (end_val - start) * amount
end

-- Find most frequent value in table
local function most_frequent(tbl)
    local count = {}
    local most_common = nil
    local max_count = 0

    for _, value in ipairs(tbl) do
        count[value] = (count[value] or 0) + 1
        if count[value] > max_count then
            max_count = count[value]
            most_common = value
        end
    end

    return most_common
end

-- Split string by delimiter
local function split_string(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- Convert seconds to ticks
local function seconds_to_ticks(seconds)
    return math.floor(0.5 + seconds / globals.tickinterval())
end

-- Convert ticks to seconds
local function ticks_to_seconds(ticks)
    return globals.tickinterval() * ticks
end

-- Get animation layer
local function get_anim_layer(entity_ptr, layer_index)
    layer_index = layer_index or 1
    entity_ptr = ffi.cast(pointer_type, entity_ptr)
    return ffi.cast("struct animation_layer_t**", ffi.cast("char*", entity_ptr) + 0x2990)[0][layer_index]
end


-- =====================================================
-- PLAYER TRACKING
-- =====================================================

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

-- =====================================================
-- ANTI-AIM ANALYSIS
-- =====================================================

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
            if ui.get(enable_resolver_checkbox) then
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

                -- Determine anti-aim type
                if resolver_state.player_fired and
                   math.abs(math.abs(player_history.cur[player].pitch) - math.abs(player_history.prev[player].pitch)) > 30 and
                   player_history.cur[player].pitch < player_history.prev[player].pitch then
                    aa_type = "ON SHOT"
                else
                    if math.abs(player_history.cur[player].pitch) > 60 then
                        if yaw_delta_abs > 30 and
                           math.abs(delta_cur_pre_prev) < 15 and
                           math.abs(delta_prev_pre_pre_prev) < 15 then
                            aa_type = "[!!]"
                        elseif math.abs(delta_cur_prev) > 15 or
                               math.abs(delta_prev_pre_prev) > 15 or
                               math.abs(delta_pre_prev_pre_pre_prev) > 15 or
                               math.abs(delta_pre_pre_prev_cur) > 15 then
                            aa_type = "[!!!]"
                        end
                    end
                end

                -- Apply anti-aim correction if detected
                if player_history.cur[player].pitch >= 78 and player_history.prev[player].pitch > 78 then
                    if aa_type == "[!!!]" or aa_type == "[!!]" then
                        if aa_type == "[!!]" then
                            if normalize_angle(current_yaw - prev_yaw) > 0 then
                                plist.set(player, "Force body yaw", true)
                                plist.set(player, "Force body yaw value", 60)
                            elseif normalize_angle(current_yaw - prev_yaw) < 0 then
                                plist.set(player, "Force body yaw", true)
                                plist.set(player, "Force body yaw value", -60)
                            end
                        elseif aa_type == "[!!!]" then
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


-- =====================================================
-- WATERMARK SYSTEM (PORTED FROM OLDWATERMARK.LUA)
-- =====================================================

-- Watermark variables
local watermark_data = {
    items = {},
    items_drawn = {},
    frame_data = {},
    offset_x = -15,
    offset_y = 15,
    rainbow_colors = {},
    rainbow_index = 0,
    prev_fps = 0,
    prev_values = {}
}

-- Rainbow header colors (3 static gradient colors)
local rainbow_header_colors = {
    {255, 0, 0},    -- Red
    {0, 255, 0},    -- Green
    {0, 0, 255}     -- Blue
}

-- Database for persistent storage
local watermark_db = database.read("wraith_watermark") or {}

-- UI References
local watermark_reference = nil
local color_reference = nil
local custom_name_reference = nil
local rainbow_header_reference = nil
local custom_sense_checkbox_reference = nil
local custom_sense_color_reference = nil
local gradient_color1_reference = nil
local gradient_color2_reference = nil
local gradient_color3_reference = nil
local gradient_color1_label = nil
local gradient_color2_label = nil
local gradient_color3_label = nil

-- All watermark features from oldwatermark.lua
local watermark_items = {
    {
        name = "Logo",
        get_width = function(self, frame_data)
            self.wraith_width = renderer.measure_text(nil, "hrisito")
            self.resolver_width = renderer.measure_text(nil, "sense")
            self.beta_width = renderer.measure_text(nil, "+")
            return self.wraith_width + self.resolver_width + self.beta_width
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)

            -- Draw each part with custom colors and glow effect
            -- hrisito (white with glow)
            renderer.text(x + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, "hrisito")
            renderer.text(x, y, 255, 255, 255, a, nil, 0, "hrisito")

            -- Use custom sense color if enabled, otherwise default gamesense green
            local sense_r, sense_g, sense_b, sense_a = 149, 184, 6, 255  -- Default gamesense green
            if custom_sense_checkbox_reference and custom_sense_color_reference and ui.get(custom_sense_checkbox_reference) then
                -- Get color picker values properly
                local color_r, color_g, color_b, color_a = ui.get(custom_sense_color_reference)

                if color_r and color_g and color_b then
                    sense_r, sense_g, sense_b, sense_a = color_r, color_g, color_b, color_a
                end
            end
            -- sense (custom color with glow)
            renderer.text(x + self.wraith_width + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, "sense")
            renderer.text(x + self.wraith_width, y, sense_r, sense_g, sense_b, a, nil, 0, "sense")

            -- + (red with glow)
            renderer.text(x + self.wraith_width + self.resolver_width + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, "+")
            renderer.text(x + self.wraith_width + self.resolver_width, y, 255, 90, 90, a, nil, 0, "+")
        end
    },
    {
        name = "Custom text",
        get_width = function(self, frame_data)
            local edit = ui.get(custom_name_reference)
            if edit ~= self.edit_prev and self.edit_prev ~= nil then
                watermark_db.custom_name = edit
            elseif edit == "" and watermark_db.custom_name ~= nil then
                ui.set(custom_name_reference, watermark_db.custom_name)
            end
            self.edit_prev = edit

            local text = watermark_db.custom_name
            if text ~= nil and text:gsub(" ", "") ~= "" then
                self.text = text
                return renderer.measure_text(nil, text)
            else
                self.text = nil
            end
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)

            -- Glow effect (shadow text)
            renderer.text(x + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, self.text)
            renderer.text(x, y, r, g, b, a, nil, 0, self.text)
        end
    },
    {
        name = "FPS",
        get_width = function(self, frame_data)
            self.fps = math.floor(1 / globals.absoluteframetime())
            self.text = tostring(self.fps or 0) .. " fps"

            local fps_max_val = 999
            self.width = math.max(renderer.measure_text(nil, self.text), renderer.measure_text(nil, fps_max_val .. " fps"))
            return self.width
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local fps_r, fps_g, fps_b = r, g, b
            local glow_alpha = math.floor(a * 0.4)

            -- Color code FPS based on performance with modern palette
            if self.fps < 60 then
                fps_r, fps_g, fps_b = 255, 100, 100  -- Red for low FPS
            elseif self.fps < 120 then
                fps_r, fps_g, fps_b = 255, 200, 100  -- Orange for medium FPS
            else
                fps_r, fps_g, fps_b = 150, 255, 150  -- Green for high FPS
            end

            -- Glow effect (shadow text)
            renderer.text(x + self.width + 1, y + 1, 0, 0, 0, glow_alpha, "r", 0, self.text)
            renderer.text(x + self.width, y, fps_r, fps_g, fps_b, a, "r", 0, self.text)
        end
    },
    {
        name = "Ping",
        get_width = function(self, frame_data)
            local ping = client.latency()
            self.ping = ping > 0 and ping or 0
            self.text = math.floor(self.ping*1000) .. "ms"
            self.width = math.max(renderer.measure_text(nil, "999ms"), renderer.measure_text(nil, self.text))
            return self.width
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local ping_r, ping_g, ping_b = r, g, b
            local glow_alpha = math.floor(a * 0.4)

            -- Dynamic ping color coding (similar to FPS but for ping)
            local ping = self.ping * 1000  -- Convert to ms for easier reading

            if ping <= 40 then
                -- Excellent ping: Bright green
                ping_r, ping_g, ping_b = 150, 255, 150
            elseif ping <= 60 then
                -- Good ping: Yellow-green
                local t = (ping - 40) / 20  -- 0 to 1 over 20ms
                ping_r = math.floor(150 + t * 105)  -- 150→255
                ping_g = math.floor(255 - t * 71)   -- 255→184
                ping_b = math.floor(150 - t * 150)  -- 150→0
            elseif ping <= 100 then
                -- Moderate ping: Yellow to orange
                local t = (ping - 60) / 40  -- 0 to 1 over 40ms
                ping_r = 255
                ping_g = math.floor(184 - t * 184)  -- 184→0
                ping_b = 0
            elseif ping <= 150 then
                -- High ping: Orange to red
                local t = (ping - 100) / 50  -- 0 to 1 over 50ms
                ping_r = 255
                ping_g = math.floor(0 + t * 100)   -- 0→100
                ping_b = 0
            else
                -- Very high ping: Red
                ping_r, ping_g, ping_b = 255, 100, 100
            end

            -- Glow effect (shadow text)
            renderer.text(x + self.width + 1, y + 1, 0, 0, 0, glow_alpha, "r", 0, self.text)
            renderer.text(x + self.width, y, ping_r, ping_g, ping_b, a, "r", 0, self.text)
        end
    },
    {
        name = "KDR",
        get_width = function(self, frame_data)
            frame_data.local_player = frame_data.local_player or entity.get_local_player()
            if frame_data.local_player == nil then return end

            local player_resource = entity.get_player_resource()
            if player_resource == nil then return end

            self.kills = entity.get_prop(player_resource, "m_iKills", frame_data.local_player)
            self.deaths = math.max(entity.get_prop(player_resource, "m_iDeaths", frame_data.local_player), 1)

            self.kdr = self.kills/self.deaths

            if self.kdr ~= 0 then
                self.text = string.format("%.1f", self.kdr)
                self.text_width = math.max(renderer.measure_text(nil, "10.0"), renderer.measure_text(nil, self.text))
                self.unit_width = renderer.measure_text("-", "kdr")
                return self.text_width+self.unit_width
            end
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)

            -- Glow effect (shadow text)
            renderer.text(x + self.text_width + 1, y + 1, 0, 0, 0, glow_alpha, "r", 0, self.text)
            renderer.text(x + self.text_width + self.unit_width + 1, y + 3, 0, 0, 0, glow_alpha, "r-", 0, "kdr")

            -- Main text
            renderer.text(x + self.text_width, y, r, g, b, a, "r", 0, self.text)
            renderer.text(x + self.text_width + self.unit_width, y + 2, 255, 255, 255, a * 0.75, "r-", 0, "kdr")
        end
    },
    {
        name = "Velocity",
        get_width = function(self, frame_data)
            frame_data.local_player = frame_data.local_player or entity.get_local_player()
            if frame_data.local_player == nil then return end

            local vel_x, vel_y = entity.get_prop(frame_data.local_player, "m_vecVelocity")
            if vel_x ~= nil then
                self.velocity = math.sqrt(vel_x*vel_x + vel_y*vel_y)
                self.vel_width = renderer.measure_text(nil, "9999")
                self.unit_width = renderer.measure_text("-", "vel")
                return self.vel_width+self.unit_width
            end
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)
            local velocity = math.min(9999, self.velocity) + 0.4
            velocity = math.floor(velocity)

            -- Glow effect (shadow text)
            renderer.text(x + self.vel_width + 1, y + 1, 0, 0, 0, glow_alpha, "r", 0, velocity)
            renderer.text(x + self.vel_width + self.unit_width + 1, y + 4, 0, 0, 0, glow_alpha, "r-", 0, "vel")

            -- Main text
            renderer.text(x + self.vel_width, y, 255, 255, 255, a, "r", 0, velocity)
            renderer.text(x + self.vel_width + self.unit_width, y + 3, 255, 255, 255, a * 0.75, "r-", 0, "vel")
        end
    },
    {
        name = "Server framerate",
        get_width = function(self, frame_data)
            frame_data.local_player = frame_data.local_player or entity.get_local_player()
            if frame_data.local_player == nil then return end

            -- Simplified server framerate calculation
            self.framerate = 64 -- Assume 64 tick server
            self.var = 1

            self.text1 = "sv:"
            self.text2 = string.format("%.1f", self.framerate)
            self.text3 = " +-"
            self.text4 = string.format("%.1f", self.var)

            self.width1 = renderer.measure_text(nil, self.text1)
            self.width2 = math.max(renderer.measure_text(nil, self.text2), renderer.measure_text(nil, "99.9"))
            self.width3 = renderer.measure_text(nil, self.text3)
            self.width4 = math.max(renderer.measure_text(nil, self.text4), renderer.measure_text(nil, "9.9"))

            return self.width1 + self.width2 + self.width3 + self.width4
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)
            local fr_r, fr_g, fr_b = r, g, b
            local vr_r, vr_g, vr_b = r, g, b

            -- Glow effect (shadow text)
            renderer.text(x + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, self.text1)
            renderer.text(x + self.width1 + self.width2 + 1, y + 1, 0, 0, 0, glow_alpha, "r", 0, self.text2)
            renderer.text(x + self.width1 + self.width2 + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, self.text3)
            renderer.text(x + self.width1 + self.width2 + self.width3 + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, self.text4)

            -- Main text
            renderer.text(x, y, r, g, b, a, nil, 0, self.text1)
            renderer.text(x + self.width1 + self.width2, y, fr_r, fr_g, fr_b, a, "r", 0, self.text2)
            renderer.text(x + self.width1 + self.width2, y, r, g, b, a, nil, 0, self.text3)
            renderer.text(x + self.width1 + self.width2 + self.width3, y, vr_r, vr_g, vr_b, a, nil, 0, self.text4)
        end
    },
    {
        name = "Server info",
        get_width = function(self, frame_data)
            frame_data.local_player = frame_data.local_player or entity.get_local_player()
            if frame_data.local_player == nil then return end

            local game_rules = entity.get_game_rules()
            local game_mode_name = "CS:GO"

            if game_rules ~= nil then
                local game_mode, game_type = 0, 0
                local is_queued_matchmaking = entity.get_prop(game_rules, "m_bIsQueuedMatchmaking") == 1

                if is_queued_matchmaking then
                    game_mode_name = "MM"
                else
                    game_mode_name = "Casual"
                end
            end

            if game_mode_name ~= nil then
                self.text = "Valve (" .. game_mode_name .. ")"
                return renderer.measure_text(nil, self.text)
            end
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)

            -- Glow effect (shadow text)
            renderer.text(x + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, self.text)

            -- Main text
            renderer.text(x, y, 255, 255, 255, a, nil, 0, self.text)
        end
    },
    {
        name = "Tickrate",
        get_width = function(self, frame_data)
            if globals.mapname() == nil then return end
            local tickinterval = globals.tickinterval()
            if tickinterval ~= nil then
                local tickrate = math.floor(1/tickinterval)
                self.text = tickrate .. " tick"
                return renderer.measure_text(nil, self.text)
            end
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local glow_alpha = math.floor(a * 0.4)

            -- Glow effect (shadow text)
            renderer.text(x + 1, y + 1, 0, 0, 0, glow_alpha, nil, 0, self.text)

            -- Main text
            renderer.text(x, y, 255, 255, 255, a, nil, 0, self.text)
        end
    },
    {
        name = "Time",
        get_width = function(self, frame_data)
            self.time_width = renderer.measure_text(nil, "00")
            self.sep_width = renderer.measure_text(nil, ":")
            return self.time_width + self.sep_width + self.time_width + (self.seconds and (self.sep_width + self.time_width) or 0)
        end,
        draw = function(self, x, y, w, h, r, g, b, a)
            local hours, minutes, seconds, milliseconds = client.system_time()
            hours, minutes = string.format("%02d", hours), string.format("%02d", minutes)
            local glow_alpha = math.floor(a * 0.4)

            -- Glow effect (shadow text)
            renderer.text(x + 1, y + 1, 0, 0, 0, glow_alpha, "", 0, hours)
            renderer.text(x + self.time_width + 1, y + 1, 0, 0, 0, glow_alpha, "", 0, ":")
            renderer.text(x + self.time_width + self.sep_width + 1, y + 1, 0, 0, 0, glow_alpha, "", 0, minutes)

            -- Main text
            renderer.text(x, y, 255, 255, 255, a, "", 0, hours)
            renderer.text(x+self.time_width, y, 255, 255, 255, a, "", 0, ":")
            renderer.text(x+self.time_width+self.sep_width, y, 255, 255, 255, a, "", 0, minutes)

            if self.seconds then
                seconds = string.format("%02d", seconds)
                -- Glow effect for seconds
                renderer.text(x + self.time_width*2 + self.sep_width + 1, y + 1, 0, 0, 0, glow_alpha, "", 0, ":")
                renderer.text(x + self.time_width*2 + self.sep_width*2 + 1, y + 1, 0, 0, 0, glow_alpha, "", 0, seconds)

                -- Main text for seconds
                renderer.text(x+self.time_width*2+self.sep_width, y, 255, 255, 255, a, "", 0, ":")
                renderer.text(x+self.time_width*2+self.sep_width*2, y, 255, 255, 255, a, "", 0, seconds)
            end
        end,
        seconds = true
    }
}

-- Rainbow header animation (now static)
-- Function kept for potential future use but not called in static mode

-- Watermark callback for UI changes
local function on_watermark_changed()
    local value = ui.get(watermark_reference)

    if #value > 0 then
        -- Handle Time / Time + seconds mutual exclusion
        if table_contains(value, "Time") and table_contains(value, "Time + seconds") then
            local value_new = value
            if not table_contains(watermark_data.prev_values, "Time") then
                value_new = table_remove_element(value_new, "Time + seconds")
            elseif not table_contains(watermark_data.prev_values, "Time + seconds") then
                value_new = table_remove_element(value_new, "Time")
            end

            if table_contains(value_new, "Time") and table_contains(value_new, "Time + seconds") then
                value_new = table_remove_element(value_new, "Time")
            end

            ui.set(watermark_reference, value_new)
            on_watermark_changed()
            return
        end
    end

    ui.set_visible(custom_name_reference, table_contains(value, "Custom text"))
    ui.set_visible(rainbow_header_reference, #value > 0)

    -- Show custom sense checkbox when watermark is enabled AND Logo is selected
    local show_custom_sense_checkbox = #value > 0 and table_contains(value, "Logo")
    if custom_sense_checkbox_reference then
        ui.set_visible(custom_sense_checkbox_reference, show_custom_sense_checkbox)
    end

    -- Show custom sense color picker when checkbox is enabled
    local sense_checkbox_enabled = custom_sense_checkbox_reference and ui.get(custom_sense_checkbox_reference)
    local show_custom_sense_color = sense_checkbox_enabled
    if custom_sense_color_reference then
        ui.set_visible(custom_sense_color_reference, show_custom_sense_color)
    end

    -- Show gradient color pickers and labels when watermark is enabled and rainbow header is checked
    local show_gradient_pickers = (#value > 0) and rainbow_header_reference and ui.get(rainbow_header_reference)

    -- Set visibility only if UI elements exist (nil checks)
    if gradient_color1_label then ui.set_visible(gradient_color1_label, show_gradient_pickers) end
    if gradient_color1_reference then ui.set_visible(gradient_color1_reference, show_gradient_pickers) end
    if gradient_color2_label then ui.set_visible(gradient_color2_label, show_gradient_pickers) end
    if gradient_color2_reference then ui.set_visible(gradient_color2_reference, show_gradient_pickers) end
    if gradient_color3_label then ui.set_visible(gradient_color3_label, show_gradient_pickers) end
    if gradient_color3_reference then ui.set_visible(gradient_color3_reference, show_gradient_pickers) end

    watermark_data.prev_values = value

    -- Save to database
    database.write("wraith_watermark", watermark_db)
end

-- Main watermark paint function
local function on_paint_watermark()
    -- Check if watermark is enabled
    if watermark_reference == nil or not ui.get(watermark_reference) or #ui.get(watermark_reference) == 0 then
        return
    end

    local screen_width, screen_height = client.screen_size()

    -- Calculate total width first
    local total_width = 0
    local item_margin = 9

    -- Get enabled features
    local enabled_features = ui.get(watermark_reference) or {}

    -- Handle special Time + seconds case
    for i=1, #watermark_items do
        local item = watermark_items[i]
        if item.name == "Time" then
            item.seconds = table_contains(enabled_features, "Time + seconds")
            if item.seconds then
                table.insert(enabled_features, "Time")
            end
        end
    end

    for i=1, #watermark_items do
        local item = watermark_items[i]
        if table_contains(enabled_features, item.name) then
            local item_width = item:get_width(watermark_data.frame_data)
            if item_width ~= nil and item_width > 0 then
                total_width = total_width + item_width + item_margin
            end
        end
    end

    total_width = total_width - item_margin -- Remove last margin

    -- Position exactly like oldwatermark.lua with independent left/right padding
    local margin_x = 15
    local margin_y = 15
    local padding_left = 2   -- Left padding (space before text starts)
    local padding_right = 2  -- Right padding (space after text ends)
    local x = screen_width - total_width - margin_x  -- Original positioning
    local y = margin_y

    -- Calculate text and background boundaries with independent padding
    local text_start_x = x
    local text_end_x = x + total_width
    local background_start_x = text_start_x - padding_left   -- Left padding
    local background_end_x = text_end_x + padding_right     -- Right padding
    local background_width = background_end_x - background_start_x

    -- Background: text_start_x - padding_left to text_end_x + padding_right
    -- Text: starts at original x position (centered within padded background)
    -- Independent padding control for left and right sides

    -- Rainbow colors are now static

    -- Reset items drawn
    watermark_data.items_drawn = {}
    local item_margin = 9

    -- Build items drawn with positioning
    local current_x = 0
    for i=1, #watermark_items do
        local item = watermark_items[i]
        if table_contains(enabled_features, item.name) then
            local item_width = item:get_width(watermark_data.frame_data)
            if item_width ~= nil and item_width > 0 then
                table.insert(watermark_data.items_drawn, {
                    item = item,
                    item_width = item_width,
                    x = current_x
                })
                current_x = current_x + item_width + item_margin
            end
        end
    end

    if #watermark_data.items_drawn == 0 then
        return
    end

    local text_height = select(2, renderer.measure_text(nil, "A"))
    local height = text_height + 8 -- Add some padding
    local bar_height = 3 -- Thin rainbow bar

    -- Draw ultra-smooth customizable gradient header bar if enabled
    if ui.get(rainbow_header_reference) then
        local bar_y = y - bar_height  -- Flush with background

        -- Get customizable gradient colors from UI (with nil checks)
        local color1_r, color1_g, color1_b = 40, 72, 113  -- Default dark blue-gray
        local color2_r, color2_g, color2_b = 164, 200, 255  -- Default light blue
        local color3_r, color3_g, color3_b = 40, 72, 113   -- Default dark blue-gray

        -- Override with UI values if references exist
        if gradient_color1_reference then
            color1_r, color1_g, color1_b = ui.get(gradient_color1_reference)
        end
        if gradient_color2_reference then
            color2_r, color2_g, color2_b = ui.get(gradient_color2_reference)
        end
        if gradient_color3_reference then
            color3_r, color3_g, color3_b = ui.get(gradient_color3_reference)
        end

        -- Create sophisticated 3-color gradient with ultra-smooth transitions
        local gradient_width = background_width  -- Exact same width as background
        local segments = math.max(math.floor(gradient_width), 240)  -- More segments for ultra-smooth gradient

        for i = 0, segments - 1 do
            local segment_width = gradient_width / segments  -- Width of each gradient segment
            local t = i / (segments - 1)  -- 0 to 1 across entire gradient bar

            -- Ultra-smooth 3-color gradient algorithm with seamless transitions
            local r, g, b

            -- Use smoothstep interpolation for perfect transitions
            local function smoothstep(edge0, edge1, x)
                local t = math.max(0, math.min(1, (x - edge0) / (edge1 - edge0)))
                return t * t * (3 - 2 * t)
            end

            if t <= 0.5 then
                -- First half: Color1 → Color2 using smoothstep
                local eased_t = smoothstep(0, 0.5, t)
                r = color1_r + (color2_r - color1_r) * eased_t
                g = color1_g + (color2_g - color1_g) * eased_t
                b = color1_b + (color2_b - color1_b) * eased_t
            else
                -- Second half: Color2 → Color3 using smoothstep
                local eased_t = smoothstep(0.5, 1, t)
                r = color2_r + (color3_r - color2_r) * eased_t
                g = color2_g + (color3_g - color2_g) * eased_t
                b = color2_b + (color3_b - color2_b) * eased_t
            end

            -- Apply sophisticated depth and lighting effects
            local depth_factor = 1.0
            local highlight_factor = 1.0

            -- Create depth (darker in middle sections)
            if t > 0.2 and t < 0.8 then
                depth_factor = 0.9  -- Slightly more depth
            end

            -- Create highlight (brighter at ends, especially the finish)
            if t < 0.15 or t > 0.85 then
                highlight_factor = 1.08  -- Brightening at edges
            end

            -- Apply depth and lighting
            local final_factor = depth_factor * highlight_factor
            r = r * final_factor
            g = g * final_factor
            b = b * final_factor

            -- Ultra-precise color calculation with anti-aliasing prep
            local pixel_r = math.max(0, math.min(255, math.floor(r + 0.5)))
            local pixel_g = math.max(0, math.min(255, math.floor(g + 0.5)))
            local pixel_b = math.max(0, math.min(255, math.floor(b + 0.5)))

            -- Draw with perfect positioning - match exact background boundaries with independent padding
            local exact_x = background_start_x + (i * segment_width)
            local next_x = background_start_x + ((i + 1) * segment_width)

            -- Ensure no gaps by rounding to nearest pixel
            local start_x = math.floor(exact_x + 0.5)
            local end_x = math.floor(next_x + 0.5)
            local draw_width = math.max(1, end_x - start_x)

            renderer.rectangle(start_x, bar_y, draw_width, bar_height, pixel_r, pixel_g, pixel_b, 255)
        end

        -- Add sophisticated lighting effects - match exact background boundaries
        -- Top highlight for depth
        renderer.gradient(background_start_x, bar_y, gradient_width, 1,
            255, 255, 255, 60,  -- Bright at top
            255, 255, 255, 0,   -- Fade to transparent
            false)

        -- Subtle shadow at bottom
        renderer.gradient(background_start_x, bar_y + bar_height - 1, gradient_width, 1,
            0, 0, 0, 30,        -- Dark shadow
            0, 0, 0, 0,         -- Fade to transparent
            false)
    end

    -- Get color picker values ONCE outside the loop
    local r, g, b, a = ui.get(color_reference)

    -- Draw background with exactly 2px padding on both sides of text
    renderer.rectangle(background_start_x, y, background_width, height, 32, 32, 32, a)

    -- Draw separator lines and text
    for i=1, #watermark_data.items_drawn do
        local item = watermark_data.items_drawn[i]

        -- Draw item text (reuse the color values extracted above) - account for left padding
        item.item:draw(x + item.x + padding_left, y + 2, item.item_width, text_height, r, g, b, 255)

        -- Draw separator line - account for left padding
        if #watermark_data.items_drawn > i then
            renderer.rectangle(x + item.x + item.item_width + 4 + padding_left, y + 2, 1, height - 4, 210, 210, 210, 255)
        end
    end
end

-- =====================================================
-- UI SETUP
-- =====================================================

-- Initialize UI elements
local function init_ui_elements()
    if enable_resolver_checkbox == nil then
        enable_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable resolver")
        if enable_resolver_checkbox == nil then
            return false
        end
    end

    if resolver_mode == nil then
        resolver_mode = ui.new_combobox("RAGE", "Other", "Resolver mode", {"desync", "off"})
        if resolver_mode == nil then
            return false
        end
    end

    -- Initialize game enhancer UI elements
    if game_enhancer.enable == nil then
        game_enhancer.enable = ui.new_checkbox("RAGE", "Other", 'Game enhancer')
        if game_enhancer.enable == nil then
            print("Failed to create game enhancer checkbox")
            return false
        end
        print("Created game enhancer checkbox")
    end

    if game_enhancer.settings == nil then
        game_enhancer.settings = ui.new_multiselect("RAGE", "Other", '\nGame enhancer list', {'Fix chams color', 'Disable dynamic lighting', 'Disable dynamic shadows', 'Disable first-person tracers', 'Disable ragdolls', 'Disable eye gloss', 'Disable eye movement', 'Disable muzzle flash light', 'Enable low CPU audio', 'Disable bloom', 'Disable particles', 'Reduce breakable objects'})
        if game_enhancer.settings == nil then
            print("Failed to create game enhancer settings")
            return false
        end
        print("Created game enhancer settings")
    end

    -- Initialize exploit UI elements
    if secret_exploit.enable == nil then
        secret_exploit.enable = ui.new_checkbox("RAGE", "Other", '\vSecret\r exploit')
        if secret_exploit.enable == nil then
            print("Failed to create secret exploit checkbox")
            return false
        end
        print("Created secret exploit checkbox")
    end

    -- Initialize watermark UI elements
    if watermark_reference == nil then
        watermark_reference = ui.new_multiselect("RAGE", "Other", "Watermark", {
            "Logo", "Custom text", "FPS", "Ping", "KDR", "Velocity",
            "Server framerate", "Server info", "Tickrate", "Time"
        })
        if watermark_reference == nil then
            print("Failed to create watermark multiselect")
            return false
        end
        print("Created watermark multiselect")
    end

    if color_reference == nil then
        color_reference = ui.new_color_picker("RAGE", "Other", "Watermark color", 149, 184, 6, 255)
        if color_reference == nil then
            print("Failed to create watermark color picker")
            return false
        end
        print("Created watermark color picker")

        -- Set default alpha to 40% (102) after creation
        ui.set(color_reference, 149, 184, 6, 102)
    end

    if custom_name_reference == nil then
        custom_name_reference = ui.new_textbox("RAGE", "Other", "Watermark name")
        if custom_name_reference == nil then
            print("Failed to create custom name textbox")
            return false
        end
        print("Created custom name textbox")
    end

    if rainbow_header_reference == nil then
        rainbow_header_reference = ui.new_checkbox("RAGE", "Other", "Watermark rainbow header")
        if rainbow_header_reference == nil then
            print("Failed to create rainbow header checkbox")
            return false
        end
        print("Created rainbow header checkbox")
    end

    if custom_sense_checkbox_reference == nil then
        custom_sense_checkbox_reference = ui.new_checkbox("RAGE", "Other", "Custom sense color")
        if custom_sense_checkbox_reference == nil then
            print("Failed to create custom sense checkbox")
            return false
        end
        print("Created custom sense checkbox")
    end

    if custom_sense_color_reference == nil then
        custom_sense_color_reference = ui.new_color_picker("RAGE", "Other", "Custom sense color", 255, 255, 0, 255)
        if custom_sense_color_reference == nil then
            print("Failed to create custom sense color picker")
            return false
        end
        print("Created custom sense color picker with yellow default")

        -- Set initial custom color to yellow instead of magenta
        ui.set(custom_sense_color_reference, 255, 255, 0, 255)
    end

    -- Initialize gradient color labels and pickers
    if gradient_color1_label == nil then
        gradient_color1_label = ui.new_label("RAGE", "Other", "Gradient color 1")
        if gradient_color1_label == nil then
            print("Failed to create gradient color1 label")
            return false
        end
        print("Created gradient color1 label")
    end

    if gradient_color1_reference == nil then
        gradient_color1_reference = ui.new_color_picker("RAGE", "Other", "Gradient color 1", 40, 72, 113, 255)
        if gradient_color1_reference == nil then
            print("Failed to create gradient color1 picker")
            return false
        end
        print("Created gradient color1 picker")
    end

    if gradient_color2_label == nil then
        gradient_color2_label = ui.new_label("RAGE", "Other", "Gradient color 2")
        if gradient_color2_label == nil then
            print("Failed to create gradient color2 label")
            return false
        end
        print("Created gradient color2 label")
    end

    if gradient_color2_reference == nil then
        gradient_color2_reference = ui.new_color_picker("RAGE", "Other", "Gradient color 2", 164, 200, 255, 255)
        if gradient_color2_reference == nil then
            print("Failed to create gradient color2 picker")
            return false
        end
        print("Created gradient color2 picker")
    end

    if gradient_color3_label == nil then
        gradient_color3_label = ui.new_label("RAGE", "Other", "Gradient color 3")
        if gradient_color3_label == nil then
            print("Failed to create gradient color3 label")
            return false
        end
        print("Created gradient color3 label")
    end

    if gradient_color3_reference == nil then
        gradient_color3_reference = ui.new_color_picker("RAGE", "Other", "Gradient color 3", 40, 72, 113, 255)
        if gradient_color3_reference == nil then
            print("Failed to create gradient color3 picker")
            return false
        end
        print("Created gradient color3 picker")
    end

    -- Ensure default colors are set correctly
    ui.set(gradient_color1_reference, 40, 72, 113, 255)
    ui.set(gradient_color2_reference, 164, 200, 255, 255)
    ui.set(gradient_color3_reference, 40, 72, 113, 255)

    return true
end


-- Get resolver enabled state
local function is_resolver_enabled()
    return enable_resolver_checkbox ~= nil and ui.get(enable_resolver_checkbox)
end

-- =====================================================
-- EVENT CALLBACKS
-- =====================================================

-- Main resolver update function
local function on_net_update_end()
    local local_player = entity.get_local_player()

    if not entity.is_alive(local_player) then
        return
    end

    -- Track players for anti-aim analysis (always needed for ESP flags)
    track_players(local_player)

    -- Analyze anti-aim patterns only if resolver is enabled
    if is_resolver_enabled() then
        analyze_anti_aim(local_player)
    else
        -- Reset resolver state when disabled
        resolver_state.is_analyzing_aa = false
        resolver_state.player_fired = false
        resolver_state.time_difference = 0
        resolver_state.ticks_since_last_shot = 0
    end
end

-- ESP flag callback
local function esp_flag_callback(player)
    if not entity.is_alive(entity.get_local_player()) then
        return
    end

    if is_resolver_enabled() and entity.is_alive(player) and not entity.is_dormant(player) then
        if player_aa_info[player] ~= nil and player_aa_info[player].anti_aim_type ~= nil then
            return true, string.upper(player_aa_info[player].anti_aim_type)
        end
    end
end


-- Setup event callbacks
local function setup_callbacks()
    pcall(function() init_ui_elements() end)

    -- Set watermark callback after UI is initialized
    if watermark_reference ~= nil then
        ui.set_callback(watermark_reference, on_watermark_changed)
        on_watermark_changed() -- Initialize visibility


        -- Force visibility update after initialization
        client.delay_call(0.1, function()
            if rainbow_header_reference and watermark_reference then
                local current_value = ui.get(watermark_reference)
                local rainbow_enabled = ui.get(rainbow_header_reference)
                local show_pickers = (#current_value > 0) and rainbow_enabled

                -- Set visibility only if UI elements exist (nil checks)
                if gradient_color1_label then ui.set_visible(gradient_color1_label, show_pickers) end
                if gradient_color1_reference then ui.set_visible(gradient_color1_reference, show_pickers) end
                if gradient_color2_label then ui.set_visible(gradient_color2_label, show_pickers) end
                if gradient_color2_reference then ui.set_visible(gradient_color2_reference, show_pickers) end
                if gradient_color3_label then ui.set_visible(gradient_color3_label, show_pickers) end
                if gradient_color3_reference then ui.set_visible(gradient_color3_reference, show_pickers) end
            end
        end)
    end

    -- Register callbacks
    client.set_event_callback("net_update_end", on_net_update_end)
    client.set_event_callback("setup_command", aim_punch_fix_callback)
    client.set_event_callback("setup_command", function(e)
        -- Call all setup_command functions
        aim_punch_fix_callback(e)
    end)
    client.set_event_callback("paint", on_paint_watermark)
    client.register_esp_flag("", 255, 255, 255, esp_flag_callback)

end

-- Cleanup function
local function cleanup()
    client.unset_event_callback("net_update_end", on_net_update_end)
    client.unset_event_callback("setup_command", aim_punch_fix_callback)

    -- Save watermark database
    if watermark_db then
        database.write("wraith_watermark", watermark_db)
    end

    print("hrisito multi-script unloaded")
end






-- =====================================================
-- INITIALIZATION
-- =====================================================

-- Initialize the resolver
local function initialize()
    print("multi-script loading...")

    -- Initialize UI elements
    if enable_resolver_checkbox == nil then
        enable_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable resolver")
    end

    if resolver_mode == nil then
        resolver_mode = ui.new_combobox("RAGE", "Other", "Resolver mode", {"desync", "off"})
    end

    -- Setup callbacks
    setup_callbacks()
end

-- Register cleanup callback
client.set_event_callback("shutdown", cleanup)

-- Start initialization
initialize()