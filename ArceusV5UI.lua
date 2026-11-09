--[[
    ArceusV5UI.lua
    Arceus X v5 style interface in ONE LocalScript.

    Tabs: Home / Code / Hub / Arcy / Game / Settings

    Notes
      - Your AI API key is NOT stored in this file. Paste it in
        Settings > Arcy AI. It is saved only in your local
        ArceusV5UI/settings.json (if your executor supports writefile).
      - Never commit settings.json (or any key) to GitHub.
      - Pure ASCII on purpose (no unicode characters).
      - Logo and icons are placeholders. Put your own rbxassetid values
        in CONFIG.LogoAsset and CONFIG.Icons.

    Load from GitHub:
      loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/ArceusV5UI.lua"))()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local CONFIG = {
    Name = "Arceus X v5 UI",
    Version = "1.0.0",
    SaveFolder = "ArceusV5UI",
    LogoAsset = "",
    Icons = { Home = "", Code = "", Hub = "", Arcy = "", Game = "", Settings = "" },
    DefaultEndpoint = "https://api.openai.com/v1/chat/completions",
    DefaultModel = "gpt-4o-mini",
    SystemPrompt = "You are Arcy, a friendly Roblox scripting assistant. When asked for a script, reply with one short working Luau code block. Do not use unicode characters in code.",
}

local DEFAULTS = {
    Theme = "Crimson",
    Animations = true,
    AnimStyle = "Smooth",
    AnimSpeed = 1,
    Transition = "Slide",
    Transparency = 0.12,
    Corner = 16,
    Scale = 1,
    Blur = false,
    ShowFps = false,
    MusicId = "",
    ApiKey = "",
    Endpoint = CONFIG.DefaultEndpoint,
    Model = CONFIG.DefaultModel,
    Starred = {},
}

--------------------------------------------------------------------
-- UTILS + SAVE SYSTEM
--------------------------------------------------------------------
local function copyTable(t)
    local out = {}
    for k, v in pairs(t) do
        if type(v) == "table" then out[k] = copyTable(v) else out[k] = v end
    end
    return out
end

local HAS_FS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

local function ensureFolder()
    if HAS_FS and type(makefolder) == "function" and type(isfolder) == "function" then
        local ok, exists = pcall(isfolder, CONFIG.SaveFolder)
        if ok and not exists then pcall(makefolder, CONFIG.SaveFolder) end
    end
end

local function readData(name)
    if not HAS_FS then return nil end
    local p = CONFIG.SaveFolder .. "/" .. name
    local ok, exists = pcall(isfile, p)
    if ok and exists then
        local ok2, data = pcall(readfile, p)
        if ok2 then return data end
    end
    return nil
end

local function writeData(name, data)
    if not HAS_FS then return end
    ensureFolder()
    pcall(writefile, CONFIG.SaveFolder .. "/" .. name, data)
end

local Settings = copyTable(DEFAULTS)
do
    local raw = readData("settings.json")
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if DEFAULTS[k] ~= nil and type(v) == type(DEFAULTS[k]) then Settings[k] = v end
            end
        end
    end
end

local Files = {}
do
    local raw = readData("files.json")
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            for _, f in ipairs(data) do
                if type(f) == "table" and type(f.name) == "string" and type(f.code) == "string" then
                    table.insert(Files, { name = f.name, code = f.code, starred = f.starred == true })
                end
            end
        end
    end
    if #Files == 0 then
        table.insert(Files, {
            name = "Script n.1",
            code = "local Time = 2\n\ntask.wait(Time)\nprint(\"Waited \" .. Time .. \" seconds\")",
            starred = false,
        })
    end
end

local function saveSettingsNow()
    local ok, json = pcall(function() return HttpService:JSONEncode(Settings) end)
    if ok then writeData("settings.json", json) end
end

local function saveFilesNow()
    local ok, json = pcall(function() return HttpService:JSONEncode(Files) end)
    if ok then writeData("files.json", json) end
end

local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(1.5, function()
        saveQueued = false
        saveSettingsNow()
        saveFilesNow()
    end)
end

--------------------------------------------------------------------
-- THEMES
--------------------------------------------------------------------
local THEMES = {
    Crimson = {
        Bg = Color3.fromRGB(13, 13, 17), Panel = Color3.fromRGB(27, 25, 31), Panel2 = Color3.fromRGB(42, 38, 46),
        Accent = Color3.fromRGB(200, 32, 48), Accent2 = Color3.fromRGB(70, 130, 235),
        Text = Color3.fromRGB(242, 242, 246), Sub = Color3.fromRGB(150, 148, 162),
        OnAccent = Color3.fromRGB(255, 255, 255), Bad = Color3.fromRGB(240, 80, 80),
    },
    Violet = {
        Bg = Color3.fromRGB(14, 12, 22), Panel = Color3.fromRGB(28, 24, 42), Panel2 = Color3.fromRGB(42, 36, 62),
        Accent = Color3.fromRGB(140, 90, 235), Accent2 = Color3.fromRGB(70, 150, 240),
        Text = Color3.fromRGB(244, 242, 250), Sub = Color3.fromRGB(155, 150, 175),
        OnAccent = Color3.fromRGB(255, 255, 255), Bad = Color3.fromRGB(240, 80, 100),
    },
    Ocean = {
        Bg = Color3.fromRGB(9, 15, 23), Panel = Color3.fromRGB(19, 31, 45), Panel2 = Color3.fromRGB(30, 48, 68),
        Accent = Color3.fromRGB(35, 160, 230), Accent2 = Color3.fromRGB(95, 110, 240),
        Text = Color3.fromRGB(240, 246, 250), Sub = Color3.fromRGB(140, 160, 178),
        OnAccent = Color3.fromRGB(255, 255, 255), Bad = Color3.fromRGB(240, 90, 90),
    },
    Emerald = {
        Bg = Color3.fromRGB(9, 17, 14), Panel = Color3.fromRGB(19, 33, 27), Panel2 = Color3.fromRGB(30, 50, 42),
        Accent = Color3.fromRGB(40, 190, 120), Accent2 = Color3.fromRGB(60, 150, 210),
        Text = Color3.fromRGB(240, 248, 244), Sub = Color3.fromRGB(140, 168, 155),
        OnAccent = Color3.fromRGB(10, 25, 18), Bad = Color3.fromRGB(240, 90, 90),
    },
    Mono = {
        Bg = Color3.fromRGB(14, 14, 14), Panel = Color3.fromRGB(28, 28, 28), Panel2 = Color3.fromRGB(44, 44, 44),
        Accent = Color3.fromRGB(225, 225, 225), Accent2 = Color3.fromRGB(140, 140, 140),
        Text = Color3.fromRGB(245, 245, 245), Sub = Color3.fromRGB(150, 150, 150),
        OnAccent = Color3.fromRGB(20, 20, 20), Bad = Color3.fromRGB(240, 90, 90),
    },
}
local THEME_NAMES = { "Crimson", "Violet", "Ocean", "Emerald", "Mono" }

local function Theme(key)
    local t = THEMES[Settings.Theme] or THEMES.Crimson
    return t[key]
end

--------------------------------------------------------------------
-- REGISTRIES, TWEEN, INSTANCE HELPERS
--------------------------------------------------------------------
local themedList, panelList, cornerList = {}, {}, {}
local themeHooks, refreshers, starRefreshers, heartbeatHooks = {}, {}, {}, {}
local connections = {}
local alive = true

local destroyUI, commitEditor, loadIntoEditor, renderHub, showPage

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local EASE = {
    Smooth = { Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
    Bouncy = { Enum.EasingStyle.Back, Enum.EasingDirection.Out },
    Snappy = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
    Elastic = { Enum.EasingStyle.Elastic, Enum.EasingDirection.Out },
    Linear = { Enum.EasingStyle.Linear, Enum.EasingDirection.Out },
}
local ANIM_STYLES = { "Smooth", "Bouncy", "Snappy", "Elastic", "Linear" }
local TRANSITIONS = { "Slide", "Fade", "Zoom" }

local function tween(inst, props, dur)
    if not Settings.Animations then
        for k, v in pairs(props) do inst[k] = v end
        return nil
    end
    local e = EASE[Settings.AnimStyle] or EASE.Smooth
    local t = TweenService:Create(inst, TweenInfo.new((dur or 0.3) / Settings.AnimSpeed, e[1], e[2]), props)
    t:Play()
    return t
end

local function tweenFixed(inst, props, dur)
    if not Settings.Animations then
        for k, v in pairs(props) do inst[k] = v end
        return
    end
    TweenService:Create(inst, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function new(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local Gui = new("ScreenGui", {
    Name = "ArceusV5UI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
do
    local ok = pcall(function()
        if type(gethui) == "function" then Gui.Parent = gethui() else Gui.Parent = game:GetService("CoreGui") end
    end)
    if not ok or not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function bindTheme(inst, prop, key)
    table.insert(themedList, { inst = inst, prop = prop, key = key })
    inst[prop] = Theme(key)
end

local function round(inst, ratio)
    local r = ratio or 1
    local c = new("UICorner", { CornerRadius = UDim.new(0, math.floor(Settings.Corner * r)) }, inst)
    table.insert(cornerList, { c = c, r = r })
    return c
end

local function pill(inst)
    return new("UICorner", { CornerRadius = UDim.new(1, 0) }, inst)
end

local function padding(inst, l, t, r, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0),
    }, inst)
end

local function panel(parent, size, pos, ratio, colorKey)
    local f = new("Frame", { Size = size, Position = pos or UDim2.new(0, 0, 0, 0), BorderSizePixel = 0 }, parent)
    bindTheme(f, "BackgroundColor3", colorKey or "Panel")
    f.BackgroundTransparency = Settings.Transparency
    table.insert(panelList, f)
    round(f, ratio or 0.8)
    return f
end

local function label(parent, text, o)
    o = o or {}
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = o.size or 14,
        Font = o.font or Enum.Font.GothamMedium,
        TextXAlignment = o.align or Enum.TextXAlignment.Left,
        TextYAlignment = o.yalign or Enum.TextYAlignment.Center,
        TextWrapped = o.wrap or false,
        Position = o.pos or UDim2.new(0, 0, 0, 0),
        Size = o.sz or UDim2.new(1, 0, 1, 0),
        AnchorPoint = o.anchor or Vector2.new(0, 0),
    }, parent)
    bindTheme(l, "TextColor3", o.color or "Text")
    if o.auto then l.AutomaticSize = o.auto end
    return l
end

local function button(parent, text, size, pos, cb, accent)
    local b = new("TextButton", {
        Size = size, Position = pos or UDim2.new(0, 0, 0, 0), Text = text,
        Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0,
    }, parent)
    bindTheme(b, "BackgroundColor3", accent and "Accent" or "Panel2")
    bindTheme(b, "TextColor3", accent and "OnAccent" or "Text")
    round(b, 0.6)
    b.MouseEnter:Connect(function() tweenFixed(b, { BackgroundTransparency = 0.25 }, 0.12) end)
    b.MouseLeave:Connect(function() tweenFixed(b, { BackgroundTransparency = 0 }, 0.12) end)
    b.Activated:Connect(function() if cb then cb(b) end end)
    return b
end

local function applyTheme()
    for i = #themedList, 1, -1 do
        local e = themedList[i]
        if e.inst:IsDescendantOf(Gui) then
            tweenFixed(e.inst, { [e.prop] = Theme(e.key) }, 0.3)
        else
            table.remove(themedList, i)
        end
    end
    for _, h in ipairs(themeHooks) do pcall(h) end
end

local function applyTransparency()
    for i = #panelList, 1, -1 do
        local f = panelList[i]
        if f:IsDescendantOf(Gui) then f.BackgroundTransparency = Settings.Transparency else table.remove(panelList, i) end
    end
end

local function applyCorners()
    for i = #cornerList, 1, -1 do
        local e = cornerList[i]
        if e.c.Parent then
            e.c.CornerRadius = UDim.new(0, math.floor(Settings.Corner * e.r))
        else
            table.remove(cornerList, i)
        end
    end
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function attachDrag(hit, measure, onAlpha, vertical)
    local dragging = false
    local function update(input)
        local a
        if vertical then
            a = 1 - math.clamp((input.Position.Y - measure.AbsolutePosition.Y) / math.max(measure.AbsoluteSize.Y, 1), 0, 1)
        else
            a = math.clamp((input.Position.X - measure.AbsolutePosition.X) / math.max(measure.AbsoluteSize.X, 1), 0, 1)
        end
        onAlpha(a)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

--------------------------------------------------------------------
-- NOTIFICATIONS + CONSOLE LOG
--------------------------------------------------------------------
local toastCount = 0
local function notify(text, dur)
    if not alive then return end
    local y = 10 + toastCount * 40
    toastCount = toastCount + 1
    local t = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -50),
        Size = UDim2.new(0, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.X,
        Text = text, Font = Enum.Font.GothamMedium, TextSize = 14, BorderSizePixel = 0, ZIndex = 50,
    }, Gui)
    bindTheme(t, "BackgroundColor3", "Panel2")
    bindTheme(t, "TextColor3", "Text")
    padding(t, 16, 0, 16, 0)
    pill(t)
    local st = new("UIStroke", { Thickness = 1, Transparency = 0.4 }, t)
    bindTheme(st, "Color", "Accent")
    tween(t, { Position = UDim2.new(0.5, 0, 0, y) }, 0.35)
    task.delay(dur or 2.2, function()
        toastCount = math.max(0, toastCount - 1)
        if t.Parent then
            tween(t, { Position = UDim2.new(0.5, 0, 0, -50) }, 0.3)
            task.delay(0.4, function() if t.Parent then t:Destroy() end end)
        end
    end)
