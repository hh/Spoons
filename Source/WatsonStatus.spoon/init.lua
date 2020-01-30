--- === WatsonStatus ===
---
--- Display in menubar status from time tracker CLI Watson https://github.com/TailorDev/Watson
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WatsonStatus.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WatsonStatus.spoon.zip)

-- Metadata
local obj = {}
obj.name = "WatsonStatus"
obj.version = "0.1"
obj.author = "Roman Khomenko <roman.dowakin@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.menubar = nil
obj.timer = nil
obj.pathwatcher = nil

--- WatsonStatus.watsonbin
--- Variable
--- Path to watson binary
obj.watsonbin = "/usr/local/bin/watson"

--- WatsonStatus.watsonfolder
--- Variable
--- Path to watson folder. Spoon set folder watch on it to monitor changes.
obj.watsonfolder = "/Users/roman/Library/Application Support/watson"


function obj:init()
end

--- WatsonStatus:start()
--- Method
--- Starts WatsonStatus
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WatsonStatus object
function obj:start()
    if self.menubar then self:stop() end
    self.menubar = hs.menubar.new()
    self.menubar:setClickCallback(self.clicked)
    self.update()
    self.timer = hs.timer.doEvery(60, self.update)
    self.pathwatcher = hs.pathwatcher.new(obj.watsonfolder, obj.update):start()
    return self
end

--- WatsonStatus:stop()
--- Method
--- Stops WatsonStatus
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WatsonStatus objectini
function obj:stop()
    if self.menubar then self.menubar:delete() end
    self.menubar = nil
    if self.timer then self.timer:stop() end
    self.timer = nil
    if self.pathwatcher then self.pathwatcher:stop() end
    self.pathwatcher = nil
    return self
end

function obj.update()
    output = hs.execute(obj.." status")
    output = string.gsub(output, "\n", "")
    obj.menubar:setTooltip(output)
    if output == "No project started." then
        -- from icons8.com https://icons8.com/icons/set/sleep
        obj.menubar:setIcon(hs.image.imageFromPath(hs.spoons.resourcePath("wait.png")):setSize({h=18,w=18}))
    else
        -- from icons8.com https://icons8.com/icons/set/time
        obj.menubar:setIcon(hs.image.imageFromPath(hs.spoons.resourcePath("run.png")):setSize({h=18,w=18}))        
    end
end

function obj.clicked()
    hs.execute(obj.." stop")
end

return obj
