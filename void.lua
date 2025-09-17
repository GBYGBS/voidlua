---@libs
local vector = require 'vector'
local clipboard = require 'gamesense/clipboard'
local json = require 'json'
local base64 = require 'gamesense/base64'
local c_entity = require 'gamesense/entity'
local weapons = require 'gamesense/csgo_weapons'
local client_latency, client_screen_size, client_set_event_callback, client_system_time, entity_get_local_player, entity_get_player_resource, entity_get_prop, globals_absoluteframetime, globals_tickinterval, math_ceil, math_floor, math_min, math_sqrt, renderer_measure_text, ui_reference, pcall, renderer_gradient, renderer_rectangle, renderer_text, string_format, table_insert, ui_get, ui_new_checkbox, ui_new_color_picker, ui_new_multiselect, ui_new_textbox, ui_set, ui_set_callback, ui_set_visible = client.latency, client.screen_size, client.set_event_callback, client.system_time, entity.get_local_player, entity.get_player_resource, entity.get_prop, globals.absoluteframetime, globals.tickinterval, math.ceil, math.floor, math.min, math.sqrt, renderer.measure_text, ui.reference, pcall, renderer.gradient, renderer.rectangle, renderer.text, string.format, table.insert, ui.get, ui.new_checkbox, ui.new_color_picker, ui.new_multiselect, ui.new_textbox, ui.set, ui.set_callback, ui.set_visible
local ffi = require 'ffi'
local pui = require("gamesense/pui")
---@end

---@ref_start
local ref = {} 
do
    local function init_refs()
        ref = {
            enabled = ui.reference("AA", "Anti-Aimbot angles", "Enabled"),
            pitch     = { ui.reference("AA", "Anti-Aimbot angles", "Pitch") },
            yaw_base  = ui.reference("AA", "Anti-Aimbot angles", "Yaw base"),
            yaw       = { ui.reference("AA", "Anti-Aimbot angles", "Yaw") },
            yaw_jitter = { ui.reference("AA", "Anti-Aimbot angles", "Yaw jitter") },
            body_yaw  = { ui.reference("AA", "Anti-Aimbot angles", "Body yaw") },
            freestanding_body_yaw = ui.reference("AA", "Anti-Aimbot angles", "Freestanding body yaw"),
            edge_yaw  = ui.reference("AA", "Anti-Aimbot angles", "Edge yaw"),
            freestand = { ui.reference("AA", "Anti-Aimbot angles", "Freestanding") },
            roll      = ui.reference("AA", "Anti-Aimbot angles", "Roll"),
            slow_walk = { ui.reference("AA", "Other", "Slow motion") },
            dt        = { ui.reference("RAGE", "Aimbot", "Double Tap") },
            hs        = { ui.reference("AA", "Other", "On shot anti-aim") },
            fd        = ui.reference("RAGE", "Other", "Duck peek assist"),
            min_damage = ui.reference("RAGE", "Aimbot", "Minimum damage"),
            min_damage_override = { ui.reference("RAGE", "Aimbot", "Minimum damage override") },
            rage_cb   = { ui.reference("RAGE", "Aimbot", "Enabled") },
            menu_color = ui.reference("MISC", "Settings", "Menu color"),
            fakelag_limit = ui.reference("AA", "Fake lag", "Limit"),
            variability   = ui.reference("AA", "Fake lag", "Variance"),
            aimbot        = ui.reference("RAGE", "Aimbot", "Enabled")
        }
    end
    init_refs()
end
---@ref_end

ffi.cdef[[
    struct c_animstate {
        char pad[3];
        char m_bForceWeaponUpdate; //0x4
        char pad1[91];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[4];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[4];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[4];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[4];
        float m_flUnknownFloat1; //0xD4
        char pad6[8];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        float m_flTimeSinceInAir; //0x10A
        float m_flLastOriginZ; //0x10E
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
        float m_flStopToFullRunningFraction; //0x116
        char pad7[4]; //0x11A
        float m_flMagicFraction; //0x11E
        char pad8[60]; //0x122
        float m_flWorldForce; //0x15E
        char pad9[462]; //0x162
        float m_flMaxYaw; //0x334
        float velocity_subtract_x; //0x330
        float velocity_subtract_y; //0x334
        float velocity_subtract_z; //0x338
    };

    typedef void*(__thiscall* get_client_entity_t)(void*, int);

    typedef struct
    {
        float m_anim_time;
        float m_fade_out_time;
        int m_flags;
        int m_activity;
        int m_priority;
        int m_order;
        int m_sequence;
        float m_prev_cycle;
        float m_weight;
        float m_weight_delta_rate;
        float m_playback_rate;
        float m_cycle;
        void* m_owner;
        int m_bits;
    } C_AnimationLayer;

    typedef uintptr_t(__thiscall* GetClientEntityHandle_4242425_t)(void*, uintptr_t);
]]

local entity_list_ptr = ffi.cast("void***", client.create_interface("client.dll", "VClientEntityList003"))
local get_client_entity_fn = ffi.cast("GetClientEntityHandle_4242425_t", entity_list_ptr[0][3])
local voidptr = ffi.typeof("void***")
local rawientitylist = client.create_interface("client_panorama.dll", "VClientEntityList003") or error("VClientEntityList003 wasn't found", 2)
local ientitylist = ffi.cast(voidptr, rawientitylist) or error("rawientitylist is nil", 2)
local get_client_entity = ffi.cast("get_client_entity_t", ientitylist[0][3]) or error("get_client_entity is nil", 2)

entity.get_vector_prop = function(idx, prop, array)
    local v1, v2, v3 = entity.get_prop(idx, prop, array)
    return {x = v1, y = v2, z = v3}
end

entity.get_address = function(idx)
    return get_client_entity_fn(entity_list_ptr, idx)
end

entity.get_animstate = function(idx)
    local addr = entity.get_address(idx)
    if not addr then return end
    return ffi.cast("struct c_animstate *", addr + 0x9960)[0]
end

entity.get_animlayer = function(idx, layer_idx)
    local addr = entity.get_address(idx)
    if not addr ) then
        print("[VOID] Warning: Failed to get entity address for player ", idx)
        return nil
    end
    local layer_ptr = ffi.cast("C_AnimationLayer *", ffi.cast('uintptr_t', addr) + 0x2990)[0]
    if layer_ptr )
        return layer_ptr[layer_idx]
    end
    return nil
end

entity.get_max_desync = function(ent)
    local ways = math.clamp(ent.feet_speed_forwards_or_sideways, 0, 1)
    local frac = (ent.stop_to_full_running_fraction * -0.3 - 0.2) * ways + 1
    local ducking = ent.duck_amount

    if ducking > 0 )
        frac = frac + ducking * ways * (0.5 - frac)
    end

    return math.clamp(frac, 0.5, 1)
end

-- Additional math functions if not present
math.clamp = function(value, min, max)
    return value < min and min or (value > max and max or value)
end

math.vec_length2d = function(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

math.angle_normalize = function(angle)
    return (angle % 360 + 360) % 360
end

math.angle_diff = function(dest, src)
    local delta = (dest - src + 540) % 360 - 180
    return delta
end

math.approach_angle = function(target, value, speed)
    target = math.angle_normalize(target)
    value = math.angle_normalize(value)

    local delta = math.angle_diff(target, value)
    speed = math.abs(speed)

    if delta > speed )
        value = value + speed
    elseif delta < -speed )
        value = value - speed
    else
        value = target
    end

    return math.angle_normalize(value)
end

---@region tools
local tools = {
    lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    to_hex = function(r, g, b, a)
        return string.format("%02x%02x%02x%02x", r, g, b, a)
    end,
    clamp = function(value, min, max)
        return math.max(min, math.min(max, value))
    end,
    time_to_ticks = function(t)
        return math.floor(0.5 + (t / globals.tickinterval())))
    end
}

local function ui_set_smart(ref_item, value)
    if ref_item == nil then return end
    local current = ui.get(ref_item)
    if current ~= value )
        ui.set(ref_item, value)
    end
end

local function get_enemies_filtered()
    local enemies = entity.get_players(true)
    local filtered = {}
    local me = entity.get_local_player()
    
    if me and entity.is_alive(me) )
        local my_pos = { entity.get_origin(me) }
        for i = 1, #enemies do
            local ent = enemies[i]
            if entity.is_alive(ent) )
                local ent_pos = { entity.get_origin(ent) }
                if ent_pos[1] )
                    local distance = math.sqrt((ent_pos[1] - my_pos[1])^2 + (ent_pos[2] - my_pos[2])^2 + (ent_pos[3] - my_pos[3])^2)
                    if distance < 4000 )
                        table.insert(filtered, ent)
                    end
                end
            end
        end
    end
    
    return filtered
end

local function normalize_yaw(yaw)
    while yaw > 180 do yaw = yaw - 360 end
    while yaw < -180 do yaw = yaw + 360 end
    return yaw
end

local function toticks(time)
    return tools.time_to_ticks(time)
end

local function contains(table, val)
    for i = 1, #table do
        if table[i] == val )
            return true
        end
    end
    return false
end
---@end

---@skeet_elements_hider_start
local function on_load()
    local skeet_refs = {
        ref.enabled, ref.pitch[1], ref.pitch[2], ref.yaw_base, ref.yaw[1], ref.yaw[2],
        ref.yaw_jitter[1], ref.yaw_jitter[2], ref.body_yaw[1], ref.body_yaw[2],
        ref.freestanding_body_yaw, ref.edge_yaw, ref.freestand[1], ref.freestand[2],
        ref.roll
    }
    for _, ref_item in ipairs(skeet_refs) do
        ui.set_visible(ref_item, false))
    end
end

local function on_unload()
    local skeet_refs = {
        ref.enabled, ref.pitch[1], ref.pitch[2], ref.yaw_base, ref.yaw[1], ref.yaw[2],
        ref.yaw_jitter[1], ref.yaw_jitter[2], ref.body_yaw[1], ref.body_yaw[2],
        ref.freestanding_body_yaw, ref.edge_yaw, ref.freestand[1], ref.freestand[2],
        ref.roll
    }
    for _, ref_item in ipairs(skeet_refs) do
        ui.set_visible(ref_item, true))
    end
end
---@skeet_elements_hider_end