end

local consoleScroll
local logLabels = {}
local logCount = 0
local function logLine(text, kind)
    if not consoleScroll then return end
    logCount = logCount + 1
    local color = Theme("Text")
    if kind == "err" then color = Theme("Bad") elseif kind == "warn" then color = Color3.fromRGB(240, 190, 70) end
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, Text = tostring(text), TextSize = 12, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color, LayoutOrder = logCount,
    }, consoleScroll)
    table.insert(logLabels, l)
    if #logLabels > 200 then
        local old = table.remove(logLabels, 1)
        old:Destroy()
    end
    task.defer(function()
        if consoleScroll and consoleScroll.Parent then
            consoleScroll.CanvasPosition = Vector2.new(0, consoleScroll.AbsoluteCanvasSize.Y)
        end
    end)
end

connect(LogService.MessageOut, function(msg, mtype)
    local kind = "info"
    if mtype == Enum.MessageType.MessageError then kind = "err"
    elseif mtype == Enum.MessageType.MessageWarning then kind = "warn" end
    logLine(msg, kind)
end)

--------------------------------------------------------------------
-- WINDOW SKELETON
--------------------------------------------------------------------
local WINDOW_SIZE = UDim2.new(0.86, 0, 0.84, 0)

local Window = new("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = WINDOW_SIZE, BorderSizePixel = 0, ClipsDescendants = true,
}, Gui)
bindTheme(Window, "BackgroundColor3", "Bg")
Window.BackgroundTransparency = Settings.Transparency
table.insert(panelList, Window)
round(Window, 1.4)
local winStroke = new("UIStroke", { Thickness = 1, Transparency = 0.55 }, Window)
bindTheme(winStroke, "Color", "Accent")
local uiScale = new("UIScale", { Scale = Settings.Scale }, Window)

local Glow = new("Frame", { Name = "Glow", Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 0 }, Window)
bindTheme(Glow, "BackgroundColor3", "Accent")
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 0.97), NumberSequenceKeypoint.new(1, 0.7),
    }),
}, Glow)
round(Glow, 1.4)

local TopBar = new("Frame", { Name = "TopBar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46) }, Window)
makeDraggable(TopBar, Window)

local BackBtn = new("TextButton", {
    Text = "<", Font = Enum.Font.GothamBlack, TextSize = 26, BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 3), Size = UDim2.new(0, 40, 0, 40),
}, TopBar)
bindTheme(BackBtn, "TextColor3", "Accent")

if CONFIG.LogoAsset ~= "" then
    new("ImageLabel", {
        BackgroundTransparency = 1, Image = CONFIG.LogoAsset, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 38, 0, 38),
    }, TopBar)
else
    label(TopBar, "ARCEUS X  v5", {
        size = 18, font = Enum.Font.GothamBlack, align = Enum.TextXAlignment.Center,
        anchor = Vector2.new(0.5, 0.5), pos = UDim2.new(0.5, 0, 0.5, 0), sz = UDim2.new(0, 220, 0, 30),
    })
