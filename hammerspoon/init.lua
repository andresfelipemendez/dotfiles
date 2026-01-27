local audiodevice = require("hs.audiodevice")

local devices = {
    f16 = "Vocaster One USB",
    f17 = "MacBook Pro Speakers",
    f18 = "External Headphones", 
}

function switchAudioDevice(deviceName)
    local device = audiodevice.findDeviceByName(deviceName)
    if device then
        device:setDefaultOutputDevice()
        hs.alert.show("Audio: " .. deviceName)
    else
        hs.alert.show("Device not found: " .. deviceName)
    end
end

hs.hotkey.bind({}, "f16", function() switchAudioDevice(devices.f16) end)
hs.hotkey.bind({}, "f17", function() switchAudioDevice(devices.f17) end)
hs.hotkey.bind({}, "f18", function() switchAudioDevice(devices.f18) end)

local hyper = {"cmd", "alt", "ctrl", "shift"}
local application = require("hs.application")
local window = require("hs.window")
local apps = {
    ["1"] = "Obsidian",
    ["2"] = "OBS",
    
    ["3"] = "Safari",
    ["4"] = "GoLand",
    
    ["f"] = "Fork",
    ["t"] = "iTerm", 
    ["e"] = "Finder"
}

function getFrontmostFinderWindowPath()
    local success, path, raw = hs.osascript.applescript([[
        tell application "Finder"
            set targetPath to POSIX path of (target of front Finder window as text)
            return targetPath
        end tell
    ]])
    if success then
        return path
    else
        return nil
    end
end

function openVSCodeInFinderPath()
    local finderPath = getFrontmostFinderWindowPath()
    if  type(finderPath) == "string" and finderPath ~= "" then
        hs.execute('open -a "Visual Studio Code" "' .. finderPath .. '"')
    else
        print("No frontmost Finder window found.")
    end
end

function openForkInFinderPath()
    local finderPath = getFrontmostFinderWindowPath()
    if  type(finderPath) == "string" and finderPath ~= "" then
        hs.execute('/usr/local/bin/fork -C "' .. finderPath .. '"')
    else
        print("No frontmost Finder window found.")
    end
end


local vsCodeShortcut = {"cmd", "ctrl"} -- Combination: Command + Control
local vsCodeKey = "V"                 -- Key: V
hs.hotkey.bind(vsCodeShortcut, vsCodeKey, openVSCodeInFinderPath)
hs.hotkey.bind(vsCodeShortcut, "F", openForkInFinderPath)

-- function openVSCodeInFinderPath()
--     local path = hs.finder.frontmostFinderWindowPath()

function smartAppSwitch(appName)
    local app = application.get(appName)
    
    if not app then
        application.launchOrFocus(appName)
        return
    end
    
    local allWindows = app:allWindows()
    local windows = {}
    for _, win in ipairs(allWindows) do
        if win:isStandard() and win:isVisible() then
            windows[#windows + 1] = win
        end
    end
    print("App: " .. appName .. ", Window count: " .. #windows)
    
    if #windows == 0 then
        if appName == "Finder" then
            print("Creating new Finder window")
            hs.execute([[osascript -e 'tell application "Finder"
                make new Finder window
                set target of front window to home
                activate
            end tell']])
            print("Output: " .. tostring(output))
            print("Status: " .. tostring(status))
        else
            app:activate()
        end
        return
    end
    
    local focusedWindow = window.focusedWindow()
    local currentApp = focusedWindow and focusedWindow:application()
    
    if currentApp and currentApp:name() == appName then
        local currentIndex = 1
        for i, win in ipairs(windows) do
            if win == focusedWindow then
                currentIndex = i
                break
            end
        end
        local nextIndex = (currentIndex % #windows) + 1
        windows[nextIndex]:focus()
    else
        windows[1]:focus()
    end
end

for key, appName in pairs(apps) do
    hs.hotkey.bind(hyper, key, function() smartAppSwitch(appName) end)
end

local hyper = {"cmd", "alt", "ctrl", "shift"}

local function openFileInApp(appName, filePath)
    local osa = [[
        tell application "%s"
            activate
            open POSIX file "%s"
        end tell
    ]]
    hs.osascript(osa:format(appName, filePath))
end

hs.hotkey.bind(hyper, "`", function()
    local configPath = os.getenv("HOME") .. "/.hammerspoon/init.lua"
    openFileInApp("Sublime Text", configPath)
end)

hs.hotkey.bind(hyper, "r", hs.reload)
hs.hotkey.bind(hyper, "c", hs.toggleConsole)