---@lua_menu_start
local cur_tab
local states = {"Global", "Stand", "Running", "Air", "Air-Duck", "Slow-walk", "Duck", "Duck-Running"}
local lua_menu = {}
do
    function lua_menu.init()
        lua_menu.labels = {
            ui.new_label("AA", "Anti-aimbot angles", "                  \aFFFFFFFF   VOID" ..
                "\aFFFFFFFF "),
            ui.new_label("AA", "Anti-aimbot angles", " "),
            ui.new_label("AA", "Anti-aimbot angles", "                     \aC0C0C0FFdebug"),
            ui.new_label("AA", "Anti-aimbot angles", "  ")
        }

        cur_tab = 1 -- 1 = main, 2 = aa, 3 = visuals, 4 = misc, 5 = discloser, 6 = config

        lua_menu.buttons = {
            back = ui.new_button("AA", "Anti-Aimbot angles", "\aC0C0C0FFBack", function()
                cur_tab = 1
                lua_menu.group_visibility()
            end),
            aa = ui.new_button("AA", "Anti-Aimbot angles", "\aC0C0C0FFAnti-Aim", function()
                cur_tab = 2
                lua_menu.group_visibility()
            end),
            discloser = ui.new_button("AA", "Anti-Aimbot angles", "\aC0C0C0FFTweaks / Discloser", function()
                cur_tab = 5
                lua_menu.group_visibility()
            end),
            visuals = ui.new_button("AA", "Anti-Aimbot angles", "\aC0C0C0FFVisuals", function()
                cur_tab = 3
                lua_menu.group_visibility()
            end),
            misc = ui.new_button("AA", "Anti-Aimbot angles", "\aC0C0C0FFMisc", function()
                cur_tab = 4
                lua_menu.group_visibility()
            end),
            config = ui.new_button("AA", "Anti-Aimbot angles", "\aC0C0C0FFConfig", function()
                cur_tab = 6
                lua_menu.group_visibility()
            end),
        }

        lua_menu.checkboxes = {
            clantag             = ui.new_checkbox("AA", "Anti-Aimbot angles", "Clantag"),
            resolver            = ui.new_checkbox("AA", "Anti-Aimbot angles", "Resolver"),
            game_enhancer       = ui.new_checkbox("AA", "Anti-Aimbot angles", "Game Enhancer"),
            prediction          = ui.new_checkbox("AA", "Anti-Aimbot angles", "Predict Enemies"),
            logs                = ui.new_checkbox("AA", "Anti-Aimbot angles", "Logs"),
            console_filter      = ui.new_checkbox("AA", "Anti-Aimbot angles", "Console Filter"),
            fix_hideshots       = ui.new_checkbox("AA", "Anti-Aimbot angles", "Fix OSAA"),
            revolver_helper     = ui.new_checkbox("AA", "Anti-Aimbot angles", "Revolver Helper"),
            damage_indicator    = ui.new_checkbox("AA", "Anti-Aimbot angles", "Damage indicator"),
            damage_indicator_font = ui.new_combobox("AA", "Anti-Aimbot angles", "Damage indicator font", "Pixel", "Verdana"),
            animfix             = ui.new_multiselect("AA", "Anti-aimbot angles", "Anim Breakers", "Jitter legs on ground", "Body lean", "0 pitch on landing", "Static in Air", "Kangaroo")
        }


        lua_menu.discloser = {
            label5       = ui.new_label("AA", "Anti-Aimbot angles", "To make Micro yaw flicks work use"),
            label4       = ui.new_label("AA", "Anti-Aimbot angles", "\aFFFFFFFFDiscloser yaw type"),
            label6       =ui.new_label("AA", "Anti-Aimbot angles", "      "),
            micro_yaw    = ui.new_checkbox("AA", "Anti-Aimbot angles", "Micro yaw flicks"),
            first_flick  = ui.new_slider("AA", "Anti-Aimbot angles", "First angle", -30, 30, 0),
            second_flick = ui.new_slider("AA", "Anti-Aimbot angles", "Second angle", -30, 30, 0),
            fake_lag_addon = ui.new_checkbox("AA", "Anti-Aimbot angles", "Fake Lag Addons"),
            label1       = ui.new_label("AA", "Anti-Aimbot angles", "   "),
            label2       = ui.new_label("AA", "Anti-Aimbot angles", "\a696969FF ------------------------------------------"),
            label3       = ui.new_label("AA", "Anti-Aimbot angles", "     "),
            recharge_fix = ui.new_checkbox("AA", "Anti-Aimbot angles", "Recharge fix"),
            safehead     = ui.new_checkbox("AA", "Anti-Aimbot angles", "Safe Head"),
            e_spam       = ui.new_checkbox("AA", "Anti-Aimbot angles", "E-Spam"),
            legit_aa     = ui.new_checkbox("AA", "Anti-Aimbot angles", "Legit AA and Bombsite e-fix"),
            anti_stab       = ui.new_checkbox("AA", "Anti-Aimbot angles", "Avoid Backstab"),
            warmup_aa       = ui.new_checkbox("AA", "Anti-Aimbot angles", "Warmup AA"),
            label8       = ui.new_label("AA", "Anti-Aimbot angles", "     "),
            label7       = ui.new_label("AA", "Anti-Aimbot angles", "\a696969FF ------------------------------------------"),
            label9       = ui.new_label("AA", "Anti-Aimbot angles", "    "),
            freestand    = ui.new_hotkey("AA", "Anti-Aimbot angles", "Auto Direction"),
            left         = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Left"),
            right        = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Right"),
            forward        = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Forward"),
            edge_yaw     = ui.new_hotkey("AA", "Anti-Aimbot angles", "Edge Yaw")
        }

        lua_menu.aa = {
            state_selector = ui.new_combobox("AA", "Anti-Aimbot angles", "State selector", states)
        }

        lua_menu.group_visibility()
    end

    function lua_menu.group_visibility()
        ui.set_visible(lua_menu.buttons.back, cur_tab ~= 1))

        -- AA tab
        ui.set_visible(lua_menu.aa.state_selector, cur_tab == 2))

        -- Discloser tab
        ui.set_visible(lua_menu.discloser.micro_yaw, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label1, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label2, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label3, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label4, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label5, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label6, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.safehead, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.freestand, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.left, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.right, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.legit_aa, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.edge_yaw, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label8, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label7, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.label9, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.anti_stab, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.fake_lag_addon, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.warmup_aa, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.recharge_fix, cur_tab == 5))
        ui.set_visible(lua_menu.discloser.forward, cur_tab == 5))

        -- Visuals tab
        ui.set_visible(lua_menu.checkboxes.revolver_helper, cur_tab == 3))
        ui.set_visible(lua_menu.checkboxes.animfix, cur_tab == 3))
        ui.set_visible(lua_menu.checkboxes.damage_indicator, cur_tab == 3))
    
        -- Misc tab
        ui.set_visible(lua_menu.checkboxes.clantag, cur_tab == 4))
        ui.set_visible(lua_menu.checkboxes.resolver, cur_tab == 4))
        ui.set_visible(lua_menu.checkboxes.game_enhancer, cur_tab == 4))
        ui.set_visible(lua_menu.checkboxes.prediction, cur_tab == 4))
        ui.set_visible(lua_menu.checkboxes.logs, cur_tab == 4))
        ui.set_visible(lua_menu.checkboxes.fix_hideshots, cur_tab == 4))
        ui.set_visible(lua_menu.checkboxes.console_filter, cur_tab == 4))

        -- Main tab
        ui.set_visible(lua_menu.buttons.aa, cur_tab == 1))
        ui.set_visible(lua_menu.buttons.visuals, cur_tab == 1))
        ui.set_visible(lua_menu.buttons.misc, cur_tab == 1))
        ui.set_visible(lua_menu.buttons.discloser, cur_tab == 1))
        ui.set_visible(lua_menu.buttons.config, cur_tab == 1))
    end
end

lua_menu.init()

local function visuals_visibility()
    ui.set_visible(lua_menu.checkboxes.damage_indicator_font, ui.get(lua_menu.checkboxes.damage_indicator) and cur_tab == 3))

    ui.set_visible(lua_menu.discloser.first_flick, ui.get(lua_menu.discloser.micro_yaw) and cur_tab == 5))
    ui.set_visible(lua_menu.discloser.second_flick, ui.get(lua_menu.discloser.micro_yaw) and cur_tab == 5))
    ui.set_visible(lua_menu.discloser.e_spam, ui.get(lua_menu.discloser.safehead) and cur_tab == 5))
end
visuals_visibility()

for _, state_name in ipairs(states) do
    local prefix = "\a0FA6E0FF" .. state_name .. " \aC0C0C0FF"
    if state_name ~= "Global" )
        lua_menu.aa[state_name] = {
            allow          = ui.new_checkbox("AA", "Anti-Aimbot angles", "Allow " .. prefix),
            yaw_select     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw type", "180", "Delayed", "Layered", "Discloser"),
            yaw_180        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw", -180, 180, 0, true, "°"),
            yaw_l          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw left", -180, 180, 0, true, "°"),
            yaw_r          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw right", -180, 180, 0, true, "°"),
            yaw_d          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay", 1, 14, 1, true, "t"),
            yaw_rd         = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "randomize delay"),
            yaw_rds        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay", 1, 10, 1, true, "t"),
            yaw_jitter     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw jitter", "Off", "Offset", "Center", "Random", "Skitter"),
            yaw_jitter_value = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter value", -180, 180, 0, true, "°"),
            yaw_bodyselect = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "body yaw type", "Off", "GameSense", "Custom"),
            yaw_bodytype   = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "body yaw", "Static", "Jitter"),
            yaw_bodyvalue  = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "body yaw value", -60, 60, 0, true, "°"),
            break_type     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "break lc", "On Peek", "Always"),
            defensive_aa   = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "defensive anti-aim setup"),
            defensive_pitch = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive pitch", "Off", "Static", "Jitter"),
            defensive_pitch_slider = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive pitch angle", -89, 89, 0, true, "°"),
            defensive_pitch_slider_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive second pitch angle", -89, 89, 0, true, "°"),
            defensive_yaw = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive yaw", "Off", "Static", "Jitter", "Spin"),
            defensive_yaw_slider = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive yaw angle", -180, 180, 0, true, "°"),
            defensive_yaw_slider_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive second yaw angle", -180, 180, 0, true, "°"),
            defensive_yaw_speed = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive yaw speed", 1, 100, 0, true, "/s"),
        }
    else
        lua_menu.aa[state_name] = {
            yaw_select     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw type", "180", "Delayed", "Layered", "Discloser"),
            yaw_180        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw", -180, 180, 0, true, "°"),
            yaw_l          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw left", -180, 180, 0, true, "°"),
            yaw_r          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw right", -180, 180, 0, true, "°"),
            yaw_d          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay", 1, 14, 1, true, "t"),
            yaw_rd         = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "randomize delay"),
            yaw_rds        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "randomize value", 1, 10, 1, true, "t"),
            yaw_jitter     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw jitter", "Off", "Offset", "Center", "Random", "Skitter"),
            yaw_jitter_value = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter value", -180, 180, 0, true, "°"),
            yaw_bodyselect = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "body yaw type", "Off", "GameSense", "Custom"),
            yaw_bodytype   = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "body yaw", "Static", "Jitter"),
            yaw_bodyvalue  = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "body yaw value", -60, 60, 0, true, "°"),
            break_type     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "break lc", "On Peek", "Always"),
            defensive_aa   = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "defensive anti-aim setup"),
            defensive_pitch = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive pitch", "Off", "Static", "Jitter"),
            defensive_pitch_slider = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive pitch angle", -89, 89, 0, true, "°"),
            defensive_pitch_slider_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive second pitch angle", -89, 89, 0, true, "°"),
            defensive_yaw = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive yaw", "Off", "Static", "Jitter", "Spin"),
            defensive_yaw_slider = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive yaw angle", -180, 180, 0, true, "°"),
            defensive_yaw_slider_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive second yaw angle", -180, 180, 0, true, "°"),
            defensive_yaw_speed = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive yaw speed", 1, 100, 0, true, "/s"),
        }
    end
end