end

local MinBtn = new("TextButton", {
    Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -52, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
}, TopBar)
bindTheme(MinBtn, "BackgroundColor3", "Accent2")
pill(MinBtn)
local CloseBtn = new("TextButton", {
    Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
}, TopBar)
bindTheme(CloseBtn, "BackgroundColor3", "Accent")
pill(CloseBtn)

local Sidebar = new("Frame", {
    Name = "Sidebar", BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 50), Size = UDim2.new(0, 54, 1, -58),
}, Window)
new("UIListLayout", {
    Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
}, Sidebar)

local Content = new("Frame", {
    Name = "Content", BackgroundTransparency = 1, Position = UDim2.new(0, 68, 0, 50), Size = UDim2.new(1, -76, 1, -58),
}, Window)

local Mini = new("TextButton", {
    Name = "Mini", Text = "AX", Visible = false, AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(0, 54, 0, 54),
    Font = Enum.Font.GothamBlack, TextSize = 18, AutoButtonColor = false, BorderSizePixel = 0,
}, Gui)
bindTheme(Mini, "BackgroundColor3", "Accent")
bindTheme(Mini, "TextColor3", "OnAccent")
pill(Mini)

local FpsLabel = new("TextLabel", {
    Name = "Fps", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.new(0, 80, 0, 22),
    BackgroundTransparency = 0.4, BorderSizePixel = 0, Font = Enum.Font.Code, TextSize = 14, Text = "-- FPS",
    Visible = Settings.ShowFps, ZIndex = 40,
}, Gui)
bindTheme(FpsLabel, "BackgroundColor3", "Bg")
bindTheme(FpsLabel, "TextColor3", "Text")
pill(FpsLabel)

local blur = new("BlurEffect", { Size = 0, Enabled = false }, Lighting)
local function applyBlur()
    blur.Enabled = Settings.Blur
    blur.Size = Settings.Blur and 16 or 0
end

local function playOpen()
    Window.Visible = true
    Window.Size = UDim2.new(WINDOW_SIZE.X.Scale * 0.8, 0, WINDOW_SIZE.Y.Scale * 0.8, 0)
    tween(Window, { Size = WINDOW_SIZE }, 0.5)
end

local minimized = false
local function setMinimized(state)
    minimized = state
    if state then
        tween(Window, { Size = UDim2.new(0, 0, 0, 0) }, 0.25)
        task.delay(0.3 / Settings.AnimSpeed, function() if minimized then Window.Visible = false end end)
        Mini.Visible = true
    else
        Mini.Visible = false
        Window.Visible = true
        Window.Size = UDim2.new(0, 0, 0, 0)
        tween(Window, { Size = WINDOW_SIZE }, 0.4)
    end
end

--------------------------------------------------------------------
-- PAGES + NAV
--------------------------------------------------------------------
local pages = {}
local navButtons = {}
local currentPage = nil
local history = {}

local function newPage(id)
    local p = new("CanvasGroup", {
        Name = id, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false,
    }, Content)
    pages[id] = p
    return p
end

local function refreshNav()
    for pid, nb in pairs(navButtons) do
        local active = pid == currentPage
        tweenFixed(nb.Text, { TextColor3 = active and Theme("Accent") or Theme("Sub") }, 0.2)
        if nb.Image then tweenFixed(nb.Image, { ImageColor3 = active and Theme("Accent") or Theme("Sub") }, 0.2) end
        tween(nb.Bar, { Size = active and UDim2.new(0, 4, 0.5, 0) or UDim2.new(0, 4, 0, 0) }, 0.25)
    end
end
table.insert(themeHooks, refreshNav)

showPage = function(id, fromBack)
    if id == currentPage or not pages[id] then return end
    if currentPage and not fromBack then
        table.insert(history, currentPage)
        if #history > 20 then table.remove(history, 1) end
    end
    local old = pages[currentPage]
    if old then old.Visible = false end
    currentPage = id
    local p = pages[id]
    p.Visible = true
    local home = UDim2.new(0.5, 0, 0.5, 0)
    if Settings.Animations then
        p.GroupTransparency = 1
        p.Size = UDim2.new(1, 0, 1, 0)
        p.Position = home
        if Settings.Transition == "Slide" then
            p.Position = UDim2.new(0.5, 40, 0.5, 0)
        elseif Settings.Transition == "Zoom" then
            p.Size = UDim2.new(0.9, 0, 0.9, 0)
        end
        tween(p, { GroupTransparency = 0, Position = home, Size = UDim2.new(1, 0, 1, 0) }, 0.35)
    else
        p.GroupTransparency = 0
        p.Position = home
        p.Size = UDim2.new(1, 0, 1, 0)
    end
    refreshNav()
end

local function goBack()
    local prev = table.remove(history)
    if prev then showPage(prev, true) else notify("Nothing to go back to", 1.2) end
end

local NAV = {
    { id = "Home", text = "HOME" },
    { id = "Code", text = "</>" },
    { id = "Hub", text = "CLOUD" },
    { id = "Arcy", text = "ARCY" },
    { id = "Game", text = "GAME" },
    { id = "Settings", text = "SET" },
}
for i, n in ipairs(NAV) do
    newPage(n.id)
    local b = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = i,
    }, Sidebar)
    local entry = {}
    local asset = CONFIG.Icons[n.id]
    entry.Text = label(b, n.text, {
        size = 12, font = Enum.Font.GothamBlack, align = Enum.TextXAlignment.Center, color = "Sub",
    })
    if asset and asset ~= "" then
        entry.Text.Visible = false
        entry.Image = new("ImageLabel", {
            BackgroundTransparency = 1, Image = asset, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 28, 0, 28),
        }, b)
    end
    entry.Bar = new("Frame", {
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -4, 0.5, 0), Size = UDim2.new(0, 4, 0, 0),
    }, b)
    bindTheme(entry.Bar, "BackgroundColor3", "Accent")
    pill(entry.Bar)
    navButtons[n.id] = entry
    b.Activated:Connect(function() showPage(n.id) end)
end

--------------------------------------------------------------------
-- COMPONENTS (settings style controls)
--------------------------------------------------------------------
local function row(parent, height)
    return new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height) }, parent)
end

local function card(parent, title)
    local c = panel(parent, UDim2.new(1, 0, 0, 0), nil, 0.7)
    c.AutomaticSize = Enum.AutomaticSize.Y
    padding(c, 14, 12, 14, 14)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, c)
    label(c, title, { size = 17, font = Enum.Font.GothamBold, sz = UDim2.new(1, 0, 0, 24) })
    return c
end

local function addToggle(parent, text, key, onChange)
    local r = row(parent, 36)
    label(r, text, { sz = UDim2.new(1, -60, 1, 0) })
    local sw = new("TextButton", {
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 46, 0, 24),
    }, r)
    pill(sw)
    local knob = new("Frame", {
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(0, 3, 0.5, 0),
    }, sw)
    pill(knob)
    local function refresh()
        local on = Settings[key] == true
        tween(sw, { BackgroundColor3 = on and Theme("Accent") or Theme("Panel2") }, 0.2)
        tween(knob, { Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.2)
    end
    sw.Activated:Connect(function()
        Settings[key] = not Settings[key]
        refresh()
        queueSave()
        if onChange then onChange(Settings[key]) end
    end)
    table.insert(refreshers, refresh)
    table.insert(themeHooks, refresh)
    refresh()
end

local function addSlider(parent, text, key, min, max, decimals, onChange)
    local r = row(parent, 46)
    label(r, text, { sz = UDim2.new(0.6, 0, 0, 20) })
    local val = label(r, "", {
        color = "Sub", align = Enum.TextXAlignment.Right, pos = UDim2.new(0.6, 0, 0, 0), sz = UDim2.new(0.4, 0, 0, 20),
    })
    local track = new("Frame", { Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 8), BorderSizePixel = 0 }, r)
    bindTheme(track, "BackgroundColor3", "Panel2")
    pill(track)
    local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0 }, track)
    bindTheme(fill, "BackgroundColor3", "Accent")
    pill(fill)
    local knob = new("Frame", {
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 2,
    }, track)
    pill(knob)
    local hit = new("TextButton", {
        Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 28),
    }, r)
    local fmt = "%." .. tostring(decimals or 0) .. "f"
    local function render(alpha)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        val.Text = string.format(fmt, Settings[key])
    end
    local function refresh()
        render(math.clamp((Settings[key] - min) / (max - min), 0, 1))
    end
    attachDrag(hit, track, function(a)
        local v = min + (max - min) * a
        local step = 10 ^ (decimals or 0)
        Settings[key] = math.floor(v * step + 0.5) / step
        render(a)
        queueSave()
        if onChange then onChange(Settings[key]) end
    end, false)
    table.insert(refreshers, refresh)
    refresh()
