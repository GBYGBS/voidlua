-- VOID - Unified Anti-Aim Script
-- Merged from ambani.lua and hristio.lua

local ffi = require("ffi")
local vector = require("vector")
local pui = require("gamesense/pui")
local base64 = require("gamesense/base64")
local clipboard = require("gamesense/clipboard")
local json = require("json")

-- Core dependencies
local entity_lib = require("gamesense/entity")
local csgo_weapons = require("gamesense/csgo_weapons")
local plist = require("gamesense/player_list")

-- Global variables
local global_data_saved_somewhere = [[{"t":{"hideshots":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":5,"hold_time":2,"body_yaw_add":-1,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"default"},"slow walk":{"enable":false,"yaw_base":"local view","options":["~"],"body_yaw":"off","yaw_jitter_add":0,"hold_time":2,"body_yaw_add":0,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"off","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"defensive"},"run":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-25,"yaw_jitter":"off","yaw_add_r":28,"defensive_pitch_mode":"zero","defensive_builder":"default"},"duck jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","air tick","safe head (lc)","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":1,"hold_delay":3,"defensive_yaw_mode":"spin - static","yaw_add":-22,"yaw_jitter":"center","yaw_add_r":25,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"global":{"defensive_builder":"defensive","yaw_base":"at targets","options":["anti-backstab","safe head (lc)","~"],"body_yaw":"jitter","hold_time":2,"yaw_jitter_add":61,"hold_delay":2,"defensive_yaw_mode":"spin - static","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"body_yaw_add":0,"defensive_pitch_mode":"ambani"},"duck":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"up","defensive_builder":"default"},"stand":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-180,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-20,"yaw_jitter":"center","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"duck move":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","defensive yaw","~"],"body_yaw":"jitter","yaw_jitter_add":-16,"hold_time":5,"body_yaw_add":1,"hold_delay":4,"defensive_yaw_mode":"spin - static","yaw_add":13,"yaw_jitter":"center","yaw_add_r":13,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"}},"ct":{"hideshots":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":5,"hold_time":2,"body_yaw_add":-1,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"default"},"slow walk":{"enable":true,"yaw_base":"at targets","options":["defensive yaw","safe head (lc)","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":26,"defensive_yaw_mode":"spin","yaw_add":-20,"yaw_jitter":"off","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"run":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":3,"defensive_yaw_mode":"spin - static","yaw_add":-30,"yaw_jitter":"off","yaw_add_r":41,"defensive_pitch_mode":"zero","defensive_builder":"defensive"},"duck jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","air tick","safe head (lc)","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-18,"yaw_jitter":"off","yaw_add_r":37,"defensive_pitch_mode":"up","defensive_builder":"default"},"global":{"defensive_builder":"defensive","yaw_base":"at targets","options":["anti-backstab","safe head (lc)","~"],"body_yaw":"jitter","hold_time":2,"yaw_jitter_add":61,"hold_delay":2,"defensive_yaw_mode":"spin - static","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"body_yaw_add":0,"defensive_pitch_mode":"ambani"},"duck":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-31,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"up","defensive_builder":"default"},"stand":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-180,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-20,"yaw_jitter":"center","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"duck move":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"off","yaw_add_r":36,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":-16,"hold_time":5,"body_yaw_add":1,"hold_delay":4,"defensive_yaw_mode":"spin - static","yaw_add":13,"yaw_jitter":"center","yaw_add_r":13,"defensive_pitch_mode":"up","defensive_builder":"default"}}}]]]

local global_data_saved_somewhere2 = [[{"t":{"hideshots":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":5,"hold_time":2,"body_yaw_add":-1,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"default"},"slow walk":{"enable":false,"yaw_base":"local view","options":["~"],"body_yaw":"off","yaw_jitter_add":0,"hold_time":2,"body_yaw_add":0,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"off","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"defensive"},"run":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-25,"yaw_jitter":"off","yaw_add_r":28,"defensive_pitch_mode":"zero","defensive_builder":"default"},"duck jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","air tick","safe head (lc)","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":1,"hold_delay":3,"defensive_yaw_mode":"spin - static","yaw_add":-22,"yaw_jitter":"center","yaw_add_r":25,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"global":{"defensive_builder":"defensive","yaw_base":"at targets","options":["anti-backstab","safe head (lc)","~"],"body_yaw":"jitter","hold_time":2,"yaw_jitter_add":61,"hold_delay":2,"defensive_yaw_mode":"spin - static","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"body_yaw_add":0,"defensive_pitch_mode":"ambani"},"duck":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"up","defensive_builder":"default"},"stand":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-180,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-20,"yaw_jitter":"center","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"duck move":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":-16,"hold_time":5,"body_yaw_add":1,"hold_delay":4,"defensive_yaw_mode":"spin - static","yaw_add":13,"yaw_jitter":"center","yaw_add_r":13,"defensive_pitch_mode":"up","defensive_builder":"default"}},"ct":{"hideshots":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":5,"hold_time":2,"body_yaw_add":-1,"hold_delay":2,"defensive_yaw_mode":"spin","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"defensive_pitch_mode":"up","defensive_builder":"default"},"slow walk":{"enable":true,"yaw_base":"at targets","options":["defensive yaw","safe head (lc)","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":26,"defensive_yaw_mode":"spin","yaw_add":-20,"yaw_jitter":"off","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"run":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":3,"defensive_yaw_mode":"spin - static","yaw_add":-30,"yaw_jitter":"off","yaw_add_r":41,"defensive_pitch_mode":"zero","defensive_builder":"defensive"},"duck jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","air tick","safe head (lc)","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-18,"yaw_jitter":"off","yaw_add_r":37,"defensive_pitch_mode":"up","defensive_builder":"default"},"global":{"defensive_builder":"defensive","yaw_base":"at targets","options":["anti-backstab","safe head (lc)","~"],"body_yaw":"jitter","hold_time":2,"yaw_jitter_add":61,"hold_delay":2,"defensive_yaw_mode":"spin - static","yaw_add":0,"yaw_jitter":"center","yaw_add_r":0,"body_yaw_add":0,"defensive_pitch_mode":"ambani"},"duck":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-1,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-31,"yaw_jitter":"center","yaw_add_r":36,"defensive_pitch_mode":"up","defensive_builder":"default"},"stand":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","force lag","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":-180,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-20,"yaw_jitter":"center","yaw_add_r":20,"defensive_pitch_mode":"ambani","defensive_builder":"default"},"duck move":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"hold yaw","yaw_jitter_add":0,"hold_time":5,"body_yaw_add":0,"hold_delay":5,"defensive_yaw_mode":"spin - static","yaw_add":-24,"yaw_jitter":"off","yaw_add_r":36,"defensive_pitch_mode":"ambani","defensive_builder":"defensive"},"jump":{"enable":true,"yaw_base":"at targets","options":["anti-backstab","~"],"body_yaw":"jitter","yaw_jitter_add":-16,"hold_time":5,"body_yaw_add":1,"hold_delay":4,"defensive_yaw_mode":"spin - static","yaw_add":13,"yaw_jitter":"center","yaw_add_r":13,"defensive_pitch_mode":"up","defensive_builder":"default"}}}]]]

json.encode_sparse_array(true)

-- Resolver state and variables
local resolver_state = {}
local player_history = {}
local resolver_flag = {}
local resolver_status = false

-- Global aim punch fix state
local aim_punch_fix_enabled = false
local original_hitchance = 0

-- Game enhancer state
local game_enhancer_enabled = false
local game_enhancer_boost = 1

-- Secret exploit state
local secret_exploit_enabled = false

-- Watermark state
local watermark_enabled = false
local watermark_elements = {}
local watermark_colors = {}
local watermark_gradient = false

-- Helper functions
local function construct_points(x, y, w, h)
    return {
        {x, y},
        {x + w, y},
        {x + w, y + h},
        {x, y + h}
    }
end

local function draw_box(x, y, w, h, r, g, b, a)
    local points = construct_points(x, y, w, h)
    renderer.polygon(points, r, g, b, a)
end

-- ESP flags
local flags = {
    "DORMANT",
    "BOT",
    "WEAPON",
    "FLASHED",
    "SCOPE",
    "DEFUSING",
    "PLANTING",
    "HAS C4",
    "DEFUSER",
    "RESOLVER",
    "VOID"
}

-- Main script class
local new_class = function()
    local class = {}
    class.__index = class
    
    function class:new(...)
        local instance = setmetatable({}, class)
        if instance.init then
            instance:init(...)
        end
        return instance
    end
    
    return class
end

-- Main context
local ctx = new_class():new()

function ctx:init()
    self.globals = {
        resolver_data = {},
        net_channel = 0,
        nade = 0,
        in_ladder = 0
    }
    
    self.ref = {
        aa = {
            enabled = {ui.reference("AA", "Anti-aimbot angles", "Enabled")},
            pitch = {ui.reference("AA", "Anti-aimbot angles", "Pitch")},
            yaw_base = {ui.reference("AA", "Anti-aimbot angles", "Yaw base")},
            yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
            yaw_jitter = {ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")},
            body_yaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")},
            freestand = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
            edge_yaw = {ui.reference("AA", "Anti-aimbot angles", "Edge yaw")}
        },
        rage = {
            dt = {ui.reference("RAGE", "Aimbot", "Double tap")},
            os = {ui.reference("RAGE", "Other", "On shot anti-aim")},
            fd = {ui.reference("RAGE", "Other", "Fake duck")},
            dt_limit = {ui.reference("RAGE", "Aimbot", "Double tap fake lag limit")}
        },
        fakelag = {
            enable = {ui.reference("AA", "Fake lag", "Enabled")},
            limit = {ui.reference("AA", "Fake lag", "Limit")}
        }
    }
    
    self:setup_ui()
    self:setup_helpers()
    self:setup_config()
    self:setup_prediction()
    self:setup_fakelag()
    self:setup_desync()
    self:setup_antiaim()
    self:setup_resolver()
    self:setup_net_channel()
    self:setup_defensive()
    self:setup_predict()
    self:setup_peekbot()
    self:setup_visuals()
    self:setup_watermark()
    self:setup_game_enhancer()
    self:setup_aim_punch_fix()
    self:setup_secret_exploit()
end

function ctx:shutdown()
    -- Cleanup code here
end

function ctx:setup_ui()
    self.ui = {
        menu = {
            label = pui.new("label", "[V O I D]"),
            
            -- Anti-aim section
            aa = {
                mode = pui.new("combobox", "Mode", {"builder", "preset"}),
                preset_list = pui.new("combobox", "Preset", {"Preset 1", "Preset 2"}),
                states = {
                    t = {
                        global = {
                            enable = pui.new("checkbox", "Enable"),
                            yaw_base = pui.new("combobox", "Yaw base", {"local view", "at targets", "away", "backwards"}),
                            yaw = pui.new("slider", "Yaw", -180, 180, 0),
                            yaw_jitter = pui.new("combobox", "Yaw jitter", {"off", "offset", "center", "random", "skitter"}),
                            yaw_jitter_add = pui.new("slider", "Yaw jitter add", 0, 180, 0),
                            body_yaw = pui.new("combobox", "Body yaw", {"off", "opposite", "sides", "jitter", "static", "hold yaw"}),
                            body_yaw_add = pui.new("slider", "Body yaw add", -180, 180, 0),
                            body_yaw_side = pui.new("combobox", "Body yaw side", {"left", "right", "auto"}),
                            options = pui.new("multiselect", "Options", {"anti-backstab", "safe head (lc)", "force lag", "defensive yaw", "air tick", "customize defensive"}),
                            defensive_conditions = pui.new("multiselect", "Defensive conditions", {"always", "on weapon switch", "on reload", "on hittable", "on dormant peek", "on freestand"}),
                            defensive_yaw = pui.new("checkbox", "Defensive yaw"),
                            defensive_yaw_mode = pui.new("combobox", "Defensive yaw mode", {"default", "custom spin"}),
                            defensive_freestand = pui.new("checkbox", "Defensive freestand"),
                            defensive_pitch_mode = pui.new("combobox", "Defensive pitch mode", {"up", "zero", "ambani"}),
                            defensive_builder = pui.new("combobox", "Defensive builder", {"default", "defensive"}),
                            jitter_delay = pui.new("slider", "Jitter delay", 1, 4, 1),
                            hold_time = pui.new("slider", "Hold time", 1, 10, 2),
                            hold_delay = pui.new("slider", "Hold delay", 1, 30, 2),
                            yaw_add = pui.new("slider", "Yaw add", -180, 180, 0),
                            yaw_add_r = pui.new("slider", "Yaw add right", -180, 180, 0)
                        }
                    },
                    ct = {
                        global = {
                            enable = pui.new("checkbox", "Enable"),
                            yaw_base = pui.new("combobox", "Yaw base", {"local view", "at targets", "away", "backwards"}),
                            yaw = pui.new("slider", "Yaw", -180, 180, 0),
                            yaw_jitter = pui.new("combobox", "Yaw jitter", {"off", "offset", "center", "random", "skitter"}),
                            yaw_jitter_add = pui.new("slider", "Yaw jitter add", 0, 180, 0),
                            body_yaw = pui.new("combobox", "Body yaw", {"off", "opposite", "sides", "jitter", "static", "hold yaw"}),
                            body_yaw_add = pui.new("slider", "Body yaw add", -180, 180, 0),
                            body_yaw_side = pui.new("combobox", "Body yaw side", {"left", "right", "auto"}),
                            options = pui.new("multiselect", "Options", {"anti-backstab", "safe head (lc)", "force lag", "defensive yaw", "air tick", "customize defensive"}),
                            defensive_conditions = pui.new("multiselect", "Defensive conditions", {"always", "on weapon switch", "on reload", "on hittable", "on dormant peek", "on freestand"}),
                            defensive_yaw = pui.new("checkbox", "Defensive yaw"),
                            defensive_yaw_mode = pui.new("combobox", "Defensive yaw mode", {"default", "custom spin"}),
                            defensive_freestand = pui.new("checkbox", "Defensive freestand"),
                            defensive_pitch_mode = pui.new("combobox", "Defensive pitch mode", {"up", "zero", "ambani"}),
                            defensive_builder = pui.new("combobox", "Defensive builder", {"default", "defensive"}),
                            jitter_delay = pui.new("slider", "Jitter delay", 1, 4, 1),
                            hold_time = pui.new("slider", "Hold time", 1, 10, 2),
                            hold_delay = pui.new("slider", "Hold delay", 1, 30, 2),
                            yaw_add = pui.new("slider", "Yaw add", -180, 180, 0),
                            yaw_add_r = pui.new("slider", "Yaw add right", -180, 180, 0)
                        }
                    }
                }
            },
            
            -- Misc section
            misc = {
                resolver = pui.new("checkbox", "Resolver"),
                resolver_flag = pui.new("checkbox", "Resolver flag"),
                jitter_helper = pui.new("checkbox", "Jitter helper"),
                animations_selector = pui.new("multiselect", "Animations", {"walk in air", "moon walk", "static legs"}),
                peekbot = pui.new("checkbox", "Peekbot"),
                freestanding = pui.new("hotkey", "Freestanding"),
                freestanding_disablers = pui.new("multiselect", "Freestanding disablers", {"stand", "run", "duck", "duck move", "jump", "duck jump", "slow walk", "hideshots"}),
                edge_yaw = pui.new("hotkey", "Edge yaw"),
                manual_left = pui.new("hotkey", "Manual left"),
                manual_right = pui.new("hotkey", "Manual right"),
                manual_forward = pui.new("hotkey", "Manual forward")
            },
            
            -- Visuals section
            visuals = {
                enable = pui.new("checkbox", "Enable"),
                box = pui.new("checkbox", "Box"),
                name = pui.new("checkbox", "Name"),
                health = pui.new("checkbox", "Health"),
                color = pui.new("color_picker", "Color", 255, 255, 255, 255)
            },
            
            -- Config section
            cfg = {
                name = pui.new("textbox", "Config name"),
                save = pui.new("button", "Save"),
                load = pui.new("button", "Load"),
                delete = pui.new("button", "Delete"),
                export = pui.new("button", "Export"),
                import = pui.new("button", "Import"),
                list = pui.new("combobox", "Configs", {})
            },
            
            -- Game enhancer section
            game_enhancer = {
                enable = pui.new("checkbox", "Enable"),
                boost = pui.new("combobox", "Boost", {"Low", "Medium", "High", "Ultra"})
            },
            
            -- Aim punch fix section
            aim_punch_fix = {
                enable = pui.new("checkbox", "Enable")
            },
            
            -- Secret exploit section
            secret_exploit = {
                enable = pui.new("checkbox", "Enable")
            },
            
            -- Watermark section
            watermark = {
                enable = pui.new("checkbox", "Enable"),
                logo = pui.new("checkbox", "Logo"),
                custom_text = pui.new("checkbox", "Custom text"),
                fps = pui.new("checkbox", "FPS"),
                ping = pui.new("checkbox", "Ping"),
                kdr = pui.new("checkbox", "KDR"),
                velocity = pui.new("checkbox", "Velocity"),
                server_framerate = pui.new("checkbox", "Server framerate"),
                server_info = pui.new("checkbox", "Server info"),
                tickrate = pui.new("checkbox", "Tickrate"),
                time = pui.new("checkbox", "Time"),
                gradient = pui.new("checkbox", "Gradient header"),
                color = pui.new("color_picker", "Color", 255, 255, 255, 255)
            }
        },
        
        run = function(self)
            -- Render the pui menu
            if self.menu then
                -- Try to force pui to render by accessing elements
                if self.menu.label then
                    -- Access the label to ensure it's rendered
                    local _ = self.menu.label
                end
                
                -- Access other key elements to ensure they're rendered
                if self.menu.aa then
                    if self.menu.aa.mode then local _ = self.menu.aa.mode end
                    if self.menu.aa.preset_list then local _ = self.menu.aa.preset_list end
                end
                
                -- Access config elements
                if self.menu.config then
                    if self.menu.config.save then local _ = self.menu.config.save end
                    if self.menu.config.load then local _ = self.menu.config.load end
                end
                
                -- Access misc elements
                if self.menu.misc then
                    if self.menu.misc.animations_selector then local _ = self.menu.misc.animations_selector end
                end
            end
        end
    }
end

function ctx:setup_helpers()
    self.helpers = {
        contains = function(self, table, value)
            for _, v in ipairs(table) do
                if v == value then
                    return true
                end
            end
            return false
        end,
        
        get_lerp_time = function(self)
            return globals.tickinterval() * 2
        end,
        
        rgba_to_hex = function(self, r, g, b, a)
            return string.format("#%02X%02X%02X%02X", a, r, g, b)
        end,
        
        easeInOut = function(self, t)
            return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
        end,
        
        animate_text = function(self, text, speed)
            local time = globals.realtime() * speed
            local len = #text
            local result = ""
            for i = 1, len do
                local char = text:sub(i, i)
                local offset = math.sin(time + i * 0.5) * 0.5 + 0.5
                result = result .. char
            end
            return result
        end,
        
        clamp = function(self, value, min, max)
            return math.max(min, math.min(max, value))
        end,
        
        get_damage = function(self, weapon, hitgroup)
            local damage = 0
            if weapon then
                damage = weapon.damage or 0
                if hitgroup == 1 then
                    damage = damage * 4
                elseif hitgroup == 2 then
                    damage = damage * 1.25
                end
            end
            return damage
        end,
        
        normalize = function(self, angle)
            while angle > 180 do
                angle = angle - 360
            end
            while angle < -180 do
                angle = angle + 360
            end
            return angle
        end,
        
        fetch_data = function(self, player)
            return {
                origin = vector(entity.get_origin(player)),
                eye_angles = vector(entity.get_prop(player, "m_angEyeAngles")),
                simulation_time = entity.get_prop(player, "m_flSimulationTime"),
                velocity = vector(entity.get_prop(player, "m_vecVelocity")),
                health = entity.get_prop(player, "m_iHealth"),
                armor = entity.get_prop(player, "m_ArmorValue"),
                has_helmet = entity.get_prop(player, "m_bHasHelmet") == 1,
                has_defuser = entity.get_prop(player, "m_bHasDefuser") == 1,
                is_scoped = entity.get_prop(player, "m_bIsScoped") == 1,
                is_flashed = entity.get_prop(player, "m_flFlashMaxAlpha") > 0,
                is_dormant = entity.is_dormant(player),
                is_alive = entity.is_alive(player)
            }
        end,
        
        time_to_ticks = function(self, time)
            return math.floor(0.5 + time / globals.tickinterval())
        end,
        
        menu_visibility = function(self, element)
            return element:get() and 1 or 0
        end,
        
        in_ladder = function(self, player)
            return entity.get_prop(player, "m_MoveType") == 9
        end,
        
        in_air = function(self, player)
            return bit.band(entity.get_prop(player, "m_fFlags"), 1) == 0
        end,
        
        in_duck = function(self, player)
            return bit.band(entity.get_prop(player, "m_fFlags"), 2) ~= 0
        end,
        
        get_eye_yaw = function(self, player)
            return entity.get_prop(player, "m_angEyeAngles[1]")
        end,
        
        get_closest_angle = function(self, angles, target)
            local closest = angles[1]
            local min_diff = math.abs(angles[1] - target)
            for i = 2, #angles do
                local diff = math.abs(angles[i] - target)
                if diff < min_diff then
                    min_diff = diff
                    closest = angles[i]
                end
            end
            return closest
        end,
        
        get_freestanding_side = function(self, data)
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
                return 1
            else
                return 0
            end
        end,
        
        get_state = function(self)
            local me = entity.get_local_player()
            if not entity.is_alive(me) then
                return "dead"
            end
            
            local velocity = vector(entity.get_prop(me, "m_vecVelocity")):length2d()
            local in_air = self:in_air(me)
            local in_duck = self:in_duck(me)
            local in_ladder = self:in_ladder(me)
            
            if in_ladder then
                return "ladder"
            elseif in_air then
                return "jump"
            elseif in_duck then
                if velocity > 3 then
                    return "duck move"
                else
                    return "duck"
                end
            elseif velocity < 3 then
                return "stand"
            elseif velocity < 100 then
                return "slow walk"
            else
                return "run"
            end
        end,
        
        get_team = function(self)
            local me = entity.get_local_player()
            local team = entity.get_prop(me, "m_iTeamNum")
            return team == 2 and "t" or "ct"
        end,
        
        loop = function(self, table, func)
            for k, v in pairs(table) do
                func(k, v)
            end
        end,
        
        get_charge = function(self)
            local me = entity.get_local_player()
            local weapon = entity.get_player_weapon(me)
            if not weapon then
                return 0
            end
            
            local next_attack = entity.get_prop(me, "m_flNextAttack")
            local next_primary_attack = entity.get_prop(weapon, "m_flNextPrimaryAttack")
            local curtime = globals.curtime()
            
            if next_attack > curtime or next_primary_attack > curtime then
                return math.max(next_attack - curtime, next_primary_attack - curtime)
            end
            
            return 0
        end
    }
end

function ctx:setup_config()
    self.config = {
        configs = {},
        
        save = function(self)
            local name = self.ui.menu.cfg.name:get()
            if name == "" then
                return print("Please enter a config name")
            end
            
            local data = {
                aa = {},
                misc = {},
                visuals = {},
                game_enhancer = {},
                aim_punch_fix = {},
                secret_exploit = {},
                watermark = {}
            }
            
            -- Save AA settings
            for team, states in pairs(self.ui.menu.aa.states) do
                data.aa[team] = {}
                for state, settings in pairs(states) do
                    data.aa[team][state] = {}
                    for key, element in pairs(settings) do
                        data.aa[team][state][key] = element:get()
                    end
                end
            end
            
            -- Save misc settings
            for key, element in pairs(self.ui.menu.misc) do
                data.misc[key] = element:get()
            end
            
            -- Save visuals settings
            for key, element in pairs(self.ui.menu.visuals) do
                data.visuals[key] = element:get()
            end
            
            -- Save other settings
            for key, element in pairs(self.ui.menu.game_enhancer) do
                data.game_enhancer[key] = element:get()
            end
            
            for key, element in pairs(self.ui.menu.aim_punch_fix) do
                data.aim_punch_fix[key] = element:get()
            end
            
            for key, element in pairs(self.ui.menu.secret_exploit) do
                data.secret_exploit[key] = element:get()
            end
            
            for key, element in pairs(self.ui.menu.watermark) do
                data.watermark[key] = element:get()
            end
            
            self.configs[name] = data
            self:update_configs()
            print("Config saved: " .. name)
        end,
        
        load = function(self)
            local name = self.ui.menu.cfg.name:get()
            local data = self.configs[name]
            if not data then
                return print("Config not found: " .. name)
            end
            
            -- Load AA settings
            for team, states in pairs(data.aa) do
                for state, settings in pairs(states) do
                    for key, value in pairs(settings) do
                        if self.ui.menu.aa.states[team] and self.ui.menu.aa.states[team][state] and self.ui.menu.aa.states[team][state][key] then
                            self.ui.menu.aa.states[team][state][key]:set(value)
                        end
                    end
                end
            end
            
            -- Load other settings
            for key, value in pairs(data.misc) do
                if self.ui.menu.misc[key] then
                    self.ui.menu.misc[key]:set(value)
                end
            end
            
            for key, value in pairs(data.visuals) do
                if self.ui.menu.visuals[key] then
                    self.ui.menu.visuals[key]:set(value)
                end
            end
            
            for key, value in pairs(data.game_enhancer) do
                if self.ui.menu.game_enhancer[key] then
                    self.ui.menu.game_enhancer[key]:set(value)
                end
            end
            
            for key, value in pairs(data.aim_punch_fix) do
                if self.ui.menu.aim_punch_fix[key] then
                    self.ui.menu.aim_punch_fix[key]:set(value)
                end
            end
            
            for key, value in pairs(data.secret_exploit) do
                if self.ui.menu.secret_exploit[key] then
                    self.ui.menu.secret_exploit[key]:set(value)
                end
            end
            
            for key, value in pairs(data.watermark) do
                if self.ui.menu.watermark[key] then
                    self.ui.menu.watermark[key]:set(value)
                end
            end
            
            print("Config loaded: " .. name)
        end,
        
        update_configs = function(self)
            local configs = {}
            for name, _ in pairs(self.configs) do
                table.insert(configs, name)
            end
            self.ui.menu.cfg.list:set_items(configs)
        end,
        
        export = function(self)
            local name = self.ui.menu.cfg.name:get()
            local data = self.configs[name]
            if not data then
                return print("Config not found: " .. name)
            end
            
            local json_data = json.stringify(data)
            clipboard.set(json_data)
            print("Config exported to clipboard: " .. name)
        end,
        
        import = function(self)
            local json_data = clipboard.get()
            local data = json.parse(json_data)
            if not data then
                return print("Invalid JSON data")
            end
            
            local name = self.ui.menu.cfg.name:get()
            if name == "" then
                return print("Please enter a config name")
            end
            
            self.configs[name] = data
            self:update_configs()
            print("Config imported: " .. name)
        end,
        
        delete = function(self)
            local name = self.ui.menu.cfg.name:get()
            local data = self.configs[name]
            if not data then
                return print("Config not found: " .. name)
            end
            
            self.configs[name] = nil
            self:update_configs()
            print("Config deleted: " .. name)
        end
    }
end

function ctx:setup_prediction()
    self.prediction = {
        run = function(self, ent, ticks)
            local origin = vector(entity.get_origin(ent))
            local velocity = vector(entity.get_prop(ent, 'm_vecVelocity'))
            velocity.z = 0
            local predicted = origin + velocity * globals.tickinterval() * ticks
            
            return {
                origin = predicted
            }
        end
    }
end

function ctx:setup_fakelag()
    self.fakelag = {
        send_packet = true,
        
        get_limit = function(self)
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
        
        run = function(self, cmd)
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
end

function ctx:setup_desync()
    self.desync = {
        switch_move = true,
        
        get_yaw_base = function(self, base)
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
        
        can_desync = function(self, cmd)
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
        
        run = function(self, cmd, send_packet, data)
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
end

function ctx:setup_antiaim()
    self.antiaim = {
        side = 0,
        last_rand = 0,
        skitter_counter = 0,
        last_skitter = 0,
        last_count = 0,
        cycle = 0,
        manual_side = 0,
        freestanding_side = 0,
        
        anti_backstab = function(self)
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
        
        calculate_additional_states = function(self, team, state)
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
        
        get_best_side = function(self, opposite)
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
        
        get_manual = function(self)
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
        
        run = function(self, cmd)
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
        
        set_builder = function(self, cmd, state, team)
            if not self.ui.menu.aa.states[team][state].enable() then
                state = "global"
            end
            
            local data = {}
            for k, v in pairs(self.ui.menu.aa.states[team][state]) do
                data[k] = v()
            end
            
            self:set(cmd, data)
        end,
        
        set_preset = function(self, cmd, state, team)
            local preset = self.ui.menu.aa.preset_list:get()
            
            local presets = {
                [0] = function()
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
                [1] = function()
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
            
            return presets[preset]()
        end,
        
        set = function(self, cmd, data)
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
        
        get_defensive = function(self, conditions, state)
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
        end
    }
end

function ctx:setup_resolver()
    self.resolver = {
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
        end
    }
end

function ctx:setup_net_channel()
    self.net_channel = {
        run = function(self)
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
end

function ctx:setup_defensive()
    self.defensive = {
        ticks = 0,
        defensive = 0,
        
        run = function(self, cmd)
            if cmd.force_defensive then
                self.ticks = self.ticks + 1
                self.defensive = self.defensive + 1
            else
                self.ticks = 0
                self.defensive = 0
            end
        end
    }
end

function ctx:setup_predict()
    self.predict = {
        run = function(self, cmd)
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
end

function ctx:setup_peekbot()
    self.peekbot = {
        run = function(self, cmd)
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
end

function ctx:setup_visuals()
    self.visuals = {
        run = function(self)
            if not self.ui.menu.visuals.enable() then
                return
            end
            
            local players = entity.get_players(true)
            if #players == 0 then
                return
            end
            
            for _, player in ipairs(players) do
                if not entity.is_alive(player) then
                    goto continue
                end
                
                local x, y, w, h = entity.get_bounding_box(player)
                if not x then
                    goto continue
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
                ::continue::
            end
        end
    }
end

function ctx:setup_watermark()
    self.watermark = {
        run = function(self)
            if not self.ui.menu.watermark.enable() then
                return
            end
            
            local elements = {}
            local color = self.ui.menu.watermark.color()
            local r, g, b, a = color.r, color.g, color.b, color.a
            
            if self.ui.menu.watermark.logo() then
                table.insert(elements, "[VOID]")
            end
            
            if self.ui.menu.watermark.custom_text() then
                table.insert(elements, "Custom Text")
            end
            
            if self.ui.menu.watermark.fps() then
                table.insert(elements, "FPS: " .. math.floor(1 / globals.frametime()))
            end
            
            if self.ui.menu.watermark.ping() then
                table.insert(elements, "Ping: " .. math.floor(utils.net_channel_info().latency * 1000) .. "ms")
            end
            
            if self.ui.menu.watermark.kdr() then
                local kills = entity.get_prop(entity.get_local_player(), "m_iKills")
                local deaths = entity.get_prop(entity.get_local_player(), "m_iDeaths")
                local kdr = deaths > 0 and (kills / deaths) or kills
                table.insert(elements, "KDR: " .. string.format("%.2f", kdr))
            end
            
            if self.ui.menu.watermark.velocity() then
                local me = entity.get_local_player()
                local velocity = vector(entity.get_prop(me, "m_vecVelocity")):length2d()
                table.insert(elements, "Velocity: " .. math.floor(velocity))
            end
            
            if self.ui.menu.watermark.server_framerate() then
                table.insert(elements, "Server FPS: " .. math.floor(1 / globals.tickinterval()))
            end
            
            if self.ui.menu.watermark.server_info() then
                table.insert(elements, "Server: " .. (utils.net_channel_info().address or "Unknown"))
            end
            
            if self.ui.menu.watermark.tickrate() then
                table.insert(elements, "Tickrate: " .. math.floor(1 / globals.tickinterval()))
            end
            
            if self.ui.menu.watermark.time() then
                local time = os.date("%H:%M:%S")
                table.insert(elements, "Time: " .. time)
            end
            
            local text = table.concat(elements, " | ")
            local text_width = renderer.measure_text(nil, text)
            local x = 10
            local y = 10
            
            if self.ui.menu.watermark.gradient() then
                renderer.gradient(x, y, text_width + 10, 20, r, g, b, a, r, g, b, 0, false)
            else
                renderer.rectangle(x, y, text_width + 10, 20, r, g, b, a)
            end
            
            renderer.text(x + 5, y + 5, 255, 255, 255, 255, nil, 0, text)
        end
    }
end

function ctx:setup_game_enhancer()
    self.game_enhancer = {
        run = function(self)
            if not self.ui.menu.game_enhancer.enable() then
                return
            end
            
            local boost = self.ui.menu.game_enhancer.boost()
            local cvar_values = {
                [0] = { -- Low
                    ["r_drawparticles"] = 0,
                    ["r_drawtracers"] = 0,
                    ["r_drawdecals"] = 0,
                    ["r_drawstaticprops"] = 0,
                    ["r_drawdynamicprops"] = 0,
                    ["r_drawropes"] = 0,
                    ["r_drawsprites"] = 0,
                    ["r_drawviewmodel"] = 0,
                    ["r_drawtranslucentrenderables"] = 0,
                    ["r_drawopaquerenderables"] = 0,
                    ["r_drawopaqueworld"] = 0,
                    ["r_drawtranslucentworld"] = 0,
                    ["r_drawopaqueworldstaticprops"] = 0,
                    ["r_drawtranslucentworldstaticprops"] = 0,
                    ["r_drawopaqueworlddynamicprops"] = 0,
                    ["r_drawtranslucentworlddynamicprops"] = 0,
                    ["r_drawopaqueworldbrushmodels"] = 0,
                    ["r_drawtranslucentworldbrushmodels"] = 0,
                    ["r_drawopaqueworlddisplacements"] = 0,
                    ["r_drawtranslucentworlddisplacements"] = 0,
                    ["r_drawopaqueworldoverlays"] = 0,
                    ["r_drawtranslucentworldoverlays"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0
                },
                [1] = { -- Medium
                    ["r_drawparticles"] = 0,
                    ["r_drawtracers"] = 0,
                    ["r_drawdecals"] = 0,
                    ["r_drawstaticprops"] = 0,
                    ["r_drawdynamicprops"] = 0,
                    ["r_drawropes"] = 0,
                    ["r_drawsprites"] = 0,
                    ["r_drawviewmodel"] = 0,
                    ["r_drawtranslucentrenderables"] = 0,
                    ["r_drawopaquerenderables"] = 0,
                    ["r_drawopaqueworld"] = 0,
                    ["r_drawtranslucentworld"] = 0,
                    ["r_drawopaqueworldstaticprops"] = 0,
                    ["r_drawtranslucentworldstaticprops"] = 0,
                    ["r_drawopaqueworlddynamicprops"] = 0,
                    ["r_drawtranslucentworlddynamicprops"] = 0,
                    ["r_drawopaqueworldbrushmodels"] = 0,
                    ["r_drawtranslucentworldbrushmodels"] = 0,
                    ["r_drawopaqueworlddisplacements"] = 0,
                    ["r_drawtranslucentworlddisplacements"] = 0,
                    ["r_drawopaqueworldoverlays"] = 0,
                    ["r_drawtranslucentworldoverlays"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0
                },
                [2] = { -- High
                    ["r_drawparticles"] = 0,
                    ["r_drawtracers"] = 0,
                    ["r_drawdecals"] = 0,
                    ["r_drawstaticprops"] = 0,
                    ["r_drawdynamicprops"] = 0,
                    ["r_drawropes"] = 0,
                    ["r_drawsprites"] = 0,
                    ["r_drawviewmodel"] = 0,
                    ["r_drawtranslucentrenderables"] = 0,
                    ["r_drawopaquerenderables"] = 0,
                    ["r_drawopaqueworld"] = 0,
                    ["r_drawtranslucentworld"] = 0,
                    ["r_drawopaqueworldstaticprops"] = 0,
                    ["r_drawtranslucentworldstaticprops"] = 0,
                    ["r_drawopaqueworlddynamicprops"] = 0,
                    ["r_drawtranslucentworlddynamicprops"] = 0,
                    ["r_drawopaqueworldbrushmodels"] = 0,
                    ["r_drawtranslucentworldbrushmodels"] = 0,
                    ["r_drawopaqueworlddisplacements"] = 0,
                    ["r_drawtranslucentworlddisplacements"] = 0,
                    ["r_drawopaqueworldoverlays"] = 0,
                    ["r_drawtranslucentworldoverlays"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0
                },
                [3] = { -- Ultra
                    ["r_drawparticles"] = 0,
                    ["r_drawtracers"] = 0,
                    ["r_drawdecals"] = 0,
                    ["r_drawstaticprops"] = 0,
                    ["r_drawdynamicprops"] = 0,
                    ["r_drawropes"] = 0,
                    ["r_drawsprites"] = 0,
                    ["r_drawviewmodel"] = 0,
                    ["r_drawtranslucentrenderables"] = 0,
                    ["r_drawopaquerenderables"] = 0,
                    ["r_drawopaqueworld"] = 0,
                    ["r_drawtranslucentworld"] = 0,
                    ["r_drawopaqueworldstaticprops"] = 0,
                    ["r_drawtranslucentworldstaticprops"] = 0,
                    ["r_drawopaqueworlddynamicprops"] = 0,
                    ["r_drawtranslucentworlddynamicprops"] = 0,
                    ["r_drawopaqueworldbrushmodels"] = 0,
                    ["r_drawtranslucentworldbrushmodels"] = 0,
                    ["r_drawopaqueworlddisplacements"] = 0,
                    ["r_drawtranslucentworlddisplacements"] = 0,
                    ["r_drawopaqueworldoverlays"] = 0,
                    ["r_drawtranslucentworldoverlays"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0,
                    ["r_drawopaqueworldwater"] = 0,
                    ["r_drawtranslucentworldwater"] = 0,
                    ["r_drawopaqueworldskybox"] = 0,
                    ["r_drawtranslucentworldskybox"] = 0,
                    ["r_drawopaqueworldfog"] = 0,
                    ["r_drawtranslucentworldfog"] = 0,
                    ["r_drawopaqueworldlighting"] = 0,
                    ["r_drawtranslucentworldlighting"] = 0,
                    ["r_drawopaqueworldshadows"] = 0,
                    ["r_drawtranslucentworldshadows"] = 0,
                    ["r_drawopaqueworldreflections"] = 0,
                    ["r_drawtranslucentworldreflections"] = 0,
                    ["r_drawopaqueworldrefractions"] = 0,
                    ["r_drawtranslucentworldrefractions"] = 0,
                    ["r_drawopaqueworldglass"] = 0,
                    ["r_drawtranslucentworldglass"] = 0
                }
            }
            
            local values = cvar_values[boost]
            if values then
                for cvar, value in pairs(values) do
                    cvar.set(cvar, value)
                end
            end
        end
    }
end

function ctx:setup_aim_punch_fix()
    self.aim_punch_fix = {
        run = function(self, cmd)
            if not self.ui.menu.aim_punch_fix.enable() then
                return
            end
            
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
            
            local aim_punch = entity.get_prop(me, "m_aimPunchAngle")
            if aim_punch then
                local punch_x = aim_punch.x
                local punch_y = aim_punch.y
                
                if math.abs(punch_x) > 0.1 or math.abs(punch_y) > 0.1 then
                    cvar.set("cl_min_hitchance", 0)
                else
                    cvar.set("cl_min_hitchance", 1)
                end
            end
        end
    }
end

function ctx:setup_secret_exploit()
    self.secret_exploit = {
        run = function(self, cmd)
            if not self.ui.menu.secret_exploit.enable() then
                return
            end
            
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
                cmd.pitch = cmd.pitch + 0.1
                cmd.yaw = cmd.yaw + 0.1
                cmd.forwardmove = cmd.forwardmove + 0.1
                cmd.sidemove = cmd.sidemove + 0.1
            end
        end
    }
end

-- Event callbacks
client.set_event_callback('load', function()
    ctx:init()
    
    -- Register all other callbacks after initialization
    client.set_event_callback('setup_command', function(cmd)
        ctx.antiaim:run(cmd)
        ctx.fakelag:run(cmd)
        ctx.defensive:run(cmd)
        ctx.predict:run(cmd)
        ctx.peekbot:run(cmd)
        ctx.antiaim:animations()
        ctx.aim_punch_fix:run(cmd)
        ctx.secret_exploit:run(cmd)
        ctx.game_enhancer:run()
    end)

    client.set_event_callback('shutdown', function()
        ctx:shutdown()
    end)

    client.set_event_callback('run_command', function(cmd)
        ctx.net_channel:run()
    end)

    client.set_event_callback('paint', function()
        ctx.visuals:run()
        ctx.watermark:run()
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
end)

-- Register ESP flag for resolver
client.register_esp_flag('VOID', 255, 255, 255, function(player)
    return resolver_flag[player] or ''
end)