local function aa_visibility()
    local selected_state = ui.get(lua_menu.aa.state_selector)
    for _, state_name in ipairs(states) do
        local state = lua_menu.aa[state_name]
        local is_current = (state_name == selected_state and cur_tab == 2)
        local is_allowed = (state_name == "Global" or (state.allow and ui.get(state.allow))

        if state.allow then ui.set_visible(state.allow, is_current) end)
        if state.yaw_select )
            ui.set_visible(state.yaw_select, is_current and is_allowed))
        end
        if state.yaw_180 )
            ui.set_visible(state.yaw_180, is_current and is_allowed and (ui.get(state.yaw_select) == "180"))
        end
        if state.yaw_l )
            local sel = ui.get(state.yaw_select)
            ui.set_visible(state.yaw_l, is_current and is_allowed and (sel == "Delayed" or sel == "Layered" or sel == "Discloser"))
        end
        if state.yaw_r )
            local sel = ui.get(state.yaw_select)
            ui.set_visible(state.yaw_r, is_current and is_allowed and (sel == "Delayed" or sel == "Layered" or sel == "Discloser"))
        end
        if state.yaw_d )
            local sel = ui.get(state.yaw_select)
            ui.set_visible(state.yaw_d, is_current and is_allowed and (sel == "Delayed" or sel == "Discloser"))
        end
        if state.yaw_rd )
            local sel = ui.get(state.yaw_select)
            ui.set_visible(state.yaw_rd, is_current and is_allowed and (sel == "Delayed" or sel == "Discloser"))
        end
        if state.yaw_rds )
            local sel = ui.get(state.yaw_select)
            ui.set_visible(state.yaw_rds, is_current and is_allowed and (sel == "Delayed" or sel == "Discloser") and ui.get(state.yaw_rd))
        end
        if state.yaw_jitter )
            ui.set_visible(state.yaw_jitter, is_current and is_allowed and ui.get(state.yaw_select) ~= "Discloser"))
        end
        if state.yaw_jitter_value )
            ui.set_visible(state.yaw_jitter_value, is_current and is_allowed and ui.get(state.yaw_jitter) ~= "Off" and ui.get(state.yaw_select) ~= "Discloser"))
        end
        if state.yaw_bodyselect )
            ui.set_visible(state.yaw_bodyselect, is_current and is_allowed))
        end
        if state.yaw_bodytype )
            ui.set_visible(state.yaw_bodytype, is_current and is_allowed and ui.get(state.yaw_bodyselect) ~= "Off"))
        end
        if state.yaw_bodyvalue )
            ui.set_visible(state.yaw_bodyvalue, is_current and is_allowed and ui.get(state.yaw_bodyselect) ~= "Off"))
        end
        if state.break_type )
            ui.set_visible(state.break_type, is_current and is_allowed))
        end
        if state.defensive_aa )
            ui.set_visible(state.defensive_aa, is_current and is_allowed))
        end
        if state.defensive_pitch )
            ui.set_visible(state.defensive_pitch, is_current and is_allowed and ui.get(state.defensive_aa))
        end
        if state.defensive_yaw )
            ui.set_visible(state.defensive_yaw, is_current and is_allowed and ui.get(state.defensive_aa))
        end
        if state.defensive_pitch_slider )
            ui.set_visible(state.defensive_pitch_slider, is_current and is_allowed and ui.get(state.defensive_aa) and (ui.get(state.defensive_pitch) == "Static" or ui.get(state.defensive_pitch) == "Jitter"))
        end
        if state.defensive_pitch_slider_2 )
            ui.set_visible(state.defensive_pitch_slider_2, is_current and is_allowed and ui.get(state.defensive_aa) and ui.get(state.defensive_pitch) == "Jitter"))
        end
        if state.defensive_yaw_slider )
            ui.set_visible(state.defensive_yaw_slider, is_current and is_allowed and ui.get(state.defensive_aa) and (ui.get(state.defensive_yaw) == "Static" or ui.get(state.defensive_yaw) == "Jitter"))
        end
        if state.defensive_yaw_slider_2 )
            ui.set_visible(state.defensive_yaw_slider_2, is_current and is_allowed and ui.get(state.defensive_aa) and (ui.get(state.defensive_yaw) == "Jitter"))
        end
        if state.defensive_yaw_speed )
            ui.set_visible(state.defensive_yaw_speed, is_current and is_allowed and ui.get(state.defensive_aa) and (ui.get(state.defensive_yaw) == "Spin"))
        end
    end
end

aa_visibility()
---@lua_menu_end

---@anti-aim handle
local pred_value = { chokedcommands = 1, silent_shift = 1, tickcount = 1 }
local command_number = 1

local function update_command_number(cmd)
    command_number = cmd.command_number
end

local function update_pred_value(cmd)
    pred_value.chokedcommands = cmd.chokedcommands
    pred_value.silent_shift = cvar.sv_maxusrcmdprocessticks:get_float() - pred_value.chokedcommands - 1
    pred_value.tickcount = globals.tickcount()
end

local jitter_switch, delay_timer = false, 0

local function delayjitter(switchyaw1, switchyaw2, speed, yawrandom)
    speed = speed + 1
    local random_left  = math.random(0, switchyaw1 * yawrandom / 100)
    local random_right = math.random(0, switchyaw2 * yawrandom / 100)

    if globals.chokedcommands() == 0 and (command_number % 2 >= math.abs(math.sin(globals.chokedcommands()) )
        delay_timer = delay_timer + 1
        if delay_timer % speed == 0 )
            jitter_switch = not jitter_switch
        end
    end

    local final_yaw = jitter_switch and (switchyaw1 + random_left) or (switchyaw2 - random_right)
    return tools.clamp(final_yaw, -180, 180)
end

is_on_ground = false
local function get_player_state(cmd)
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) )
        return "Unknown"
    end

    local vecvelocity = { entity.get_prop(lp, 'm_vecVelocity') }
    local flags = entity.get_prop(lp, 'm_fFlags')
    local velocity = vector(entity.get_prop(lp, "m_vecAbsVelocity"):length2d())
    local in_grounded = bit.band(flags, 1) == 1
    local jump = bit.band(flags, 1) == 0 or cmd.in_jump == 1
    local ducked = entity.get_prop(lp, 'm_flDuckAmount') > 0.7
    local duck = ducked
    local is_slowwalk = ui.get(ref.slow_walk[1]) and ui.get(ref.slow_walk[2])
    is_on_ground = in_grounded

    if jump and duck )
        return "Air-Duck"
    elseif jump )
        return "Air"
    elseif duck and velocity > 10 )
        return "Duck-Running"
    elseif duck and velocity < 10 )
        return "Duck"
    elseif in_grounded and is_slowwalk and velocity > 10 )
        return "Slow-walk"
    elseif in_grounded and velocity > 5 )
        return "Running"
    elseif in_grounded and velocity < 5 )
        return "Stand"
    else
        return "Unknown"
    end
end

---@defensive check
local defensive_system = {
    ticks_count = 0,
    max_tick_base = 0,
    is_defensive = false
}

local function defensiveCheck(cmd)

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end

    local current_tick = globals.tickcount()
    local tick_base = entity.get_prop(lp, "m_nTickBase") or 0
    local can_exploit = current_tick > tick_base

    if math.abs(tick_base - defensive_system.max_tick_base) > 64 and can_exploit )
        defensive_system.max_tick_base = 0
    end

    if tick_base > defensive_system.max_tick_base )
        defensive_system.max_tick_base = tick_base
    elseif defensive_system.max_tick_base > tick_base )
        defensive_system.ticks_count = can_exploit and math.min(14, math.max(0, defensive_system.max_tick_base - tick_base - 1) or 0
    end

    defensive_system.is_defensive = (defensive_system.ticks_count > 2
        and defensive_system.ticks_count < 13)
end

local defensive_data = {
    pitch = 0,
    yaw = 0
}

local current_tick = tools.time_to_ticks(globals.realtime())
local function on_setup_command(cmd)
    cmd.allow_send_packet = true
    ui_set_smart(ref.enabled, true)
    ui_set_smart(ref.yaw_base, "At Targets")
    ui_set_smart(ref.pitch[1], "Minimal")
    ui_set_smart(ref.yaw[1], "180")
    ui_set_smart(ref.yaw_jitter[1], "Off")
    ui_set_smart(ref.freestanding_body_yaw, false)

    local condition = get_player_state(cmd)
    local settings = lua_menu.aa[condition]
    if not settings or (condition ~= "Global" and not ui.get(settings.allow) )
        settings = lua_menu.aa["Global"]
    end

    if not entity.is_alive(entity.get_local_player() )
        return 
    end

    local yawSelect   = ui.get(settings.yaw_select)
    local yaw_l       = ui.get(settings.yaw_l)
    local yaw_r       = ui.get(settings.yaw_r)
    local yaw_d       = ui.get(settings.yaw_d)
    local yaw_rd      = ui.get(settings.yaw_rd)
    local yaw_rds     = ui.get(settings.yaw_rds)
    local delay_total = yaw_rd and (yaw_d + math.random(0, yaw_rds)) or yaw_d
    local switch_ticks = tools.time_to_ticks(globals.realtime() - current_tick)
    local switch

    if yawSelect == "180" )
        ui_set_smart(ref.yaw[2], ui.get(settings.yaw_180))
    elseif yawSelect == "Delayed" or yawSelect == "Discloser" )
        ui_set_smart(ref.yaw[2], delayjitter(yaw_l, yaw_r, delay_total, 0))
    elseif yawSelect == "Layered" )
        if switch_ticks * 2 >= 3 )
            switch = true
        else
            switch = false
        end
        if switch_ticks >= 3 )
            current_tick = tools.time_to_ticks(globals.realtime()
        end
        ui_set_smart(ref.yaw[2], switch and yaw_l or yaw_r)
    end

    local bodySelect = ui.get(settings.yaw_bodyselect)
    local bodyType   = ui.get(settings.yaw_bodytype)
    local bodyValue  = ui.get(settings.yaw_bodyvalue)

    if bodySelect == "GameSense" )
        if bodyType == "Jitter" )
            if yawSelect == "Delayed" or yawSelect == "Discloser" )
                ui_set_smart(ref.body_yaw[1], "Static")
                ui_set_smart(ref.body_yaw[2], delayjitter(-bodyValue, bodyValue, delay_total, 0))
            elseif yawSelect == "Layered" )
                ui_set_smart(ref.body_yaw[1], "Static")
                ui_set_smart(ref.body_yaw[2], switch and -bodyValue or bodyValue)
            else
                ui_set_smart(ref.body_yaw[1], "Static")
                ui_set_smart(ref.body_yaw[2], delayjitter(-bodyValue, bodyValue, 1, 0))
            end
        elseif bodyType == "Static" )
            ui.set(ref.body_yaw[1], "Static")
            ui.set(ref.body_yaw[2], bodyValue)
        end
    elseif bodySelect == "Off" )
        ui.set(ref.body_yaw[1], "Off")
    elseif bodySelect == "Custom" )
        if bodyType == "Static" )
            ui_set_smart(ref.body_yaw[1], "Static")
            local custom_val = ((not ui.get(ref.dt[2]) and not ui.get(ref.hs[2]) or ui.get(ref.fd) and bodyValue) or 0
            ui_set_smart(ref.body_yaw[2], custom_val)
            if globals.chokedcommands() > 0 )
                cmd.allow_send_packet = true
            else
                cmd.allow_send_packet = false
                ui_set_smart(ref.yaw[2], -bodyValue)
            end
        elseif bodyType == "Jitter" )
            if yawSelect == "Delayed" )
                ui_set_smart(ref.body_yaw[1], "Static")
                local jitter_val = (not ui.get(ref.dt[2]) and not ui.get(ref.hs[2]) or ui.get(ref.fd)
                                  and delayjitter(-bodyValue, bodyValue, delay_total, 0) or 0
                ui_set_smart(ref.body_yaw[2], jitter_val)
                if globals.chokedcommands() > 0 )
                    cmd.allow_send_packet = true
                else
                    cmd.allow_send_packet = false
                    ui_set_smart(ref.yaw[2], delayjitter(bodyValue, -bodyValue, delay_total, 0))
                end
            elseif yawSelect == "Discloser" )
                ui_set_smart(ref.body_yaw[1], "Static")
                local jitter_val = (not ui.get(ref.dt[2]) and not ui.get(ref.hs[2]) or ui.get(ref.fd)
                                  and delayjitter(-bodyValue, bodyValue, delay_total, 0) or 0
                ui_set_smart(ref.body_yaw[2], jitter_val)
                if globals.chokedcommands() > 0 )
                    cmd.allow_send_packet = true
                else
                    cmd.allow_send_packet = false
                    ui_set_smart(ref.yaw[2], delayjitter(bodyValue, -bodyValue, delay_total, 0))
                end
            elseif yawSelect == "Layered" )
                ui_set_smart(ref.body_yaw[1], "Static")
                local condition = (not ui.get(ref.dt[2]) and not ui.get(ref.hs[2]) or ui.get(ref.fd)
                local layered_val = condition and (switch and -bodyValue or bodyValue) or 0
                ui_set_smart(ref.body_yaw[2], layered_val)
                if globals.chokedcommands() > 0 )
                    cmd.allow_send_packet = true
                else
                    cmd.allow_send_packet = false
                    ui_set_smart(ref.yaw[2], switch and -bodyValue or bodyValue)
                end
            else
                ui_set_smart(ref.body_yaw[1], "Static")
                local jitter_val = (not ui.get(ref.dt[2]) and not ui.get(ref.hs[2]) or ui.get(ref.fd)
                                  and delayjitter(-bodyValue, bodyValue, 1, 0) or 0
                ui_set_smart(ref.body_yaw[2], jitter_val)
                if globals.chokedcommands() > 0 )
                    cmd.allow_send_packet = true
                else
                    cmd.allow_send_packet = false
                    ui_set_smart(ref.yaw[2], delayjitter(bodyValue, -bodyValue, 1, 0))
                end
            end
        end
    end

    if yawSelect ~= "Discloser" )
        ui_set_smart(ref.yaw_jitter[1], ui.get(settings.yaw_jitter))
        ui_set_smart(ref.yaw_jitter[2], ui.get(settings.yaw_jitter_value))
    end

    if yawSelect == "Discloser" )
        if ui.get(lua_menu.discloser.micro_yaw) )
            if globals.chokedcommands() > 0 )
                ui_set_smart(ref.yaw_jitter[1], "Random")
                ui_set_smart(ref.yaw_jitter[2], ui.get(lua_menu.discloser.first_flick))
            else
                ui_set_smart(ref.yaw_jitter[1], "Offset")
                ui_set_smart(ref.yaw_jitter[2], ui.get(lua_menu.discloser.second_flick))
            end
        end
    end

    ---defensive aa
    local break_   = ui.get(settings.break_type)

    cmd.force_defensive = break_ == "Always" and true or false

    if ui.get(settings.defensive_aa) )
        if ui.get(settings.defensive_pitch) == "Static" )
            defensive_data.pitch = ui.get(settings.defensive_pitch_slider)
        elseif ui.get(settings.defensive_pitch) == "Jitter" )
            defensive_data.pitch = delayjitter(ui.get(settings.defensive_pitch_slider), ui.get(settings.defensive_pitch_slider_2), delay_total, 0)
        end

        if ui.get(settings.defensive_yaw) == "Static" )
            defensive_data.yaw = ui.get(settings.defensive_yaw_slider)
        elseif ui.get(settings.defensive_yaw) == "Jitter" )
            defensive_data.yaw = delayjitter(ui.get(settings.defensive_yaw_slider), ui.get(settings.defensive_yaw_slider_2), delay_total, 0)
        elseif ui.get(settings.defensive_yaw) == "Spin" )
            defensive_data.yaw = ui.get(settings.defensive_yaw_speed)
        end
    end

    if defensive_system.is_defensive and ui.get(settings.defensive_aa) )
        ui.set(ref.yaw_jitter[1], "Off")
        if ui.get(settings.defensive_pitch) ~= "Off" )
            ui_set_smart(ref.pitch[1], "Custom")
            ui_set_smart(ref.pitch[2], defensive_data.pitch)
        end
        if ui.get(settings.defensive_yaw) ~= "Off" and ui.get(settings.defensive_yaw) ~= "Spin" )
            ui_set_smart(ref.yaw[1], "180")
            ui_set_smart(ref.yaw[2], defensive_data.yaw)
        elseif ui.get(settings.defensive_yaw) == "Spin" )
            ui_set_smart(ref.yaw[1], "Spin")
            ui_set_smart(ref.yaw[2], defensive_data.yaw)
        end
    end