end

local function addChips(parent, text, key, options, onChange)
    local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, box)
    label(box, text, { sz = UDim2.new(1, 0, 0, 20) })
    local wrap = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1,
    }, box)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    }, wrap)
    local chips = {}
    local function refresh()
        for opt, c in pairs(chips) do
            local on = Settings[key] == opt
            tween(c, {
                BackgroundColor3 = on and Theme("Accent") or Theme("Panel2"),
                TextColor3 = on and Theme("OnAccent") or Theme("Text"),
            }, 0.2)
        end
    end
    for i, opt in ipairs(options) do
        local c = new("TextButton", {
            Text = opt, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 30), LayoutOrder = i,
        }, wrap)
        padding(c, 12, 0, 12, 0)
        pill(c)
        chips[opt] = c
        c.Activated:Connect(function()
            Settings[key] = opt
            refresh()
            queueSave()
            if onChange then onChange(opt) end
        end)
    end
    table.insert(refreshers, refresh)
    table.insert(themeHooks, refresh)
    refresh()
end

local function addInput(parent, text, key, placeholder, secret, onChange)
    local r = row(parent, 58)
    label(r, text, { sz = UDim2.new(1, 0, 0, 20) })
    local box = new("TextBox", {
        Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 30), BorderSizePixel = 0, ClearTextOnFocus = false,
        Text = "", PlaceholderText = placeholder or "", Font = Enum.Font.Code, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, r)
    bindTheme(box, "BackgroundColor3", "Panel2")
    bindTheme(box, "TextColor3", "Text")
    bindTheme(box, "PlaceholderColor3", "Sub")
    round(box, 0.5)
    padding(box, 10, 0, 10, 0)
    local function refresh()
        if secret then
            box.Text = (Settings[key] ~= "") and string.rep("*", 12) or ""
        else
            box.Text = tostring(Settings[key])
        end
    end
    if secret then box.Focused:Connect(function() box.Text = "" end) end
    box.FocusLost:Connect(function()
        local t = box.Text:match("^%s*(.-)%s*$")
        if secret and t == "" then refresh() return end
        Settings[key] = t
        refresh()
        queueSave()
        if onChange then onChange(t) end
    end)
    table.insert(refreshers, refresh)
    refresh()
end

--------------------------------------------------------------------
-- DATA: SCRIPT LIBRARY + TIPS
--------------------------------------------------------------------
local LIBRARY = {
    {
        name = "Rotate 45", tag = "Character",
        code = [==[local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(45), 0)]==],
    },
    {
        name = "FPS Counter", tag = "Utility",
        code = [==[local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local gui = Instance.new("ScreenGui")
gui.Name = "FpsCounterDemo"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local text = Instance.new("TextLabel")
text.Size = UDim2.new(0, 120, 0, 30)
text.Position = UDim2.new(1, -130, 0, 10)
text.BackgroundTransparency = 0.4
text.TextColor3 = Color3.new(1, 1, 1)
text.Font = Enum.Font.Code
text.TextSize = 18
text.Parent = gui
local frames, last = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = os.clock()
    if now - last >= 0.5 then
        text.Text = math.floor(frames / (now - last)) .. " FPS"
        frames, last = 0, now
    end
end)]==],
    },
    {
        name = "Wait And Print", tag = "Basics",
        code = [==[local Time = 2

task.wait(Time)
print("Waited " .. Time .. " seconds")]==],
    },
    {
        name = "Part Spawner", tag = "Building",
        code = [==[local Players = game:GetService("Players")
local character = Players.LocalPlayer.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
if root then
    local part = Instance.new("Part")
    part.Size = Vector3.new(4, 1, 4)
    part.Anchored = true
    part.Color = Color3.fromRGB(200, 30, 50)
    part.CFrame = root.CFrame * CFrame.new(0, 0, -8)
    part.Parent = workspace
end]==],
    },
    {
        name = "Server Info", tag = "Utility",
        code = [==[local Players = game:GetService("Players")
print("PlaceId:", game.PlaceId)
print("JobId:", game.JobId)
print("Players:", #Players:GetPlayers())]==],
    },
    {
        name = "Field Of View", tag = "Camera",
        code = [==[local camera = workspace.CurrentCamera
camera.FieldOfView = 90
print("FOV set to", camera.FieldOfView)]==],
    },
}

local TIPS = {
    { "Move the window", "Drag the top bar to move the whole window around your screen." },
    { "Change the animations", "Open Settings to pick the animation style, speed, and page transition." },
    { "Star your scripts", "Starred files jump to the top of your Files list." },
    { "Ask Arcy for scripts", "Add your API key in Settings, then ask Arcy to write a script for you." },
    { "Minimize it", "The blue dot in the top right shrinks the UI into a small AX button." },
    { "Console", "The console button in the Code tab shows prints, warnings, and errors." },
}

--------------------------------------------------------------------
-- PLAYER STATE (gravity / jump / speed)
--------------------------------------------------------------------
local State = { Gravity = workspace.Gravity, Jump = 50, Speed = 16, Dirty = {} }

local function getHumanoid()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

do
    local h = getHumanoid()
    if h then
        State.Speed = h.WalkSpeed
        State.Jump = h.JumpPower
    end
end

local function applyState(key)
    if key == "Gravity" then
        workspace.Gravity = State.Gravity
        return
    end
    local h = getHumanoid()
    if not h then return end
    if key == "Speed" then
        h.WalkSpeed = State.Speed
    elseif key == "Jump" then
        h.UseJumpPower = true
        h.JumpPower = State.Jump
    end
end

connect(LocalPlayer.CharacterAdded, function(ch)
    local h = ch:WaitForChild("Humanoid", 10)
    if h then
        for k in pairs(State.Dirty) do applyState(k) end
    end
end)

--------------------------------------------------------------------
-- FILES + EDITOR LOGIC
--------------------------------------------------------------------
local selectedFile = Files[1]
local editorBox, fileList, fileSearch

local function uniqueName(base)
    local taken = {}
    for _, f in ipairs(Files) do taken[f.name] = true end
    if not taken[base] then return base end
    local n = 2
    while taken[base .. " (" .. n .. ")"] do n = n + 1 end
    return base .. " (" .. n .. ")"
end

commitEditor = function()
    if selectedFile and editorBox then
        selectedFile.code = editorBox.Text
        queueSave()
    end
end

local function renderFiles()
    if not fileList then return end
    for _, c in ipairs(fileList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local q = ((fileSearch and fileSearch.Text) or ""):lower()
    local view = {}
    for i, f in ipairs(Files) do
        if q == "" or f.name:lower():find(q, 1, true) then table.insert(view, { f = f, i = i }) end
    end
    table.sort(view, function(a, b)
        local sa = a.f.starred and 1 or 0
        local sb = b.f.starred and 1 or 0
        if sa ~= sb then return sa > sb end
        return a.i < b.i
    end)
    for order, v in ipairs(view) do
        local f = v.f
        local sel = (f == selectedFile)
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 34), Text = (f.starred and "* " or "") .. f.name,
            Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order,
            BackgroundColor3 = sel and Theme("Accent") or Theme("Panel2"),
            TextColor3 = sel and Theme("OnAccent") or Theme("Text"),
        }, fileList)
        padding(b, 12, 0, 8, 0)
        round(b, 0.5)
        b.Activated:Connect(function()
            commitEditor()
            selectedFile = f
            if editorBox then editorBox.Text = f.code end
            renderFiles()
        end)
    end
end
table.insert(themeHooks, renderFiles)

local function selectFile(f)
    commitEditor()
    selectedFile = f
    if editorBox then editorBox.Text = f.code end
    renderFiles()
end

loadIntoEditor = function(entry)
    commitEditor()
    local f = { name = uniqueName(entry.name), code = entry.code, starred = false }
    table.insert(Files, f)
    selectFile(f)
    queueSave()
    showPage("Code")
    notify("Loaded " .. f.name)
