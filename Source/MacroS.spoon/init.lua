--- === MacroS ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MacroS.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MacroS.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "MacroS"
obj.version = "0.1"
obj.author = "Roman Khomenko <roman.dowakin@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- MacroS.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('MacroS')

obj.eventWatcher = nil
obj.watcherTypes = {
   hs.eventtap.event.types.keyDown,
   hs.eventtap.event.types.keyUp,
   hs.eventtap.event.types.mouseMoved,
   hs.eventtap.event.types.leftMouseDown,
   hs.eventtap.event.types.leftMouseUp,
   hs.eventtap.event.types.rightMouseDown,
   hs.eventtap.event.types.rightMouseUp,
   hs.eventtap.event.types.scrollWheel,
}
obj.recording = {}
obj.toggleKey = nil
obj.replayAfter = nil
obj.replaying = false
obj.menuBar = nil
obj.timer = nil

function obj.watcherCallback(e)
   obj.logger.i("e", e)
   if obj.toggleKey and obj.toggleKey:getType() == e:getType() and obj.toggleKey:getKeyCode() == e:getKeyCode() then
      for k, v in pairs(obj.toggleKey:getFlags()) do
         obj.logger.i("kv", k, v, e:getFlags()[k])
         if e:getFlags()[k] ~= v then
            break
         end
         return false
      end
   end
   table.insert(obj.recording, e)
   return false
end

function obj.toggleRecording()
   obj.logger.i("toggleRecording")
   if obj.replaying then
      hs.notify.show("Stopping replay", "MacroS", "")
      obj.stop()
      return
   end
   if obj.eventWatcher then
      obj.eventWatcher:stop()
      obj.eventWatcher = nil
      for i, k in pairs(obj.recording) do
         obj.logger.i(i, hs.inspect(k:getFlags()), k:getCharacters(true), k)
      end
   else
      obj.recording = {}
      obj.eventWatcher = hs.eventtap.new(obj.watcherTypes, obj.watcherCallback)
      obj.eventWatcher:start()
   end
end

local function textPrompt(message, informativeText, defaultText, buttonOne, buttonTwo)
   local front_app = hs.application.frontmostApplication()
   hs.focus()
   button, text = hs.dialog.textPrompt(message, informativeText, defaultText, buttonOne, buttonTwo)
   front_app:activate()
   return button, text
end

function obj.tick(start)
   local pos = start or 1
   obj.logger.i("obj.replaying", obj.replaying)
   if not obj.replaying then return end
   if (not obj.recording) or (pos > #obj.recording) then
      return
   end
   obj.logger.i("post", obj.recording[pos])
   obj.recording[pos]:post()

   if pos + 1 <= #obj.recording then
      obj.logger.i("after")
      obj.timer = hs.timer.doAfter((obj.recording[pos + 1]:timestamp() - obj.recording[pos]:timestamp()) / 1e+9, function() obj.tick(pos + 1) end)
   else
      if obj.replayAfter then
         obj.timer = hs.timer.doAfter(obj.replayAfter, obj.tick)
      else
         obj.stop()
      end
   end

   obj.logger.i("replayRecording", pos)
end

function obj.replayRecording()
   obj.replaying = not obj.replaying

   if obj.replaying then
      obj.menuBar = hs.menubar.new()
      obj.menuBar:setTitle("REPLAYING")
      obj.tick()
   else
      obj.stop()      
   end
end

function obj.stop()
   obj.logger.i("start")
   obj.replaying = false
   if obj.menuBar then
      obj.menuBar:delete()
      obj.menuBar = nil
   end
   if obj.eventWatcher then
      obj.eventWatcher:stop()
      obj.eventWatcher = nil
   end
   if obj.timer then
      obj.timer:stop()
      obj.timer = nil
   end
end

function obj.manyReplayRecording()
   button, text = textPrompt("Replay after (sec)", "", "0", "Replay", "")
   obj.replayAfter = tonumber(text)
   obj.replayRecording()
end

function obj:start()
   obj.logger.i("start")
end

function obj:bindHotkeys(mapping)
   obj.logger.i("mapping", hs.inspect(mapping))
   if mapping.toggle_recording then 
      obj.toggleKey = hs.eventtap.event.newKeyEvent(mapping.toggle_recording[1], mapping.toggle_recording[2], true)
      obj.logger.i("mapping.toggle_recording", obj.toggleKey)
   end
   local def = {
      toggle_recording = obj.toggleRecording,
      replay_recording = obj.replayRecording,
   }
   hs.spoons.bindHotkeysToSpec(def, mapping)
end

return obj