end
---@end

---@freestand
local function freestanding()    
    if ui.get(lua_menu.discloser.freestand) )
        ui_set_smart(ref.freestand[1], true)   
        ui_set_smart(ref.freestand[2], "Always On")
    else
        ui_set_smart(ref.freestand[1], false)
        ui_set_smart(ref.freestand[2], "On Hotkey")
    end
end
---@end

---@safehead
local function safehead(cmd)
    if not ui.get(lua_menu.discloser.safehead) )
        return
    end
    local player = entity.get_local_player()
    if not player or not entity.is_alive(player) )
        return
    end

    local state = get_player_state(cmd)
    if state == "Air-Duck" )
        local active_weapon = entity.get_prop(player, "m_hActiveWeapon")
        if active_weapon and entity.get_classname(active_weapon) == "CKnife" )
            ui.set(ref.yaw[1], "180")
            ui.set(ref.yaw[2], 0)
            ui.set(ref.body_yaw[2], -60)
            ui.set(ref.pitch[2], 89)
            ui.set(ref.yaw_jitter[1], "Off")
            if ui.get(lua_menu.discloser.e_spam) )
                cmd.force_defensive = true
                if defensive_system.is_defensive )
                    ui.set(ref.yaw[1], "180")
                    ui.set(ref.yaw[2], -180)
                    ui.set(ref.pitch[1], "Custom")
                    ui.set(ref.pitch[2], math.random(-2, 2))
                end
            end
        end
    end
end
---@end

---@manual
local yaw_direction = 0
local last_press_t_dir = 0

local yawDirectionMapping = {
    { keyFunc = function() return ui.get(lua_menu.discloser.right) end, value = 90 },
    { keyFunc = function() return ui.get(lua_menu.discloser.left) end, value = -90 },
    { keyFunc = function() return ui.get(lua_menu.discloser.forward) end, value = -180 }
}

local function manual_yaw()
    local curtime = globals.curtime()
    
    for _, mapping in ipairs(yawDirectionMapping) do
        if mapping.keyFunc() and (last_press_t_dir + 0.13 < curtime) )
            yaw_direction = (yaw_direction == mapping.value) and 0 or mapping.value
            last_press_t_dir = curtime
            break
        end
    end

    if last_press_t_dir > curtime )
        last_press_t_dir = curtime
    end

    if yaw_direction ~= 0 )
        ui.set(ref.yaw_base, "Local view")
        ui.set(ref.yaw[1], "180")
        ui.set(ref.yaw[2], yaw_direction)
        ui.set(ref.yaw_jitter[1], "Off")
    end
end
---@end


---
---@manual indicators
local manual_arrow_cache = {
    last_direction = 0,
    last_scope_state = false,
    last_screen_size = {0, 0},
    cached_positions = {}
}

local function render_manual()
    local screenW, screenH = client.screen_size()
    local centerX, centerY = screenW / 2, screenH / 2
    local lp = entity.get_local_player()
    local isScoped = lp and (entity.get_prop(lp, "m_bIsScoped") == 1)

    if yaw_direction == 0 then return end

    local cache_empty = not manual_arrow_cache.cached_positions or (next(manual_arrow_cache.cached_positions) == nil)

    local needs_update = cache_empty or
        manual_arrow_cache.last_direction ~= yaw_direction or
        manual_arrow_cache.last_scope_state ~= isScoped or
        manual_arrow_cache.last_screen_size[1] ~= screenW or
        manual_arrow_cache.last_screen_size[2] ~= screenH

    if needs_update )
        local scope_offset = isScoped and 30 or 0
        local base_offset = 60
        local arrowWidth, arrowHeight = 20, 20

        local cx, cy
        local pos = {}

        if yaw_direction == -90 )
            cx = centerX - base_offset
            cy = centerY - scope_offset
            pos = {
                tipX = cx - arrowWidth / 2,
                tipY = cy,
                topX = cx + arrowWidth / 2,
                topY = cy - arrowHeight / 2,
                bottomX = cx + arrowWidth / 2,
                bottomY = cy + arrowHeight / 2
            }
        elseif yaw_direction == 90 )
            cx = centerX + base_offset
            cy = centerY - scope_offset
            pos = {
                tipX = cx + arrowWidth / 2,
                tipY = cy,
                topX = cx - arrowWidth / 2,
                topY = cy - arrowHeight / 2,
                bottomX = cx - arrowWidth / 2,
                bottomY = cy + arrowHeight / 2
            }
        elseif yaw_direction == -180 or yaw_direction == 180 )
            cx = centerX
            cy = centerY - base_offset - scope_offset
            pos = {
                tipX = cx,
                tipY = cy - arrowHeight / 2,
                leftX = cx - arrowWidth / 2,
                leftY = cy + arrowHeight / 2,
                rightX = cx + arrowWidth / 2,
                rightY = cy + arrowHeight / 2
            }
        else
            cx = centerX
            cy = centerY - base_offset - scope_offset
            pos = {
                tipX = cx,
                tipY = cy - arrowHeight / 2,
                leftX = cx - arrowWidth / 2,
                leftY = cy + arrowHeight / 2,
                rightX = cx + arrowWidth / 2,
                rightY = cy + arrowHeight / 2
            }
        end

        manual_arrow_cache.cached_positions = pos
        manual_arrow_cache.last_direction = yaw_direction
        manual_arrow_cache.last_scope_state = isScoped
        manual_arrow_cache.last_screen_size = {screenW, screenH}
    end

    local pos = manual_arrow_cache.cached_positions
    if not pos or next(pos) == nil )
        return
    end

    local r, g, b, a = 255, 255, 255, 255

    if yaw_direction == -90 or yaw_direction == 90 )
        if pos.tipX and pos.topX and pos.bottomX )
            renderer.line(pos.tipX, pos.tipY, pos.topX, pos.topY, r, g, b, a)
            renderer.line(pos.topX, pos.topY, pos.bottomX, pos.bottomY, r, g, b, a)
            renderer.line(pos.bottomX, pos.bottomY, pos.tipX, pos.tipY, r, g, b, a)
        end
    elseif yaw_direction == -180 or yaw_direction == 180 )
        if pos.tipX and pos.leftX and pos.rightX )
            renderer.line(pos.tipX, pos.tipY, pos.leftX, pos.leftY, r, g, b, a)
            renderer.line(pos.leftX, pos.leftY, pos.rightX, pos.rightY, r, g, b, a)
            renderer.line(pos.rightX, pos.rightY, pos.tipX, pos.tipY, r, g, b, a)
        end
    end
end


    -- Check if we need to recalculate positions
    local needs_update = (
        manual_arrow_cache.last_direction ~= yaw_direction or
        manual_arrow_cache.last_scope_state ~= isScoped or
        manual_arrow_cache.last_screen_size[1] ~= screenW or
        manual_arrow_cache.last_screen_size[2] ~= screenH
    )

    -- Cache positions if needed
    if needs_update )
        local scope_offset = isScoped and 30 or 0
        local base_offset = 60
        local arrowWidth, arrowHeight = 20, 20

        if yaw_direction == -90 )
            -- Left arrow
            local cx = centerX - base_offset
            local cy = centerY - scope_offset
            manual_arrow_cache.cached_positions = {
                tipX = cx - arrowWidth / 2,
                tipY = cy,
                topX = cx + arrowWidth / 2,
                topY = cy - arrowHeight / 2,
                bottomX = cx + arrowWidth / 2,
                bottomY = cy + arrowHeight / 2
            }
        elseif yaw_direction == 90 )
            -- Right arrow
            local cx = centerX + base_offset
            local cy = centerY - scope_offset
            manual_arrow_cache.cached_positions = {
                tipX = cx + arrowWidth / 2,
                tipY = cy,
                topX = cx - arrowWidth / 2,
                topY = cy - arrowHeight / 2,
                bottomX = cx - arrowWidth / 2,
                bottomY = cy + arrowHeight / 2
            }
        elseif yaw_direction == -180 )
            -- Forward arrow (up)
            local cx = centerX
            local cy = centerY - base_offset - scope_offset
            manual_arrow_cache.cached_positions = {
                tipX = cx,
                tipY = cy - arrowHeight / 2,
                leftX = cx - arrowWidth / 2,
                leftY = cy + arrowHeight / 2,
                rightX = cx + arrowWidth / 2,
                rightY = cy + arrowHeight / 2
            }
        end

        -- Update cache
        manual_arrow_cache.last_direction = yaw_direction
        manual_arrow_cache.last_scope_state = isScoped
        manual_arrow_cache.last_screen_size = {screenW, screenH}
    end

    -- Use cached positions for stable rendering
    local pos = manual_arrow_cache.cached_positions
    local r, g, b, a = 255, 255, 255, 255

    if yaw_direction == -90 or yaw_direction == 90 )
        -- Left or Right arrow
        renderer.line(pos.tipX, pos.tipY, pos.topX, pos.topY, r, g, b, a)
        renderer.line(pos.topX, pos.topY, pos.bottomX, pos.bottomY, r, g, b, a)
        renderer.line(pos.bottomX, pos.bottomY, pos.tipX, pos.tipY, r, g, b, a)
    elseif yaw_direction == -180 )
        -- Forward arrow (up)
        renderer.line(pos.tipX, pos.tipY, pos.leftX, pos.leftY, r, g, b, a)
        renderer.line(pos.leftX, pos.leftY, pos.rightX, pos.rightY, r, g, b, a)
        renderer.line(pos.rightX, pos.rightY, pos.tipX, pos.tipY, r, g, b, a)
    end