end

local function runCode(src)
    if not src or src:gsub("%s", "") == "" then
        notify("Nothing to run", 1.5)
        return
    end
    if type(loadstring) ~= "function" then
        logLine("loadstring is not available in this environment", "err")
        notify("loadstring unavailable here", 2.5)
        return
    end
    local fn, err = loadstring(src)
    if not fn then
        logLine(tostring(err), "err")
        notify("Syntax error - check Console", 2.5)
        return
    end
    notify("Executed", 1.2)
    task.spawn(function()
        local ok, e = pcall(fn)
        if not ok then logLine(tostring(e), "err") end
    end)
end

local function setClipboard(text)
    local f = setclipboard or toclipboard
    if type(f) == "function" then
        local ok = pcall(f, text)
        return ok
    end
    return false
end

--------------------------------------------------------------------
-- LIBRARY CARDS
--------------------------------------------------------------------
local function refreshStars()
    for i = #starRefreshers, 1, -1 do
        local e = starRefreshers[i]
        if e.inst:IsDescendantOf(Gui) then e.fn() else table.remove(starRefreshers, i) end
    end
end
table.insert(themeHooks, refreshStars)

local function libraryCard(parent, entry, size)
    local c = panel(parent, size, nil, 0.7, "Panel2")
    c.Name = "Card"
    local name = label(c, entry.name, {
        size = 15, font = Enum.Font.GothamBold, pos = UDim2.new(0, 10, 0, 8), sz = UDim2.new(1, -44, 0, 22),
    })
    name.TextTruncate = Enum.TextTruncate.AtEnd
    label(c, entry.tag, { size = 12, color = "Sub", pos = UDim2.new(0, 10, 0, 30), sz = UDim2.new(1, -20, 0, 18) })
    label(c, "Tap to load into editor", {
        size = 11, color = "Sub", anchor = Vector2.new(0, 1), pos = UDim2.new(0, 10, 1, -8), sz = UDim2.new(1, -20, 0, 16),
    })
    local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 2 }, c)
    local star = new("TextButton", {
        Text = "*", Font = Enum.Font.GothamBlack, TextSize = 26, BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.new(0, 30, 0, 32), ZIndex = 3,
    }, c)
    local function refreshStar()
        star.TextColor3 = Settings.Starred[entry.name] and Color3.fromRGB(255, 200, 60) or Theme("Sub")
    end
    table.insert(starRefreshers, { inst = c, fn = refreshStar })
    refreshStar()
    hit.Activated:Connect(function() loadIntoEditor(entry) end)
    star.Activated:Connect(function()
        Settings.Starred[entry.name] = (not Settings.Starred[entry.name]) or nil
        refreshStars()
        queueSave()
        if renderHub then task.defer(renderHub) end
    end)
    return c
end

--------------------------------------------------------------------
-- HOME PAGE
--------------------------------------------------------------------
local function typewrite(lbl, text, per)
    task.spawn(function()
        for i = 1, #text do
            if not alive or not lbl.Parent then return end
            lbl.Text = text:sub(1, i)
            task.wait(per or 0.04)
        end
    end)
end

local function addVSlider(parent, xScale, name, glyph, key, min, max)
    local holder = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(xScale, 0, 0, 12), Size = UDim2.new(0.28, 0, 1, -24),
    }, parent)
    local track = new("Frame", { Size = UDim2.new(1, 0, 1, -28), BorderSizePixel = 0, ClipsDescendants = true }, holder)
    bindTheme(track, "BackgroundColor3", "Panel2")
    round(track, 1.2)
    local fill = new("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 0), BorderSizePixel = 0,
    }, track)
    bindTheme(fill, "BackgroundColor3", "Accent")
    local pct = label(track, "0%", {
        size = 13, font = Enum.Font.GothamBold, align = Enum.TextXAlignment.Center,
        pos = UDim2.new(0, 0, 0, 6), sz = UDim2.new(1, 0, 0, 22),
    })
    pct.ZIndex = 3
    local g = label(track, glyph, {
        size = 26, font = Enum.Font.GothamBlack, align = Enum.TextXAlignment.Center,
        pos = UDim2.new(0, 0, 1, -46), sz = UDim2.new(1, 0, 0, 40),
    })
    g.ZIndex = 3
    label(holder, name, {
        size = 13, color = "Sub", align = Enum.TextXAlignment.Center,
        anchor = Vector2.new(0, 1), pos = UDim2.new(0, 0, 1, 0), sz = UDim2.new(1, 0, 0, 22),
    })
    local function render(alpha)
        fill.Size = UDim2.new(1, 0, alpha, 0)
        pct.Text = string.format("%d%%", math.floor(alpha * 100 + 0.5))
    end
    render(math.clamp((State[key] - min) / (max - min), 0, 1))
    attachDrag(track, track, function(a)
        State[key] = min + (max - min) * a
        State.Dirty[key] = true
        applyState(key)
        render(a)
    end, true)
end

local function buildHome()
    local page = pages.Home

    local welcome = panel(page, UDim2.new(0.48, 0, 0.22, 0), UDim2.new(0, 0, 0, 0), 0.8)
    local avatar = new("ImageLabel", {
        BackgroundTransparency = 0, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.new(0, 46, 0, 46), Image = "",
    }, welcome)
    bindTheme(avatar, "BackgroundColor3", "Panel2")
    pill(avatar)
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and avatar.Parent then avatar.Image = img end
    end)
    label(welcome, "Welcome", { size = 13, color = "Sub", pos = UDim2.new(0, 70, 0.5, -22), sz = UDim2.new(1, -80, 0, 18) })
    local nm = label(welcome, LocalPlayer.DisplayName, {
        size = 22, font = Enum.Font.GothamBlack, pos = UDim2.new(0, 70, 0.5, -2), sz = UDim2.new(1, -80, 0, 28),
    })
    nm.TextTruncate = Enum.TextTruncate.AtEnd

    local hub = panel(page, UDim2.new(0.18, 0, 0.22, 0), UDim2.new(0.5, 0, 0, 0), 0.8)
    label(hub, "AX", {
        size = 22, font = Enum.Font.GothamBlack, color = "Accent", align = Enum.TextXAlignment.Center,
        pos = UDim2.new(0, 0, 0, 4), sz = UDim2.new(1, 0, 0.55, 0),
    })
    label(hub, "Arceus Hub", {
        size = 13, font = Enum.Font.GothamBold, align = Enum.TextXAlignment.Center,
        anchor = Vector2.new(0, 1), pos = UDim2.new(0, 0, 1, -6), sz = UDim2.new(1, 0, 0, 20),
    })
    new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, hub).Activated:Connect(function()
        showPage("Hub")
    end)

    local best = panel(page, UDim2.new(0.68, 0, 0.43, 0), UDim2.new(0, 0, 0.25, 0), 0.8)
    label(best, "Best Scripts", {
        size = 14, font = Enum.Font.GothamBold, align = Enum.TextXAlignment.Center, sz = UDim2.new(1, 0, 0, 28),
    })
    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 28), Size = UDim2.new(1, -16, 1, -36),
        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
    }, best)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, scroll)
    for _, entry in ipairs(LIBRARY) do libraryCard(scroll, entry, UDim2.new(0, 170, 1, -8)) end

    local banner = panel(page, UDim2.new(0.68, 0, 0.29, 0), UDim2.new(0, 0, 0.71, 0), 0.9, "Accent")
    new("UIGradient", {
        Rotation = 0,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.6) }),
    }, banner)
    local face = new("TextLabel", {
        Text = "A", Font = Enum.Font.GothamBlack, TextSize = 24, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.new(0, 48, 0, 48),
    }, banner)
    bindTheme(face, "BackgroundColor3", "Bg")
    bindTheme(face, "TextColor3", "Accent")
    pill(face)
    label(banner, "Let's talk", { size = 12, pos = UDim2.new(0, 82, 0.5, -26), sz = UDim2.new(1, -100, 0, 18) }).TextColor3 = Color3.fromRGB(255, 255, 255)
    local greet = label(banner, "", { size = 22, pos = UDim2.new(0, 82, 0.5, -6), sz = UDim2.new(1, -100, 0, 30) })
    greet.TextColor3 = Color3.fromRGB(255, 255, 255)
    typewrite(greet, "Hello! I'm Arcy!", 0.05)
    new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 5 }, banner).Activated:Connect(function()
        showPage("Arcy")
    end)

    local sliders = panel(page, UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), 0.9)
    addVSlider(sliders, 0.04, "Gravity", "G", "Gravity", 0, 250)
    addVSlider(sliders, 0.36, "Jump", "J", "Jump", 0, 500)
    addVSlider(sliders, 0.68, "Speed", "S", "Speed", 0, 500)
