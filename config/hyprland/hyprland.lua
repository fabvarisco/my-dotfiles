-- Hyprland 0.55+ loads this file instead of hyprland.conf.
-- https://wiki.hypr.land/Configuring/Start/

local username = "@USERNAME@"
local profile = "/etc/profiles/per-user/" .. username
local home = os.getenv("HOME") or ""

local terminal = "kitty"
local fileManager = "nautilus"
local menu = "vicinae toggle"
local mainMod = "SUPER"

------------------
---- MONITORS ----
------------------

-- hyprmon still writes hyprlang lines to monitors.conf (Super+D).
local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_csv(value)
    local parts = {}
    local start = 1
    while true do
        local comma = string.find(value, ",", start, true)
        if not comma then
            parts[#parts + 1] = trim(string.sub(value, start))
            break
        end
        parts[#parts + 1] = trim(string.sub(value, start, comma - 1))
        start = comma + 1
    end
    return parts
end

local function load_monitors(path)
    local file = io.open(path, "r")
    if not file then
        return false
    end

    local loaded = false
    for line in file:lines() do
        local body = line:match("^%s*monitor%s*=%s*(.*)$")
        if body and body ~= "" then
            local fields = split_csv(body)
            local spec = { output = fields[1] or "" }
            local mode = fields[2]
            if mode == "disable" or mode == "disabled" then
                spec.disabled = true
            else
                if mode and mode ~= "" then spec.mode = mode end
                if fields[3] and fields[3] ~= "" then spec.position = fields[3] end
                if fields[4] and fields[4] ~= "" then
                    spec.scale = tonumber(fields[4]) or fields[4]
                end
                if fields[5] and fields[5] ~= "" then spec.transform = tonumber(fields[5]) end
                if fields[6] and fields[6] ~= "" then spec.vrr = tonumber(fields[6]) end
            end
            hl.monitor(spec)
            loaded = true
        end
    end

    file:close()
    return loaded
end

if not load_monitors(home .. "/.config/hypr/monitors.conf") then
    hl.monitor({ output = "desc:Dell Inc. DELL P3425WE", mode = "3440x1440@100", position = "0x0", scale = 1 })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR DISPLAY")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sleep 2 && " .. profile .. "/bin/noctalia-shell")
    hl.exec_cmd("sleep 3 && pw-play " .. profile .. "/share/sounds/Oxygen-Sys-Log-In.ogg")
    hl.exec_cmd("sleep 1 && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' && gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
    hl.exec_cmd("cp -n ~/.config/kde/kdeglobals ~/.config/kdeglobals 2>/dev/null || true")
    hl.exec_cmd('hyprctl setcursor "AOSP Cursors" 24')
    -- vicinae is started by the systemd user service. A second
    -- `vicinae server` here registers another tray icon.
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "AOSP Cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "Breeze")

-----------------------
---- LOOK AND FEEL ----
-----------------------

local function saved_sensitivity()
    local file = io.open(home .. "/.local/state/hypr/mouse-sensitivity", "r")
    if not file then
        return 0
    end
    local value = tonumber(file:read("*l"))
    file:close()
    return value or 0
end

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = "rgb(cdd6f4)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        extend_border_grab_area = 15,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.95,
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            new_optimizations = true,
            xray = false,
        },
        shadow = {
            enabled = true,
            range = 8,
            render_power = 2,
            color = "rgba(1a1a1aee)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        -- Default 1.0 keeps splitting an ultrawide into columns (1x1x1).
        -- 1.5 stacks the third window (1 | 2) on the Dell.
        split_width_multiplier = 1.5,
    },

    master = {
        new_on_top = true,
    },

    misc = {
        disable_hyprland_logo = true,
        vrr = 0,
        focus_on_activate = true,
    },

    debug = {
        disable_logs = false,
        vfr = true,
    },

    render = {
        direct_scanout = false,
    },

    cursor = {
        inactive_timeout = 20, -- 0.56 caps this at 20 seconds
        no_hardware_cursors = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 35,
        repeat_delay = 200,
        follow_mouse = 1,
        sensitivity = saved_sensitivity(),
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
            scroll_factor = 1.0,
        },
    },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.1, 0.9 }, { 0.05, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 90%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "myBezier", style = "slidefadevert 30%" })

---------------------
---- KEYBINDINGS ----
---------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(
    "pw-play " .. profile .. "/share/sounds/Oxygen-Sys-Log-Out.ogg; hyprctl dispatch 'hl.dsp.exit()'"
))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd([[vicinae 'vicinae://launch/clipboard/history?toggle=true']]))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/wallpaper-vicinae.sh"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("kitty --class hyprmon -e hyprmon"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("kitty --class mouse-sens -e ~/.config/hypr/mouse-sensitivity.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("kitty --class cava -e cava"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + G", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

local arrows = { left = "l", right = "r", up = "u", down = "d" }
for key, direction in pairs(arrows) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

hl.bind(mainMod .. " + ALT + period", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + ALT + comma", hl.dsp.window.move({ monitor = "-1" }))

for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT + Tab", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

hl.bind("Print", hl.dsp.exec_cmd([[grim - | wl-copy && notify-send "Screenshot" "Copied to clipboard"]]))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd([[grim ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png && notify-send "Screenshot" "Saved to ~/Pictures"]]))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "Region copied to clipboard"]]))

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/gpu-screen.sh record-toggle"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/gpu-screen.sh replay-toggle"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/gpu-screen.sh replay-save"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name = "ghost-windows",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
    },
    no_focus = true,
})

local function floating_dialog(name, class)
    hl.window_rule({
        name = name,
        match = { class = "^(" .. class .. ")$" },
        float = true,
        size = { 800, 800 },
        center = true,
    })
end

floating_dialog("floating", "floating")
floating_dialog("mouse-sens", "mouse-sens")
floating_dialog("hyprmon", "hyprmon")

hl.window_rule({
    name = "zen-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
})

hl.layer_rule({
    name = "vicinae-blur",
    match = { namespace = "vicinae" },
    blur = true,
    xray = false,
})