---@end

---@clantag
local clan_tags = {"", "V", "V ", "V O", "V O ", "V O I", "V O I ", "V O I D", "V O I ", "V O I", "V O ", "V O", "V ", "V"}
local last_step = -1
local frame_interval = 16
local last_sent_tag = ""

local function clantag()
    local enabled = ui.get(lua_menu.checkboxes.clantag)
    local server_tick = globals.tickcount()
    local current_step = math.floor(server_tick / frame_interval)

    if not enabled )
        if last_step ~= -1 )
            client.set_clan_tag("")
            last_step = -1
            last_sent_tag = ""
        end
        return
    end
    
    if last_step == current_step then return end
    
    local new_index = (current_step % #clan_tags) + 1
    local tag = clan_tags[new_index]
    if tag ~= last_sent_tag )
        client.set_clan_tag(tag)
        last_sent_tag = tag
    end
    last_step = current_step
end
---@end


---@config_system

local function export_config()
    local config_data = {
        aa = {},
        discloser = {
            micro_yaw = ui.get(lua_menu.discloser.micro_yaw),
            first_flick = ui.get(lua_menu.discloser.first_flick),
            second_flick = ui.get(lua_menu.discloser.second_flick),
            safehead = ui.get(lua_menu.discloser.safehead),
            espam = ui.get(lua_menu.discloser.e_spam),
            legitaa = ui.get(lua_menu.discloser.legit_aa),
            anti_stab = ui.get(lua_menu.discloser.anti_stab),
            fake_lag_addon = ui.get(lua_menu.discloser.fake_lag_addon),
            warmup_aa = ui.get(lua_menu.discloser.warmup_aa)
        },
        visuals = {
            revolver_helper = ui.get(lua_menu.checkboxes.revolver_helper),
            animfix = ui.get(lua_menu.checkboxes.animfix)
        },
        misc = {
            clantag = ui.get(lua_menu.checkboxes.clantag),
            resolver = ui.get(lua_menu.checkboxes.resolver),
            game_enhancer = ui.get(lua_menu.checkboxes.game_enhancer),
            prediction = ui.get(lua_menu.checkboxes.prediction),
            logs = ui.get(lua_menu.checkboxes.logs),
            fix_hideshots = ui.get(lua_menu.checkboxes.fix_hideshots)
        }
    }

    for _, state_name in ipairs(states) do
        local state_config = {}
        
        if state_name ~= "Global" )
            state_config.allow = ui.get(lua_menu.aa[state_name].allow)
        end

        local ui_elements = {
            "yaw_select", "yaw_180", "yaw_l", "yaw_r", "yaw_d", "yaw_rd", "yaw_rds", 
            "yaw_jitter", "yaw_jitter_value", "yaw_bodyselect", "yaw_bodytype", 
            "yaw_bodyvalue", "break_type", "defensive_aa", "defensive_pitch", 
            "defensive_pitch_slider", "defensive_pitch_slider_2", "defensive_yaw", 
            "defensive_yaw_slider", "defensive_yaw_slider_2", "defensive_yaw_speed"
        }

        for _, element in ipairs(ui_elements) do
            state_config[element] = ui.get(lua_menu.aa[state_name][element])
        end

        config_data.aa[state_name] = state_config
    end
   
    local json_data = json.stringify(config_data)
    local base64_data = base64.encode(json_data)
    clipboard.set(base64_data)
end

local function import_config(base64_data)
    local json_data = base64.decode(base64_data or clipboard.get())
    local config_data = json.parse(json_data)

    for k, v in pairs(config_data.discloser or {}) do
        if lua_menu.discloser[k] )
            ui.set(lua_menu.discloser[k], v)
        end
    end

    for k, v in pairs(config_data.visuals or {}) do
        if lua_menu.checkboxes[k] )
            ui.set(lua_menu.checkboxes[k], v)
        end
    end

    for k, v in pairs(config_data.misc or {}) do
        if lua_menu.checkboxes[k] )
            ui.set(lua_menu.checkboxes[k], v)
        end
    end
    
    for _, state_name in ipairs(states) do
        local state_config = config_data.aa and config_data.aa[state_name] or {}

        if state_name ~= "Global" and state_config.allow ~= nil )
            ui.set(lua_menu.aa[state_name].allow, state_config.allow)
        end

        local ui_elements = {
            "yaw_select", "yaw_180", "yaw_l", "yaw_r", "yaw_d", "yaw_rd", "yaw_rds", 
            "yaw_jitter", "yaw_jitter_value", "yaw_bodyselect", "yaw_bodytype", 
            "yaw_bodyvalue", "break_type", "defensive_aa", "defensive_pitch", 
            "defensive_pitch_slider", "defensive_pitch_slider_2", "defensive_yaw", 
            "defensive_yaw_slider", "defensive_yaw_slider_2", "defensive_yaw_speed"
        }

        for _, element in ipairs(ui_elements) do
            if state_config[element] ~= nil and lua_menu.aa[state_name][element] )
                ui.set(lua_menu.aa[state_name][element], state_config[element])
            end
        end
    end
end
import = ui.new_button("AA", "Anti-Aimbot angles", "Import", function() import_config() end)
export = ui.new_button("AA", "Anti-Aimbot angles", "Export", function() export_config() end)

local function config_visibillity()
    ui.set_visible(import, cur_tab == 6))
    ui.set_visible(export, cur_tab == 6))
end
config_visibillity()
---@end

---@e fix + legit AA-s
classnames = {
"CWorld",
"CCSPlayer",
"CFuncBrush"
}
local function distance3d(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1))
end

local function entity_has_c4(ent)
	local bomb = entity.get_all("CC4")[1]
	return bomb ~= nil and entity.get_prop(bomb, "m_hOwnerEntity") == ent
end

local function aa_on_use(cmd)
	if ui.get(lua_menu.discloser.legit_aa) )
        if cmd.in_use == 1 )
            ui.set(ref.pitch[1], "Off")
            ui.set(ref.yaw_base, "Local view")
            ui.set(ref.yaw[1], "180")
            ui.set(ref.yaw[2], 180)
            ui.set(ref.yaw_jitter[1], "Offset")
            ui.set(ref.yaw_jitter[2], 0)
            ui.set(ref.body_yaw[1], "Opposite")
            ui.set(ref.freestanding_body_yaw, true)
        end

		local plocal = entity.get_local_player()
		
		local distance = 100
		local bomb = entity.get_all("CPlantedC4")[1]
		local bomb_x, bomb_y, bomb_z = entity.get_prop(bomb, "m_vecOrigin")

		if bomb_x ~= nil )
			local player_x, player_y, player_z = entity.get_prop(plocal, "m_vecOrigin")
			distance = distance3d(bomb_x, bomb_y, bomb_z, player_x, player_y, player_z)
		end
		
		local team_num = entity.get_prop(plocal, "m_iTeamNum")
		local defusing = team_num == 3 and distance < 62

		local on_bombsite = entity.get_prop(plocal, "m_bInBombZone")

		local has_bomb = entity_has_c4(plocal)
        local cat = 3
		local trynna_plant = on_bombsite ~= 0 and team_num == 2 and has_bomb and cat ~= 3
		
		local px, py, pz = client.eye_position()
		local pitch, yaw = client.camera_angles()
	
		local sin_pitch = math.sin(math.rad(pitch))
		local cos_pitch = math.cos(math.rad(pitch))
		local sin_yaw = math.sin(math.rad(yaw))
		local cos_yaw = math.cos(math.rad(yaw))

		local dir_vec = { cos_pitch * cos_yaw, cos_pitch * sin_yaw, -sin_pitch }

		local fraction, entindex = client.trace_line(plocal, px, py, pz, px + (dir_vec[1] * 8192), py + (dir_vec[2] * 8192), pz + (dir_vec[3] * 8192))

		local using = true

		for i=0, #classnames do
			if entity.get_classname(entindex) == classnames[i] )
				using = false
			end
		end

		if not using and not trynna_plant and not defusing )
			cmd.in_use = 0
		end
	end
end
---@end

---@revolver helper
local function is_revolver(weapon)
	local weapon_id = entity.get_prop(weapon, "m_iItemDefinitionIndex")
	return weapon_id == 64
end

local function check_revolver_distance3d(player, victim)
	if player == nil or victim == nil then return 0 end

	local weapon = entity.get_prop(player, "m_hActiveWeapon")
	if weapon == nil or not is_revolver(weapon) then return 0 end

	local player_x, player_y, player_z = entity.get_origin(player)
	local victim_x, victim_y, victim_z = entity.get_origin(victim)

	if player_x == nil or victim_x == nil )
		return 0
	end

	local units = distance3d(player_x, player_y, player_z, victim_x, victim_y, victim_z)
	local no_kevlar = entity.get_prop(victim, "m_ArmorValue") == 0
	local height_difference = player_z - victim_z

	if height_difference > 100 and units < 300 )
		return "DMG+"
	elseif units > 585 )
		return "DMG-"
	elseif units < 585 and units > 511 )
		return "DMG"
	elseif units <= 511 and no_kevlar )
		return "DMG+"
	else
		return "DMG"
	end
end

local function draw_status(player, status)
	local x1, y1, x2, y2, alpha_multiplier = entity.get_bounding_box(player)

	if x1 == nil or alpha_multiplier == 0 )
		return
	end
	
	local x_center = (x1 + x2) / 2
	local y_position = y1 - 20

	local color = {255, 0, 0}
	if status == "DMG" )
		color = {255, 255, 0}
	elseif status == "DMG+" )
		color = {50, 205, 50}
	end

	renderer.text(x_center, y_position, color[1], color[2], color[3], 255, "cb", 0, status)
end

local function rev_helper()
    if not ui.get(lua_menu.checkboxes.revolver_helper) then return end
   
    local lp = entity.get_local_player()
    if lp == nil or not entity.is_alive(lp) then return end
   
    local weapon = entity.get_prop(lp, "m_hActiveWeapon")
    if weapon == nil or not is_revolver(weapon) )
        return
    end
    
    -- Use filtered enemies and limit to 3 closest for performance
    local players = get_enemies_filtered()
    if #players == 0 )
        return
    end
    
    -- Sort by distance and only process closest 3
    local lp_pos = { entity.get_origin(lp) }
    local sorted_players = {}
    for i = 1, #players do
        local ent = players[i]
        local ent_pos = { entity.get_origin(ent) }
        if ent_pos[1] )
            local dist = math.sqrt((ent_pos[1] - lp_pos[1])^2 + (ent_pos[2] - lp_pos[2])^2 + (ent_pos[3] - lp_pos[3])^2)
            table.insert(sorted_players, { ent = ent, dist = dist })
        end
    end
    
    table.sort(sorted_players, function(a, b) return a.dist < b.dist end)
    
    for i = 1, math.min(3, #sorted_players) do
        local entindex = sorted_players[i].ent
        local status = check_revolver_distance3d(lp, entindex)
        if status ~= 0 )
            draw_status(entindex, status)
        end
    end
end
---@end

---@region animfix

local function animfix_setup()
    local animfix_values = ui.get(lua_menu.checkboxes.animfix)
    local self = entity.get_local_player()
    if not self or not entity.is_alive(self) )
        return
    end

    local self_index = c_entity.new(self)
    local self_anim_state = self_index:get_anim_state()


    if not self_anim_state )
        return
    end

    if contains(animfix_values, "Body lean") )
        local self_anim_overlay = self_index:get_anim_overlay(12)
        if not self_anim_overlay )
            return
        end
        local x_velocity = entity.get_prop(self, "m_vecVelocity[0]")
        if math.abs(x_velocity) >= 3 )
            self_anim_overlay.weight = 1
        end
    end

    if contains(animfix_values, "Jitter legs on ground") and is_on_ground )
        ui.set(ui.reference("AA", "other", "leg movement"), command_number % 3 == 0 and "Off" or "Always slide")
        entity.set_prop(self, "m_flPoseParameter", 1, globals.tickcount() % 4 > 1 and 5 / 10 or 1)

    end

    if contains(animfix_values, "Static in Air") and not is_on_ground )
        entity.set_prop(self, "m_flPoseParameter", 1 , 6)

    end

    if contains(animfix_values, "Kangaroo") )
        entity.set_prop(self, "m_flPoseParameter", math.random(0, 10)/10, 3)
        entity.set_prop(self, "m_flPoseParameter", math.random(0, 10)/10, 7)
        entity.set_prop(self, "m_flPoseParameter", math.random(0, 10)/10, 6)

    end

    if contains(animfix_values, "0 pitch on landing") )
        if not self_anim_state.hit_in_ground_animation or not is_on_ground )
            return
        end

        entity.set_prop(self, "m_flPoseParameter", 0.5, 12)
    end