end

--------------------------------------------------------------------
-- CODE (EDITOR) PAGE
--------------------------------------------------------------------
local function buildEditor()
    local page = pages.Code
    local codePanel = panel(page, UDim2.new(0.68, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0.9)

    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 1, -64),
        ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.XY,
        ScrollingDirection = Enum.ScrollingDirection.XY,
    }, codePanel)
    local lineNums = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(0, 34, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Code, TextSize = 14, LineHeight = 1, TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Top, Text = "1",
    }, scroll)
    bindTheme(lineNums, "TextColor3", "Sub")
    editorBox = new("TextBox", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -42, 1, 0),
        AutomaticSize = Enum.AutomaticSize.XY, MultiLine = true, ClearTextOnFocus = false, TextWrapped = false,
        Font = Enum.Font.Code, TextSize = 14, LineHeight = 1, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Text = "", PlaceholderText = "-- write your script here",
    }, scroll)
    bindTheme(editorBox, "TextColor3", "Text")
    bindTheme(editorBox, "PlaceholderColor3", "Sub")

    local function updateLines()
        local n = 1
        for _ in string.gmatch(editorBox.Text, "\n") do n = n + 1 end
        local parts = {}
        for i = 1, n do parts[i] = tostring(i) end
        lineNums.Text = table.concat(parts, "\n")
    end
    editorBox:GetPropertyChangedSignal("Text"):Connect(updateLines)
    editorBox.FocusLost:Connect(commitEditor)
    editorBox.Text = selectedFile.code
    updateLines()

    -- console overlay
    local consoleFrame = panel(codePanel, UDim2.new(1, -16, 0.5, -30), UDim2.new(0, 8, 0.5, -4), 0.6, "Panel2")
    consoleFrame.Visible = false
    consoleFrame.ZIndex = 6
    label(consoleFrame, "Console", { size = 13, font = Enum.Font.GothamBold, pos = UDim2.new(0, 10, 0, 4), sz = UDim2.new(0.5, 0, 0, 22) })
    local clearLog = button(consoleFrame, "Clear", UDim2.new(0, 60, 0, 22), UDim2.new(1, -66, 0, 4), function()
        for _, l in ipairs(logLabels) do l:Destroy() end
        logLabels = {}
    end)
    clearLog.TextSize = 12
    consoleScroll = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 30), Size = UDim2.new(1, -16, 1, -36),
        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, consoleFrame)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, consoleScroll)
    for _, d in ipairs(consoleFrame:GetDescendants()) do
        if d:IsA("GuiObject") then d.ZIndex = 6 end
    end

    -- floating buttons
    local saveBtn = button(codePanel, "SV", UDim2.new(0, 38, 0, 38), UDim2.new(1, -50, 0, 10), function()
        commitEditor()
        saveFilesNow()
        saveSettingsNow()
        notify("Saved")
    end)
    pill(saveBtn)
    saveBtn.ZIndex = 5
    local consoleBtn = button(codePanel, ">_", UDim2.new(0, 38, 0, 38), UDim2.new(1, -50, 0, 54), function()
        consoleFrame.Visible = not consoleFrame.Visible
    end, true)
    pill(consoleBtn)
    consoleBtn.ZIndex = 5

    -- bottom bar
    local bar = new("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -8), Size = UDim2.new(1, -16, 0, 40),
    }, codePanel)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8),
    }, bar)
    button(bar, "Clear", UDim2.new(0, 64, 0, 38), nil, function() editorBox.Text = "" end)
    button(bar, "Copy", UDim2.new(0, 64, 0, 38), nil, function()
        if setClipboard(editorBox.Text) then notify("Copied") else notify("Clipboard not available here", 2) end
    end)
    button(bar, "Paste", UDim2.new(0, 64, 0, 38), nil, function()
        local f = getclipboard or fromclipboard
        if type(f) == "function" then
            local ok, t = pcall(f)
            if ok and type(t) == "string" then editorBox.Text = editorBox.Text .. t return end
        end
        notify("Paste: long-press inside the editor", 2.2)
    end)
    button(bar, "Execute", UDim2.new(0, 96, 0, 38), nil, function() runCode(editorBox.Text) end, true)

    -- files panel
    local filesPanel = panel(page, UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), 0.9)
    label(filesPanel, "Files", { size = 22, font = Enum.Font.GothamBold, pos = UDim2.new(0, 14, 0, 8), sz = UDim2.new(1, -28, 0, 30) })
    fileSearch = new("TextBox", {
        Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 0, 28), BorderSizePixel = 0, ClearTextOnFocus = false,
        Text = "", PlaceholderText = "Search scripts...", Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, filesPanel)
    bindTheme(fileSearch, "BackgroundColor3", "Panel2")
    bindTheme(fileSearch, "TextColor3", "Text")
    bindTheme(fileSearch, "PlaceholderColor3", "Sub")
    round(fileSearch, 0.5)
    padding(fileSearch, 10, 0, 10, 0)
    fileSearch:GetPropertyChangedSignal("Text"):Connect(renderFiles)

    button(filesPanel, "+", UDim2.new(0.27, 0, 0, 32), UDim2.new(0.05, 0, 0, 78), function()
        commitEditor()
        local f = { name = uniqueName("Script n." .. (#Files + 1)), code = "", starred = false }
        table.insert(Files, f)
        selectFile(f)
        queueSave()
    end)
    button(filesPanel, "*", UDim2.new(0.27, 0, 0, 32), UDim2.new(0.365, 0, 0, 78), function()
        if selectedFile then
            selectedFile.starred = not selectedFile.starred
            renderFiles()
            queueSave()
        end
    end)
    local pendingDelete = 0
    button(filesPanel, "Del", UDim2.new(0.27, 0, 0, 32), UDim2.new(0.68, 0, 0, 78), function()
        if not selectedFile then return end
        if os.clock() - pendingDelete > 3 then
            pendingDelete = os.clock()
            notify("Tap Del again to delete " .. selectedFile.name, 2.5)
            return
        end
        pendingDelete = 0
        for i, f in ipairs(Files) do
            if f == selectedFile then table.remove(Files, i) break end
        end
        if #Files == 0 then table.insert(Files, { name = "Script n.1", code = "", starred = false }) end
        selectedFile = nil
        selectFile(Files[1])
        queueSave()
    end)

    fileList = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, 118), Size = UDim2.new(1, -20, 1, -128),
        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, filesPanel)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, fileList)
    renderFiles()
end

