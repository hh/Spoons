--- ==== EasySuperGenPass ====
--- 
--- https://github.com/chriszarate/supergenpass-lib
--- https://gist.github.com/prashanthrajagopal/08ab39d62725c8a8716b

local obj = { __gc = true }
obj.__index = obj

-- Metadata
obj.name = "EasySuperGenPass"
obj.version = "0.1"
obj.author = "Roman Khomenko <roman.dowakin@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.save_master_password = false
obj.master_password = nil
obj.master_passwords_hashes = nil

obj.logger = hs.logger.new('EasySuperGenPass')

local function superGenPass(pass)
    local len = 10

    local function valid_pass(s)
        s = s:sub(1, len)

        -- 1. Password must start with a lowercase letter [a-z].
        if not s:match("^[a-z]") then return false end
        -- 2. Password must contain at least one uppercase letter [A-Z].
        if not s:match("[A-Z]") then return false end
        -- 3. Password must contain at least one numeral [0-9].
        if not s:match("[0-9]") then return false end

        return s
    end

    local function b64_md5(s)
        s = hs.hash.MD5(s)
        s = hs.execute(string.format('echo "%s" | xxd -r -p | base64 -b 98', s))
        s = s:match("^%s*(.-)%s*$")
        s = s:gsub("=", "A")
        s = s:gsub("/", "8")
        s = s:gsub("+", "9")
        return s
    end

    for i = 1, len do
        pass = b64_md5(pass)
    end

    while not valid_pass(pass) do
        pass = b64_md5(pass)
    end

    pass = valid_pass(pass)
    return pass
end

local function textPrompt(message, informativeText, defaultText, buttonOne, buttonTwo)
    -- TODO: can we use password field
    local front_app = hs.application.frontmostApplication()
    hs.focus()
    button, text = hs.dialog.textPrompt(message, informativeText, defaultText, buttonOne, buttonTwo)
    front_app:activate()
    return button, text
end

local function extractUrlFromBrowsers()
    local front_browser = hs.application.frontmostApplication():name()

    if front_browser == "Google Chrome" then
        success, url = hs.osascript.applescript('tell application "Google Chrome" to return URL of active tab of front window')
        if success then
            return url
        end
    end
    
    if front_browser == "Firefox" then
        local prev_pos = hs.mouse.getAbsolutePosition()
        hs.eventtap.keyStroke({"cmd"}, "L")
        hs.eventtap.keyStroke({"cmd"}, "C")
        hs.mouse.setAbsolutePosition(prev_pos)
        hs.eventtap.leftClick(prev_pos)
        url = hs.pasteboard.getContents()
        return url
    end
end

local function getMasterPassword()
    if obj.master_password then
        return obj.master_password
    else
        local master_password = nil
        result, master_password = textPrompt(
            "Type your master password:",
            "", "", "ok", "cancel")
        if result ~= "ok" then
            return
        end

        master_password_hash = hs.hash.MD5(master_password):sub(1, 4)
        obj.logger.i("master_password_hash", master_password_hash)

        if obj.master_passwords_hashes then
            if not obj.master_passwords_hashes[master_password_hash] then
                hs.notify.show(
                    "Incorrent master password",
                    "Hash didn't match with master_passwords_hashes", "")
                return
            end
        end

        if obj.save_master_password then
            obj.master_password = master_password
        end
        return master_password
    end
end

function obj:init()
end

function obj.paste_password(options)
    local url = nil
    options = options or {}

    local master_password = getMasterPassword()
    if not master_password then return end

    if not options.type_url then
        url = extractUrlFromBrowsers()
    end
    if not url then
        result, url = textPrompt("Type url for password:", "", "", "ok", "cancel")
        if result ~= "ok" then
            return
        end
    end
    if url:sub(1, 4) ~= "http" then
        url = "http://"..url
    end
    
    -- using extra splits to not use proper regexp from external library
    domain = hs.fnutils.split(url:match('^%w+://([^/]+)'), "%.")
    if #domain < 2 then
        hs.notify.show("Incorrent URL", url, "")
        return
    end
    domain = domain[#domain-1]..'.'..domain[#domain]

    local password = superGenPass(master_password..":"..domain)
    if options.copy then
        hs.pasteboard.setContents(password)
    else
        hs.eventtap.keyStrokes(password)
    end
end

function obj.type_url_paste_password()
    obj.paste_password{type_url=true}
end

function obj.copy_password()
    obj.paste_password{copy=true}
end

function obj:bindHotkeys(mapping)
    local def = {
        paste_password = obj.paste_password,
        type_url_paste_password = obj.type_url_paste_password,
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
end

return obj