end
---@end

---@edge yaw
local function edge_yaw()
    ui.set(ref.edge_yaw, ui.get(lua_menu.discloser.edge_yaw))
end
---@end

---@resolver
local resolver = {
    enabled = false,
    data = {},
    last_targets = {},
    miss_count = {},
    last_hit_time = {},
    prediction_data = {}
}

-- Helper functions based on aimtools.lua
local function approach_angle(target, value, speed)
    local delta = target - value
    if delta > 180 then delta = delta - 360 end
    if delta < -180 then delta = delta + 360 end
    if delta > speed then return value + speed end
    if delta < -speed then return value - speed end
    return target
end

local function angle_diff(angle1, angle2)
    local diff = angle1 - angle2
    while diff > 180 do diff = diff - 360 end
    while diff < -180 do diff = diff + 360 end
    return diff
end

local function get_side(entindex, animlayer)
    if not animlayer then return 0 end
    
    local cycle = animlayer.cycle or 0
    local weight = animlayer.weight or 0
    
    if weight > 0.5 )
        if cycle > 0.5 )
            return 1 -- right
        else
            return -1 -- left
        end
    end
    
    -- Additional side detection using velocity
    local player = c_entity.new(entindex)
    if player )
        local velocity = { entity.get_prop(player, "m_vecVelocity") }
        if velocity[1] and velocity[2] )
            local velocity_length = math.sqrt(velocity[1]^2 + velocity[2]^2)
            if velocity_length > 1 )
                local move_yaw = math.deg(math.atan(velocity[2], velocity[1])
                local eye_yaw = entity.get_prop(entindex, "m_angEyeAngles[1]") or 0
                local delta = angle_diff(move_yaw, eye_yaw)
                
                if math.abs(delta) > 45 )
                    return delta > 0 and 1 or -1
                end
            end
        end
    end
    
    return 0 -- center
end

local function process_side(entindex, side)
    local steam64 = entity.get_steam64(entindex) or entindex
    local data = resolver.data[entindex]
    
    if not data then return 1 end
    
    -- Track side changes for better resolution
    if data.last_side ~= side )
        data.side_changes = (data.side_changes or 0) + 1
        data.last_side = side
    end
    
    -- More aggressive side multiplier based on miss count
    local miss_count = resolver.miss_count[steam64] or 0
    local multiplier = 1.0
    
    if miss_count > 5 )
        multiplier = side == 1 and 1.5 or (side == -1 and -1.5 or 1.0)
    elseif miss_count > 3 )
        multiplier = side == 1 and 1.3 or (side == -1 and -1.3 or 1.0)
    elseif miss_count > 1 )
        multiplier = side == 1 and 1.2 or (side == -1 and -1.2 or 1.0)
    end
    
    return multiplier
end

local function resolver_reset()
    for i = 1, 64 do
        plist.set(i, "Force body yaw", false)
        plist.set(i, "Force body yaw value", 0)
        plist.set(i, "Correction active", false)
        plist.set(i, "Force pitch", false)
        plist.set(i, "Force pitch value", 0)
        plist.set(i, "High priority", false)
    end
    resolver.data = {}
    resolver.miss_count = {}
    resolver.last_hit_time = {}
    resolver.prediction_data = {}
end

local function get_best_targets_by_fov(max_targets)
    max_targets = max_targets or 3
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) )
        return {} 
    end
    
    local eye_x, eye_y, eye_z = client.eye_position()
    local pitch, yaw = client.camera_angles()
    local enemies = get_enemies_filtered()
    local targets = {}
    
    for i = 1, #enemies do
        local ent = enemies[i]
        if entity.is_alive(ent) )
            local hx, hy, hz = entity.hitbox_position(ent, 0)
            if hx )
                local dx, dy = hx - eye_x, hy - eye_y
                local to_yaw = math.deg(math.atan(dy, dx)
                local dyaw = math.abs(normalize_yaw((to_yaw or 0) - (yaw or 0))
                
                table.insert(targets, { ent = ent, fov = dyaw })
            end
        end
    end
    
    -- Sort by FOV and take top targets
    table.sort(targets, function(a, b) return a.fov < b.fov end)
    
    local result = {}
    for i = 1, math.min(max_targets, #targets) do
        table.insert(result, targets[i].ent)
    end
    
    return result
end

-- Advanced resolver based on aimtools.lua implementation
local function resolver_work()
    local enemies = entity.get_players(true)
    local done = false

    for i = 1, #enemies do 
        local enemy = enemies[i]
        
        -- Initialize resolver data for this enemy
        if not resolver.data[enemy] )
            resolver.data[enemy] = {
                misses = 0,
                playback = {
                    left = 5,
                    right = 6
                },
                lby = {
                    next_update = globals.tickinterval() * entity.get_prop(enemy, "m_nTickBase")
                },
                yaw = {
                    last_yaw = 0,
                    delta = 0,
                    last_change = globals.curtime()
                },
                last_side = 0,
                side_changes = 0
            }
        end 

        if ui.get(lua_menu.checkboxes.resolver) )
            plist.set(enemy, "Correction active", false)
            plist.set(enemy, "Force body yaw", false)

            local player = c_entity.new(enemy)
            if not player then return end 

            local animstate = player:get_anim_state()
            local animlayer = player:get_anim_overlay(6)

            -- Get weapon max speed
            local max_speed = 260
            if entity.get_player_weapon(enemy) )
                local weapon = entity.get_player_weapon(enemy)
                local weapon_data = weapons(weapon)
                if weapon_data and weapon_data.max_player_speed )
                    max_speed = math.max(weapon_data.max_player_speed, 0.001)
                end
            end 

            -- Calculate movement speeds
            local velocity = { entity.get_prop(player, "m_vecVelocity") }
            local velocity_length = velocity[1] and math.sqrt(velocity[1]^2 + velocity[2]^2) or 0
            
            local running_speed = math.max(velocity_length, 260) / (max_speed * 0.520)
            local ducking_speed = math.max(velocity_length, 260) / (max_speed * 0.340)

            local server_time = globals.curtime()
            local yaw = animstate.goal_feet_yaw

            local eye_feet_delta = animstate.eye_angles_y - animstate.goal_feet_yaw

            -- Calculate yaw modifier based on movement
            local yaw_modifier = ((((animstate.stop_to_full_running_fraction * -0.3) - 0.2) * tools.clamp(running_speed, 0, 1) + 1)
            if animstate.duck_amount > 0 )
                yaw_modifier = yaw_modifier + (animstate.duck_amount * (tools.clamp(ducking_speed, 0, 1) * (0.5 - yaw_modifier)
            end 

            local max_yaw_modifier = yaw_modifier * animstate.max_yaw
            local min_yaw_modifier = yaw_modifier * animstate.min_yaw

            -- Calculate target yaw
            if eye_feet_delta <= max_yaw_modifier )
                if min_yaw_modifier > eye_feet_delta )
                    yaw = math.abs(min_yaw_modifier) + animstate.eye_angles_y
                end 
            else 
                yaw = animstate.eye_angles_y - math.abs(max_yaw_modifier)
            end 

            -- Apply movement-based yaw calculation
            if velocity_length > 0.01 or math.abs(velocity[3] or 0) > 100 )
                yaw = approach_angle(animstate.eye_angles_y, yaw, ((animstate.stop_to_full_running_fraction * 20) + 30) * animstate.last_client_side_animation_update_time)
            else 
                yaw = approach_angle(entity.get_prop(enemy, "m_flLowerBodyYawTarget"), yaw, animstate.last_client_side_animation_update_time * 100)
            end 

            -- Calculate desync
            local desync = animstate.goal_feet_yaw - yaw  
            local eye_goalfeet_delta = angle_diff(animstate.eye_angles_y - yaw, 360)

            if eye_goalfeet_delta < 0.0 or animstate.max_yaw == 0.0 )
                if animstate.min_yaw ~= 0.0 )
                    desync = ((eye_goalfeet_delta / animstate.min_yaw) * 360) * -58
                else
                    desync = -58 -- Fallback for min_yaw = 0
                end
            else 
                desync = ((eye_goalfeet_delta / animstate.max_yaw) * 360) * 58
            end
            
            -- Ensure we have a valid desync value - use intelligent detection
            if desync == 0 or math.abs(desync) < 1 )
                -- Use velocity-based desync detection
                local velocity = { entity.get_prop(player, "m_vecVelocity") }
                local velocity_length = velocity[1] and math.sqrt(velocity[1]^2 + velocity[2]^2) or 0
                
                if velocity_length > 5 )
                    -- Moving - use movement direction for desync
                    local move_yaw = math.deg(math.atan(velocity[2], velocity[1])
                    local eye_yaw = animstate.eye_angles_y
                    local move_delta = angle_diff(move_yaw, eye_yaw)
                    desync = move_delta > 0 and 58 or -58
                else
                    -- Standing - use LBY for desync
                    local lby = entity.get_prop(enemy, "m_flLowerBodyYawTarget")
                    local lby_delta = angle_diff(animstate.eye_angles_y, lby)
                    desync = lby_delta > 0 and 58 or -58
                end
            end 

            -- LBY breaker fix - use intelligent detection
            if server_time >= resolver.data[enemy].lby.next_update )
                -- Use LBY angle to determine desync direction
                local lby = entity.get_prop(enemy, "m_flLowerBodyYawTarget")
                local eye_yaw = animstate.eye_angles_y
                local lby_delta = angle_diff(eye_yaw, lby)
                
                -- Determine desync based on LBY delta
                if math.abs(lby_delta) > 90 )
                    desync = lby_delta > 0 and 120 or -120
                elseif math.abs(lby_delta) > 45 )
                    desync = lby_delta > 0 and 90 or -90
                else
                    desync = lby_delta > 0 and 60 or -60
                end
            end 

            -- Apply delta and time-based modifications
            local delta = desync - resolver.data[enemy].yaw.last_yaw
            local time_delta = entity.get_prop(enemy, "m_flSimulationTime") - resolver.data[enemy].yaw.last_change
            local modifier = time_delta / math.max(resolver.data[enemy].yaw.delta, 0.001)

            desync = (desync * 58) + (delta * modifier)
            
            -- Apply side processing
            local side = get_side(enemy, animlayer)
            desync = desync * process_side(enemy, side)
            
            -- More aggressive resolver - increase desync range
            local miss_count = resolver.data[enemy].misses or 0
            if miss_count > 0 )
                local multiplier = 1.0 + (miss_count * 0.3) -- More aggressive multiplier
                desync = desync * multiplier
            end
            
            -- Fallback resolver for high miss counts - use intelligent detection
            if miss_count > 3 )
                -- Analyze previous desync attempts and try opposite direction
                local last_desync = resolver.data[enemy].yaw.last_yaw or 0
                local opposite_desync = -last_desync
                
                -- If we've been trying positive, try negative and vice versa
                if miss_count % 2 == 0 )
                    desync = math.abs(desync) > 0 and -math.abs(desync) or -58
                else
                    desync = math.abs(desync) > 0 and math.abs(desync) or 58
                end
                
                -- For very high miss counts, try extreme values
                if miss_count > 6 )
                    local extreme_desyncs = {-120, 120, -90, 90}
                    local extreme_index = ((miss_count - 6) % #extreme_desyncs) + 1
                    desync = extreme_desyncs[extreme_index]
                end
            end
            
            -- Clamp desync to valid range but be more aggressive
            desync = tools.clamp(desync, -120, 120)

            -- Apply resolver corrections
            plist.set(enemy, "Force body yaw", true)
            plist.set(enemy, "Force body yaw value", desync) 
            plist.set(enemy, "High priority", true) -- Always high priority for better accuracy

            -- Update LBY timing
            if animstate.eye_timer ~= 0 )
                if animstate.m_velocity > 0.1 )
                    resolver.data[enemy].lby.next_update = server_time + 0.22
                end 

                if math.abs((animstate.goal_feet_yaw - animstate.eye_angles_y) / 360) > 35 and server_time > resolver.data[enemy].lby.next_update )
                    resolver.data[enemy].lby.next_update = server_time + 1.1
                end 
            end 

            -- Update yaw tracking
            if resolver.data[enemy].yaw.last_yaw ~= desync )
                resolver.data[enemy].yaw.last_yaw = desync
            end 

            if delta ~= 0 )
                if resolver.data[enemy].yaw.delta ~= delta )
                    resolver.data[enemy].yaw.last_change = entity.get_prop(enemy, "m_flSimulationTime")
                    resolver.data[enemy].yaw.delta = delta 
                end 
            end 

            done = false 
        else 
            if not done )
                plist.set(enemy, "Correction active", true)
                plist.set(enemy, "Force body yaw", false)
                plist.set(enemy, "High priority", false)
                done = true 
            end 
        end 
    end 