--------------------------------------------------------------------
-- HUB PAGE
--------------------------------------------------------------------
local function buildHub()
    local page = pages.Hub
    local top = panel(page, UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), 0.7)
    label(top, "Script Hub", { size = 17, font = Enum.Font.GothamBold, pos = UDim2.new(0, 14, 0, 0), sz = UDim2.new(0.4, 0, 1, 0) })
    local search = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.5, 0, 0, 28),
        BorderSizePixel = 0, ClearTextOnFocus = false, Text = "", PlaceholderText = "Search the hub...",
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, top)
    bindTheme(search, "BackgroundColor3", "Panel2")
    bindTheme(search, "TextColor3", "Text")
    bindTheme(search, "PlaceholderColor3", "Sub")
    round(search, 0.5)
    padding(search, 10, 0, 10, 0)

    local grid = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52),
        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, page)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.32, 0, 0, 96), CellPadding = UDim2.new(0.01, 0, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    renderHub = function()
        if not grid.Parent then return end
        for _, c in ipairs(grid:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local q = search.Text:lower()
        local view = {}
        for i, e in ipairs(LIBRARY) do
            if q == "" or e.name:lower():find(q, 1, true) or e.tag:lower():find(q, 1, true) then
                table.insert(view, { e = e, i = i })
            end
        end
        table.sort(view, function(a, b)
            local sa = Settings.Starred[a.e.name] and 1 or 0
            local sb = Settings.Starred[b.e.name] and 1 or 0
            if sa ~= sb then return sa > sb end
            return a.i < b.i
        end)
        for order, v in ipairs(view) do
            local c = libraryCard(grid, v.e, UDim2.new(0, 100, 0, 96))
            c.LayoutOrder = order
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(renderHub)
    renderHub()
end

--------------------------------------------------------------------
-- ARCY PAGE (tips, music, AI chat)
--------------------------------------------------------------------
local Music = new("Sound", { Name = "ArceusV5Music", Looped = true, Volume = 0.6 }, SoundService)
local function applyMusicId()
    local id = Settings.MusicId
    if id ~= "" then
        Music.SoundId = id:find("rbxassetid") and id or ("rbxassetid://" .. id)
    else
        Music.SoundId = ""
    end
end

local function formatTime(sec)
    sec = math.max(0, sec or 0)
    return string.format("%02d:%02d", math.floor(sec / 60), math.floor(sec % 60))
end

local function httpRequest(opts)
    local fn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if fn then
        local ok, res = pcall(fn, opts)
        if ok then return res end
        return nil, res
    end
    local ok, res = pcall(function()
        return HttpService:RequestAsync({ Url = opts.Url, Method = opts.Method, Headers = opts.Headers, Body = opts.Body })
    end)
    if ok then return { StatusCode = res.StatusCode, Body = res.Body } end
    return nil, res
end

local chatHistory = {}

local function askAI()
    local key = Settings.ApiKey
    if key == "" then return nil, "No API key yet. Add it in Settings > Arcy AI." end
    local msgs = { { role = "system", content = CONFIG.SystemPrompt } }
    for _, m in ipairs(chatHistory) do table.insert(msgs, m) end
    local body = HttpService:JSONEncode({ model = Settings.Model, messages = msgs, max_tokens = 1200 })
    local res, herr = httpRequest({
        Url = Settings.Endpoint, Method = "POST",
        Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. key },
        Body = body,
    })
    if not res then return nil, tostring(herr or "request failed") end
    local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not ok or type(data) ~= "table" then return nil, "Bad response (status " .. tostring(res.StatusCode) .. ")" end
    if data.error then
        return nil, tostring(type(data.error) == "table" and data.error.message or data.error)
    end
    local msg = data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content
    if msg then return msg end
    return nil, "Unexpected response shape (status " .. tostring(res.StatusCode) .. ")"
end

local function buildArcy()
    local page = pages.Arcy

    -- tips card
    local tips = panel(page, UDim2.new(0.5, 0, 0.55, 0), UDim2.new(0, 0, 0, 0), 0.9)
    label(tips, "ARCY TIPS", { size = 12, color = "Sub", pos = UDim2.new(0, 16, 0, 10), sz = UDim2.new(1, -32, 0, 16) })
    local tipTitle = label(tips, TIPS[1][1], { size = 18, font = Enum.Font.GothamBold, pos = UDim2.new(0, 16, 0, 30), sz = UDim2.new(1, -32, 0, 26) })
    local tipBody = label(tips, TIPS[1][2], {
        size = 15, color = "Sub", wrap = true, yalign = Enum.TextYAlignment.Top, pos = UDim2.new(0, 16, 0, 62), sz = UDim2.new(1, -32, 1, -120),
    })
    local tipIndex = 1
    local function nextTip()
        tipIndex = tipIndex % #TIPS + 1
        task.spawn(function()
            tweenFixed(tipBody, { TextTransparency = 1 }, 0.15)
            tweenFixed(tipTitle, { TextTransparency = 1 }, 0.15)
            task.wait(0.18)
            if not alive then return end
            tipTitle.Text = TIPS[tipIndex][1]
            tipBody.Text = TIPS[tipIndex][2]
            tweenFixed(tipBody, { TextTransparency = 0 }, 0.2)
            tweenFixed(tipTitle, { TextTransparency = 0 }, 0.2)
        end)
    end
    button(tips, "Next tip", UDim2.new(1, -32, 0, 34), UDim2.new(0, 16, 1, -46), nextTip, true)
    task.spawn(function()
        while alive do
            task.wait(9)
            if alive and pages.Arcy.Visible then nextTip() end
        end
    end)

    -- music card
    local music = panel(page, UDim2.new(0.5, 0, 0.42, 0), UDim2.new(0, 0, 0.58, 0), 0.9)
    local playBtn = button(music, "Play", UDim2.new(0, 56, 0, 56), UDim2.new(0, 14, 0.5, -28), nil, true)
    pill(playBtn)
    local songName = label(music, "No song set (Settings > Audio)", {
        size = 15, font = Enum.Font.GothamBold, pos = UDim2.new(0, 84, 0, 12), sz = UDim2.new(1, -96, 0, 24),
    })
    songName.TextTruncate = Enum.TextTruncate.AtEnd
    local timeLbl = label(music, "00:00 / 00:00", {
        size = 12, color = "Sub", align = Enum.TextXAlignment.Right, anchor = Vector2.new(1, 1), pos = UDim2.new(1, -14, 1, -22), sz = UDim2.new(0, 120, 0, 16),
    })
    local bar = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 84, 1, -14), Size = UDim2.new(1, -98, 0, 4), BorderSizePixel = 0 }, music)
    bindTheme(bar, "BackgroundColor3", "Panel2")
    pill(bar)
    local barFill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0 }, bar)
    bindTheme(barFill, "BackgroundColor3", "Accent")
    pill(barFill)
    playBtn.Activated:Connect(function()
        if Music.SoundId == "" then notify("Set a Sound ID in Settings > Audio", 2.4) return end
        if Music.IsPlaying then Music:Pause() else Music:Play() end
    end)
    table.insert(heartbeatHooks, function()
        if not pages.Arcy.Visible then return end
        playBtn.Text = Music.IsPlaying and "||" or "Play"
        if Music.SoundId ~= "" then
            songName.Text = "Sound " .. Settings.MusicId
            local len = Music.TimeLength
            timeLbl.Text = formatTime(Music.TimePosition) .. " / " .. formatTime(len)
            barFill.Size = UDim2.new(len > 0 and math.clamp(Music.TimePosition / len, 0, 1) or 0, 0, 1, 0)
        else
            songName.Text = "No song set (Settings > Audio)"
        end
    end)

    -- chat panel
    local chat = panel(page, UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), 0.9)
    label(chat, "Hello! I'm Arcy!", {
        size = 15, font = Enum.Font.GothamBold, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 0, 0, 8), sz = UDim2.new(1, 0, 0, 22),
    })
    local msgs = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, 36), Size = UDim2.new(1, -20, 1, -90),
        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, chat)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, msgs)
    local order = 0

    local function scrollDown()
        task.defer(function()
            if msgs.Parent then msgs.CanvasPosition = Vector2.new(0, msgs.AbsoluteCanvasSize.Y) end
        end)
    end

    local function addBubble(text, isUser)
        order = order + 1
        local holder = new("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order,
        }, msgs)
        new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
        local b = new("TextLabel", {
            Text = text, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(0.88, 0, 0, 0),
            Font = Enum.Font.GothamMedium, TextSize = 13, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 1,
        }, holder)
        bindTheme(b, "BackgroundColor3", isUser and "Accent" or "Panel2")
        bindTheme(b, "TextColor3", isUser and "OnAccent" or "Text")
        padding(b, 10, 8, 10, 8)
        round(b, 0.5)
        if isUser then
            b.Position = UDim2.new(0.12, 0, 0, 0)
        end
        scrollDown()
        return b, holder
    end

    local function attachCodeActions(holder, reply)
        local code = reply:match("```%a*\n(.-)```")
        if not code then return end
        local r = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2 }, holder)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, r)
        button(r, "Open in editor", UDim2.new(0, 110, 0, 28), nil, function()
            loadIntoEditor({ name = "Arcy script", code = code })
        end, true).TextSize = 12
        button(r, "Copy code", UDim2.new(0, 90, 0, 28), nil, function()
            if setClipboard(code) then notify("Copied") else notify("Clipboard not available here", 2) end
        end).TextSize = 12
        scrollDown()
    end

    local input = new("TextBox", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -84, 0, 34), BorderSizePixel = 0,
        ClearTextOnFocus = false, Text = "", PlaceholderText = "Teach me how to...", Font = Enum.Font.GothamMedium,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, chat)
    bindTheme(input, "BackgroundColor3", "Panel2")
    bindTheme(input, "TextColor3", "Text")
    bindTheme(input, "PlaceholderColor3", "Sub")
    pill(input)
    padding(input, 14, 0, 14, 0)

    local busy = false
    local function send()
        if busy then return end
        local text = input.Text:match("^%s*(.-)%s*$")
        if text == "" then return end
        input.Text = ""
        addBubble(text, true)
        table.insert(chatHistory, { role = "user", content = text })
        while #chatHistory > 12 do table.remove(chatHistory, 1) end
        busy = true
        local thinking, holder = addBubble("Thinking...", false)
        task.spawn(function()
            local reply, err = askAI()
            busy = false
            if not alive or not thinking.Parent then return end
            if reply then
                thinking.Text = reply
                table.insert(chatHistory, { role = "assistant", content = reply })
                attachCodeActions(holder, reply)
            else
                thinking.Text = "Error: " .. tostring(err)
            end
            scrollDown()
        end)
    end
    local sendBtn = button(chat, "Send", UDim2.new(0, 62, 0, 34), UDim2.new(1, -72, 1, -44), send, true)
    pill(sendBtn)
    input.FocusLost:Connect(function(enter) if enter then send() end end)