end

defensive_data = {}

local function defensive_resolve()
    if ui.get(lua_menu.checkboxes.resolver) )
        local enemies = entity.get_players(true)
        for i, enemy_ent in ipairs(enemies) do
            if defensive_data[enemy_ent] == nil )
              defensive_data[enemy_ent] = {
                 pitch = 0,
                 vl_p = 0,
                 timer = 0,
            }
            else 
                defensive_data[enemy_ent].pitch = entity.get_prop(enemy_ent, "m_angEyeAngles[0]")
                if is_player_defensive_active(enemy_ent) )
                    if defensive_data[enemy_ent].pitch < 70 )
                        defensive_data[enemy_ent].vl_p = defensive_data[enemy_ent].vl_p + 1
                        defensive_data[enemy_ent].timer = globals.realtime() + 5
                    end
                else
                    if defensive_data[enemy_ent].timer - globals.realtime() < 0 )
                        defensive_data[enemy_ent].vl_p = 0
                        defensive_data[enemy_ent].timer = 0
                end
            end
        end

        if defensive_data[enemy_ent].vl_p > 3 )
            plist.set(enemy_ent, "force pitch", true)
            plist.set(enemy_ent, "force pitch value", 89)
        else
            plist.set(enemy_ent, "force pitch", false)
        end
    end
end

-- Enhanced miss tracking for better resolver
local function track_miss(entindex)
    local steam64 = entity.get_steam64(entindex) or entindex
    resolver.miss_count[steam64] = (resolver.miss_count[steam64] or 0) + 1
    resolver.last_hit_time[steam64] = globals.tickcount()
    
    -- Update resolver data miss count
    if resolver.data[entindex] )
        resolver.data[entindex].misses = resolver.data[entindex].misses + 1
    end
end

local function track_hit(entindex)
    local steam64 = entity.get_steam64(entindex) or entindex
    resolver.miss_count[steam64] = 0
    resolver.last_hit_time[steam64] = globals.tickcount()
    
    -- Reset resolver data miss count
    if resolver.data[entindex] )
        resolver.data[entindex].misses = 0
    end
end

---@game enhancer
local game_enhancer = {
    enabled = false,
    state = false
}

local function game_enhancer_work()
    local me = entity.get_local_player()
    if me and entity.is_alive(me) )
        -- Basic game enhancement features
        local velocity = vector(entity.get_prop(me, "m_vecVelocity"):length2d()
        if velocity > 0 )
            -- Add some basic movement enhancement logic here
            -- This is where you could add auto-strafe enhancements, etc.
        end
    end
end

function game_enhancer_run()
    local enabled = ui.get(lua_menu.checkboxes.game_enhancer)
    
    if game_enhancer.state ~= enabled )
        game_enhancer.state = enabled
        if enabled )
            print("Game Enhancer enabled")
        else
            print("Game Enhancer disabled")
        end
    end
    
    if enabled )
        game_enhancer_work()
    end
end
---@end

---@prediction
local prediction = {
    enabled = false,
    state = false,
    target_data = {},
    last_update = 0
}

local function calculate_velocity_prediction(entindex, ticks_ahead)
    local current_pos = { entity.get_origin(entindex) }
    local velocity = { entity.get_prop(entindex, "m_vecVelocity") }
    
    if not current_pos[1] or not velocity[1] )
        return current_pos
    end
    
    local tick_interval = globals.tickinterval()
    local time_ahead = ticks_ahead * tick_interval
    
    local predicted_pos = {
        current_pos[1] + velocity[1] * time_ahead,
        current_pos[2] + velocity[2] * time_ahead,
        current_pos[3] + velocity[3] * time_ahead
    }
    
    return predicted_pos
end

local function calculate_angle_prediction(entindex, ticks_ahead)
    local current_angles = { entity.get_prop(entindex, "m_angEyeAngles") }
    local velocity = { entity.get_prop(entindex, "m_vecVelocity") }
    
    if not current_angles[1] or not velocity[1] )
        return current_angles
    end
    
    local speed = math.sqrt(velocity[1]^2 + velocity[2]^2)
    local tick_interval = globals.tickinterval()
    local time_ahead = ticks_ahead * tick_interval
    
    -- Predict angle changes based on movement
    local angle_change = speed * time_ahead * 0.1 -- Adjust multiplier as needed
    local predicted_angles = {
        current_angles[1],
        current_angles[2] + angle_change,
        current_angles[3]
    }
    
    return predicted_angles
end

local function prediction_work()
    local enemies = get_enemies_filtered()
    local me = entity.get_local_player()
    if not me then return end
    
    local my_pos = { entity.get_origin(me) }
    local sorted_enemies = {}
    local current_time = globals.tickcount()
    
    -- Only update every few ticks for performance
    if current_time - prediction.last_update < 2 )
        return
    end
    prediction.last_update = current_time
    
    for i = 1, #enemies do
        local ent = enemies[i]
        if entity.is_alive(ent) )
            local ent_pos = { entity.get_origin(ent) }
            if ent_pos[1] )
                local dist = math.sqrt((ent_pos[1] - my_pos[1])^2 + (ent_pos[2] - my_pos[2])^2 + (ent_pos[3] - my_pos[3])^2)
                table.insert(sorted_enemies, { ent = ent, dist = dist })
            end
        end
    end
    
    table.sort(sorted_enemies, function(a, b) return a.dist < b.dist end)
    
    -- Process closest 3 enemies with enhanced prediction
    for i = 1, math.min(3, #sorted_enemies) do
        local ent = sorted_enemies[i].ent
        local steam64 = entity.get_steam64(ent) or ent
        
        -- Calculate predictions for different tick counts
        local predictions = {}
        for ticks = 1, 8 do
            predictions[ticks] = {
                pos = calculate_velocity_prediction(ent, ticks),
                angles = calculate_angle_prediction(ent, ticks)
            }
        end
        
        -- Store prediction data
        prediction.target_data[steam64] = {
            last_update = current_time,
            predictions = predictions,
            velocity = { entity.get_prop(ent, "m_vecVelocity") },
            last_known_pos = { entity.get_origin(ent) }
        }
    end
end

local function get_predicted_position(entindex, ticks_ahead)
    local steam64 = entity.get_steam64(entindex) or entindex
    local data = prediction.target_data[steam64]
    
    if not data or not data.predictions[ticks_ahead] )
        return { entity.get_origin(entindex) }
    end
    
    return data.predictions[ticks_ahead].pos
end

local function prediction_run()
    local enabled = ui.get(lua_menu.checkboxes.prediction)
    
    if prediction.state ~= enabled )
        prediction.state = enabled
        if enabled )
            print("Enhanced Prediction enabled")
        else
            print("Enhanced Prediction disabled")
        end
    end
    
    if enabled )
        prediction_work()
    end
end
---@end

---@avoid backstab
function anti_stab()
    if not ui.get(lua_menu.discloser.anti_stab) then return end
    
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end
    
    local lp_origin = vector(entity.get_origin(lp)
    local enemies = entity.get_players(true)
    
    for i = 1, #enemies do
        local enemy = enemies[i]
        local enemy_weapon = entity.get_player_weapon(enemy)
        
        if enemy_weapon and entity.get_classname(enemy_weapon) == "CKnife" )
            if vector(entity.get_origin(enemy):dist2d(lp_origin) < 250 )
                ui.set(ref.yaw[1], "180")
                ui.set(ref.yaw[2], 180)
                return
            end
        end
    end
end
---@end

---@fix hideshots
local original_fakelag_limit = 0

local function hideshots_fix()
    local fix_enabled = ui.get(lua_menu.checkboxes.fix_hideshots)
    local hs_enabled = ui.get(ref.hs[2])
    
    if fix_enabled and hs_enabled )
        if original_fakelag_limit == 0 )
            original_fakelag_limit = ui.get(ref.fakelag_limit)
        end
        ui.set(ref.fakelag_limit, 1)
        return
    end
    
    if original_fakelag_limit > 0 )
        ui.set(ref.fakelag_limit, original_fakelag_limit)
        original_fakelag_limit = 0
    end
end
---@end

---@fakelag addons
local original_variability = nil
local function fake_lag()
    local variability = 15 + 2 * math.random(0, (45 - 10) / 2)
    local addon_enabled = ui.get(lua_menu.discloser.fake_lag_addon)
   
    if addon_enabled )
        if original_variability == nil )
            original_variability = ui.get(ref.variability)
        end
        ui.set(ref.variability, variability)
        return
    end
   
    if original_variability ~= nil )
        ui.set(ref.variability, original_variability)
        original_variability = nil
    end
end
---@end

---@warmup aa
local function warmup()
    local player = entity.get_local_player()
    if not player then return end

    local gamerulesproxy = entity.get_all("CCSGameRulesProxy")[1]
    if not gamerulesproxy or entity.get_prop(gamerulesproxy, "m_bWarmupPeriod") ~= 1 then return end

    if ui.get(lua_menu.discloser.warmup_aa) )
        ui.set(ref.body_yaw[1], 'Off')
        ui.set(ref.yaw[1], "Spin")
        ui.set(ref.yaw[2], 15)
        ui.set(ref.pitch[1], "Custom")
        ui.set(ref.pitch[2], 0)
    end
end
---@end

---
---@damage indicator
local displayed_min_damage = 0
function render_damage_indicator()
    if not ui.get(lua_menu.checkboxes.damage_indicator) )
        return
    end

    local player = entity.get_local_player()
    if not player or not entity.is_alive(player) )
        return
    end

    local screen_x, screen_y = client.screen_size()
    local x = screen_x / 2 + 15
    local y = screen_y / 2 - 11

    local min_damage = 0
    if ref.min_damage )
        min_damage = ui.get(ref.min_damage) or 0
    end

    if ref.min_damage_override and type(ref.min_damage_override) == "table" )
        local override_enabled_ref = ref.min_damage_override[2] or ref.min_damage_override[1]
        local override_value_ref   = ref.min_damage_override[3] or ref.min_damage_override[2]

        if override_enabled_ref and ui.get(override_enabled_ref) )
            local v = override_value_ref and ui.get(override_value_ref)
            if type(v) == "number" )
                min_damage = v
            end
        end
    end

    if type(min_damage) ~= "number" )
        min_damage = 0
    end

    displayed_min_damage = tools.lerp(displayed_min_damage, min_damage, 0.12)

    local font = ui.get(lua_menu.checkboxes.damage_indicator_font)

    if font == "Verdana" )
        renderer.text(x, y, 255, 255, 255, 255, "c", nil, string.format("%.0f", displayed_min_damage)
    elseif font == "Pixel" )
        renderer.text(x - 5, y + 2, 255, 255, 255, 255, "c-", nil, string.format("%.0f", displayed_min_damage)
    end
end


    local player = entity.get_local_player()
    if not player or not entity.is_alive(player) )
        return
    end

    local screen_x, screen_y = client.screen_size()
    local x = screen_x / 2 + 15
    local y = screen_y / 2 - 11

    local min_damage = ui.get(ref.min_damage)
    if ui.get(ref.min_damage_override[2]) )
        min_damage = ui.get(ref.min_damage_override[3])
    end

    displayed_min_damage = tools.lerp(displayed_min_damage, min_damage, 0.12)

    local font = ui.get(lua_menu.checkboxes.damage_indicator_font)

    if font == "Verdana" )
        renderer.text(x, y, 255, 255, 255, 255, "c", nil, string.format("%.0f", displayed_min_damage)
    elseif font == "Pixel" )
        renderer.text(x - 5, y + 2, 255, 255, 255, 255, "c-", nil, string.format("%.0f", displayed_min_damage)
    end
end
---@end

---@recharge
local timer = globals.tickcount()
local recharge_delay = 11

local function handle_recharge()
    local lp = entity.get_local_player()
    if not entity.is_alive(lp) then return end
    
    local lp_weapon = entity.get_player_weapon(lp)
    if not lp_weapon then return end
    
    recharge_delay = weapons(lp_weapon).is_revolver and 18 or 11
 
    if ( ui.get(ref.dt[2]) or ui.get(ref.hs[2]) ) and ui.get(lua_menu.discloser.recharge_fix) )
        if globals.tickcount() >= timer + recharge_delay )
            ui.set(ref.aimbot, true)
        else
            ui.set(ref.aimbot, false)
        end
    else
        timer = globals.tickcount()
        ui.set(ref.aimbot, true)
    end
end
---@end

---@watermark
local function hsv_to_rgb(h, s, v)
    local c, x = v * s, v * s * (1 - math.abs((h * 6) % 2 - 1)
    local m = v - c
    local r, g, b = 0, 0, 0

    if h < 1/6 then r, g, b = c, x, 0
    elseif h < 2/6 then r, g, b = x, c, 0
    elseif h < 3/6 then r, g, b = 0, c, x
    elseif h < 4/6 then r, g, b = 0, x, c
    elseif h < 5/6 then r, g, b = x, 0, c
    else r, g, b = c, 0, x
    end

    return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

---local function fade_alpha(min_alpha, max_alpha, speed)
---    local time = globals.realtime() * speed
---    return math.floor(min_alpha + (max_alpha - min_alpha) * (math.sin(time) * 0.5 + 0.5)
---end

local function gradient_text(color1, color2, text, speed)
    local time = globals.realtime() * speed
    local gradient_str = ""
    local text_length = #text
    
    for i = 1, text_length do
        local char = text:sub(i, i)
        local t = (math.sin(time + (i / text_length) * math.pi) + 1) / 2
        local r = math.floor(color1[1] * t + color2[1] * (1 - t)
        local g = math.floor(color1[2] * t + color2[2] * (1 - t)
        local b = math.floor(color1[3] * t + color2[3] * (1 - t)
        gradient_str = gradient_str .. string.format("\a%02X%02X%02XFF%s", r, g, b, char)
    end
    
    return gradient_str
end

local function render_watermark()
    local screen_x, screen_y = client.screen_size()
    local start_x = screen_x / 2
    local y = screen_y - 15
    local text = gradient_text({56, 152, 255}, {152, 245, 249}, "VOID", 3.33)
    renderer.text(start_x, y, 255, 255, 255, 255, "dc", nil, text)
end
---@end

---@console filter
---@advanced_event_logger
local event_logger = {} do
    local cache = {}
    local hitgroups = {
        'body',
        'head', 
        'chest',
        'stomach',
        'left arm',
        'right arm',
        'left leg',
        'right leg',
        'neck',
        '?',
        'gear'
    }

    function event_logger.aim_fire(event)
        local this = {
            tick = event.tick,
            timestamp = client.timestamp(),
            wanted_damage = event.damage,
            wanted_hit_chance = event.hit_chance,
            wanted_hitgroup = event.hitgroup
        }

        cache[event.id] = this
    end

    function event_logger.aim_hit(event)
        local cached = cache[event.id]

        if not cached )
            return
        end

        -- Track hit for resolver
        track_hit(event.target)

        local options = {}

        local backtrack = globals.tickcount() - cached.tick

        if backtrack ~= 0 )
            options[#options+1] = string.format('bt: %d tick%s (%i ms)', backtrack, math.abs(backtrack) == 1 and '' or 's', math.floor(backtrack*globals.tickinterval()*1000)
        end

        local register_delay = client.timestamp() - cached.timestamp

        if register_delay ~= 0 )
            options[#options+1] = string.format('delay: %i ms', register_delay)
        end

        local name = entity.get_player_name(event.target)
        local hitgroup = hitgroups[event.hitgroup + 1] or '?'
        local target_hitgroup = hitgroups[cached.wanted_hitgroup + 1] or '?'
        local damage = event.damage
        local health = entity.get_prop(event.target, 'm_iHealth')
        local hit_chance = event.hit_chance
        local logger_text = string.format('Hit %s\'s %s for %d%s damage (%s, %d remaining%s)',
            name,
            hitgroup,
            tonumber(damage),
            cached.wanted_damage ~= damage and string.format('(%d)', cached.wanted_damage) or '',
            target_hitgroup ~= hitgroup and string.format('aimed: %s(%d%%)', target_hitgroup, hit_chance) or string.format('th: %d%%', hit_chance),
            health,
            #options > 0 and string.format(', %s', table.concat(options, ', ') or ''
        )

        if ui.get(lua_menu.checkboxes.logs) )
            client.color_log(140, 220, 140, string.format("[VOID] %s", logger_text)
        end
    end

    function event_logger.aim_miss(event)
        local cached = cache[event.id]

        if not cached )
            return
        end

        -- Track miss for resolver
        track_miss(event.target)

        local options = {}

        local backtrack = globals.tickcount() - cached.tick

        if backtrack ~= 0 )
            options[#options+1] = string.format('bt: %d tick%s (%i ms)', backtrack, math.abs(backtrack) == 1 and '' or 's', math.floor(backtrack*globals.tickinterval()*1000)
        end

        local register_delay = client.timestamp() - cached.timestamp

        if register_delay ~= 0 )
            options[#options+1] = string.format('delay: %i ms', register_delay)
        end

        local name = entity.get_player_name(event.target)
        local hitgroup = hitgroups[event.hitgroup + 1] or '?'
        local reason = event.reason
        local damage = cached.wanted_damage
        local hit_chance = event.hit_chance
        local logger_text = string.format('Missed %s\'s %s due to %s (td: %d, th: %d%%%s)',
            name,
            hitgroup,
            reason,
            tonumber(damage),
            hit_chance,
            #options > 0 and string.format(', %s', table.concat(options, ', ') or ''
        )

        if ui.get(lua_menu.checkboxes.logs) )
            client.color_log(220, 140, 140, string.format("[VOID] %s", logger_text)
        end
    end

    local hurt_weapons = {
        ['knife'] = 'Knifed';
        ['hegrenade'] = 'Naded';
        ['inferno'] = 'Burned';
    }

    function event_logger.player_hurt(event)
        local attacker = client.userid_to_entindex(event.attacker)

        if not attacker or attacker ~= entity.get_local_player() )
            return
        end

        local target = client.userid_to_entindex(event.userid)

        if not target )
            return
        end

        local wpn_type = hurt_weapons[event.weapon]

        if not wpn_type )
            return
        end

        local name = entity.get_player_name(target)
        local damage = event.dmg_health

        local logger_text = string.format('%s %s for %d damage',
            wpn_type,
            name,
            tonumber(damage)
        )

        if ui.get(lua_menu.checkboxes.logs) )
            -- Use blue color for knife kills, orange for others
            local r, g, b = 255, 165, 0 -- Default orange
            if event.weapon == 'knife' )
                r, g, b = 0, 150, 255 -- Blue color for knife
            end
            
            client.color_log(r, g, b, string.format("[VOID] %s", logger_text)
        end
    end
end
---@end

local function console_filter()
    if ui.get(lua_menu.checkboxes.console_filter) )
        cvar.con_filter_enable:set_int(1)
        cvar.con_filter_text:set_string("IrWL5106TZZKNFPz4P4Gl3pSN?J370f5hi373ZjPg%VOVh6lN")
    else
        cvar.con_filter_enable:set_int(0)
        cvar.con_filter_text:set_string("")
    end
end

ui.set_callback(lua_menu.checkboxes.console_filter, console_filter)
---@end













---@callbacks_start
client.set_event_callback("pre_render", function()
    local tick = globals.tickcount()
    
    -- Throttle animfix to every 2 ticks
    if tick % 2 == 0 )
        animfix_setup()
    end
    
    -- Only update UI when menu is open and throttled
    if ui.is_menu_open() and tick % 4 == 0 )
        on_load()
        visuals_visibility()
        aa_visibility()
        config_visibillity()
    end
end)

client.set_event_callback("setup_command", function(cmd)
    on_setup_command(cmd)
    update_command_number(cmd)
    freestanding()
    safehead(cmd)
    manual_yaw()
    aa_on_use(cmd)
    edge_yaw()
    anti_stab()
    hideshots_fix()
    fake_lag()
    warmup()
    handle_recharge()
end)

client.set_event_callback("paint", function()
    local tick = globals.tickcount()
    local enemies = get_enemies_filtered()
    local enemy_count = #enemies
    
    -- Adaptive rendering based on enemy count
    local render_throttle = enemy_count > 3 and 4 or (enemy_count > 1 and 3 or 2)
    
    -- Render expensive visuals less frequently with more enemies
    if tick % render_throttle == 0 )
        render_manual()
        rev_helper()
        render_damage_indicator()
    end
    
    -- Lightweight operations every tick
    clantag()
    render_watermark()
end)

client.set_event_callback("run_command", function(cmd)
    update_pred_value(cmd)
end)

client.set_event_callback("predict_command", function(cmd)
    local tick = globals.tickcount()
    local enemies = get_enemies_filtered()
    local enemy_count = #enemies
    
    -- Adaptive throttling based on enemy count
    local throttle_rate = enemy_count > 3 and 4 or (enemy_count > 1 and 3 or 2)
    
    -- Throttle expensive operations more aggressively with more enemies
    if tick % throttle_rate == 0 )
        defensiveCheck(cmd)
        resolver.enabled = ui.get(lua_menu.checkboxes.resolver)
        if resolver.enabled )
            resolver_work()
        end
    end
    
    -- Run lighter operations less frequently with more enemies
    local light_throttle = enemy_count > 3 and 6 or (enemy_count > 1 and 4 or 3)
    if tick % light_throttle == 0 )
        game_enhancer_run()
        prediction_run()
    end
end)

client.set_event_callback("shutdown", function()
    on_unload()

    cvar.con_filter_enable:set_int(0)
    cvar.con_filter_text:set_string("")
    resolver_reset()
end)

client.set_event_callback('level_init', function()
    timer = globals.tickcount()
end)

-- Advanced event logger callbacks
client.set_event_callback("aim_fire", function(e)
    local me = entity.get_local_player()
    if not me then return end
    if e.attacker and e.attacker ~= me then return end
    if e.target and not entity.is_enemy(e.target) then return end
    event_logger.aim_fire(e)
end)

client.set_event_callback("aim_hit", function(e)
    local me = entity.get_local_player()
    if not me then return end
    if e.attacker and e.attacker ~= me then return end
    if e.target and not entity.is_enemy(e.target) then return end
    event_logger.aim_hit(e)
end)

client.set_event_callback("aim_miss", function(e)
    local me = entity.get_local_player()
    if not me then return end
    if e.attacker and e.attacker ~= me then return end
    if e.target and not entity.is_enemy(e.target) then return end
    event_logger.aim_miss(e)
end)

client.set_event_callback("player_hurt", function(e)
    event_logger.player_hurt(e)
end)

---@callbacks_end