end

--------------------------------------------------------------------
-- GAME PAGE (utilities + web search link)
--------------------------------------------------------------------
local function buildGame()
    local page = pages.Game
    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, page)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

    local util = card(scroll, "Utilities")
    addToggle(util, "Show FPS counter", "ShowFps", function(v) FpsLabel.Visible = v end)
    local r1 = row(util, 36)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, r1)
    button(r1, "Reset character", UDim2.new(0, 140, 0, 34), nil, function()
        local h = getHumanoid()
        if h then h.Health = 0 end
    end)
    button(r1, "Rejoin", UDim2.new(0, 90, 0, 34), nil, function()
        notify("Rejoining...", 1.5)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)

    local web = card(scroll, "Image search (Google)")
    label(web, "Builds a Google Images link and copies it so you can paste it in your browser.", {
        size = 12, color = "Sub", wrap = true, sz = UDim2.new(1, 0, 0, 32), yalign = Enum.TextYAlignment.Top,
    })
    local q = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0, ClearTextOnFocus = false, Text = "",
        PlaceholderText = "Search images...", Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, web)
    bindTheme(q, "BackgroundColor3", "Panel2")
    bindTheme(q, "TextColor3", "Text")
    bindTheme(q, "PlaceholderColor3", "Sub")
    round(q, 0.5)
    padding(q, 10, 0, 10, 0)
    local function searchImages(text)
        text = text:match("^%s*(.-)%s*$")
        if text == "" then notify("Type something to search", 1.5) return end
        local url = "https://www.google.com/search?tbm=isch&q=" .. HttpService:UrlEncode(text)
        if setClipboard(url) then
            notify("Link copied - paste it in your browser", 2.4)
        else
            logLine(url)
            notify("No clipboard here - link is in the Console", 2.6)
        end
    end
    local r2 = row(web, 36)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, r2)
    button(r2, "Search", UDim2.new(0, 90, 0, 34), nil, function() searchImages(q.Text) end, true)
    button(r2, "Arceus X v5 reference", UDim2.new(0, 170, 0, 34), nil, function() searchImages("Arceus X v5 UI") end)
end

--------------------------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------------------------
local function applyAll()
    uiScale.Scale = Settings.Scale
    applyTheme()
    applyTransparency()
    applyCorners()
    applyBlur()
    applyMusicId()
    FpsLabel.Visible = Settings.ShowFps
end

local function buildSettings()
    local page = pages.Settings
    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, page)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

    local look = card(scroll, "Appearance")
    addChips(look, "Theme", "Theme", THEME_NAMES, function() applyTheme() end)
    addSlider(look, "UI scale", "Scale", 0.7, 1.15, 2, function(v) uiScale.Scale = v end)
    addSlider(look, "Transparency", "Transparency", 0, 0.8, 2, function() applyTransparency() end)
    addSlider(look, "Corner roundness", "Corner", 0, 28, 0, function() applyCorners() end)
    addToggle(look, "Background blur", "Blur", function() applyBlur() end)

    local anim = card(scroll, "Animations")
    addToggle(anim, "Enable animations", "Animations", nil)
    addChips(anim, "Animation style", "AnimStyle", ANIM_STYLES, function() playOpen() end)
    addChips(anim, "Page transition", "Transition", TRANSITIONS, nil)
    addSlider(anim, "Animation speed", "AnimSpeed", 0.25, 3, 2, nil)
    local pr = row(anim, 36)
    button(pr, "Preview animation", UDim2.new(0, 170, 0, 34), nil, function() playOpen() end, true)

    local ai = card(scroll, "Arcy AI")
    label(ai, "Your key stays on this device only. It is never written into this script.", {
        size = 12, color = "Sub", wrap = true, sz = UDim2.new(1, 0, 0, 32), yalign = Enum.TextYAlignment.Top,
    })
    addInput(ai, "API key", "ApiKey", "paste your key here", true, nil)
    addInput(ai, "Endpoint (OpenAI-compatible)", "Endpoint", "https://...", false, nil)
    addInput(ai, "Model", "Model", "model name", false, nil)
    local kr = row(ai, 36)
    button(kr, "Clear API key", UDim2.new(0, 140, 0, 34), nil, function()
        Settings.ApiKey = ""
        for _, f in ipairs(refreshers) do pcall(f) end
        queueSave()
        notify("API key cleared")
    end)

    local audio = card(scroll, "Audio")
    addInput(audio, "Music Sound ID", "MusicId", "rbxassetid number", false, function()
        Music:Stop()
        applyMusicId()
    end)

    local misc = card(scroll, "Settings data")
    local mr = row(misc, 36)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, mr)
    button(mr, "Save", UDim2.new(0, 80, 0, 34), nil, function()
        commitEditor()
        saveSettingsNow()
        saveFilesNow()
        notify("Settings saved")
    end, true)
    button(mr, "Reset", UDim2.new(0, 80, 0, 34), nil, function()
        local fresh = copyTable(DEFAULTS)
        fresh.ApiKey = Settings.ApiKey
        fresh.Endpoint = Settings.Endpoint
        fresh.Model = Settings.Model
        fresh.MusicId = Settings.MusicId
        fresh.Starred = Settings.Starred
        for k, v in pairs(fresh) do Settings[k] = v end
        applyAll()
        for _, f in ipairs(refreshers) do pcall(f) end
        queueSave()
        notify("Appearance reset")
    end)
    button(mr, "Destroy UI", UDim2.new(0, 110, 0, 34), nil, function() destroyUI() end)
    label(misc, CONFIG.Name .. "  v" .. CONFIG.Version, { size = 11, color = "Sub", sz = UDim2.new(1, 0, 0, 16) })
end

--------------------------------------------------------------------
-- WIRING + STARTUP
--------------------------------------------------------------------
destroyUI = function()
    if not alive then return end
    pcall(commitEditor)
    pcall(saveSettingsNow)
    pcall(saveFilesNow)
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() Music:Destroy() end)
    pcall(function() blur:Destroy() end)
    pcall(function() Gui:Destroy() end)
    if type(getgenv) == "function" then
        pcall(function() getgenv().ArceusV5UI = nil end)
    end
end

BackBtn.Activated:Connect(goBack)
MinBtn.Activated:Connect(function() setMinimized(true) end)
CloseBtn.Activated:Connect(function() destroyUI() end)
Mini.Activated:Connect(function() setMinimized(false) end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Gui.Enabled = not Gui.Enabled end
end)

do
    local acc, frames = 0, 0
    connect(RunService.Heartbeat, function(dt)
        acc = acc + dt
        frames = frames + 1
        if acc >= 0.5 then
            if FpsLabel.Visible then FpsLabel.Text = string.format("%d FPS", math.floor(frames / acc + 0.5)) end
            acc, frames = 0, 0
        end
        for _, h in ipairs(heartbeatHooks) do h(dt) end
    end)
end

buildHome()
buildEditor()
buildHub()
buildArcy()
buildGame()
buildSettings()
applyAll()

if type(getgenv) == "function" then
    pcall(function() getgenv().ArceusV5UI = { Destroy = destroyUI } end)
end

showPage("Home")
playOpen()
notify("Welcome, " .. LocalPlayer.DisplayName)
